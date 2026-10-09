import Foundation

enum SessionEvent: Sendable {
    case status(String, healthy: Bool)
    case snapshot([ChainBlock])
    case frame(LiveFrame)
    case block(ChainBlock, celebrate: Bool)
    case template([TemplateTransaction])
    case templateUnavailable(String)
}

/// The sole owner of the socket, reconnect loop, template sequence and persisted replay guard.
actor LiveSession {
    nonisolated let events: AsyncStream<SessionEvent>
    private let output: AsyncStream<SessionEvent>.Continuation
    private let api: TelemetryAPI
    private var runner: Task<Void, Never>?
    private var socket: URLSessionWebSocketTask?
    private var generation = UUID()
    private var tip: ChainBlock?
    private var synced = false
    private var seen: SeenBlocks
    private var book = TemplateBook()
    private var tracking = false
    private var lastReceipt = Date.distantPast
    private let defaults: UserDefaults

    init(api: TelemetryAPI = TelemetryAPI(), defaults: UserDefaults = .standard) {
        self.api = api
        self.defaults = defaults
        seen = SeenBlocks(defaults: defaults)
        let stream = AsyncStream<SessionEvent>.makeStream()
        events = stream.stream
        output = stream.continuation
    }
    func start() {
        guard runner == nil else { return }
        let id = UUID(); generation = id
        runner = Task { await run(id) }
    }
    func stop() {
        generation = UUID()
        runner?.cancel(); runner = nil
        socket?.cancel(with: .goingAway, reason: nil); socket = nil
        synced = false; book.reset()
        output.yield(.status("Paused · app inactive", healthy: false))
        output.yield(.templateUnavailable("Live template paused"))
    }
    func retry() { stop(); start() }
    func trackTemplate(_ enabled: Bool) async {
        guard enabled != tracking else { return }
        tracking = enabled; book.reset()
        output.yield(.templateUnavailable(enabled ? "Synchronizing template" : "Template not subscribed"))
        guard let socket else { return }
        do { try await subscriptions(socket) }
        catch { socket.cancel(with: .goingAway, reason: nil) }
    }
    private func send(_ text: String, to socket: URLSessionWebSocketTask) async throws {
        try await socket.send(.string(text))
    }
    private func subscriptions(_ socket: URLSessionWebSocketTask) async throws {
        let topics = tracking ? "\"blocks\",\"mempool-blocks\",\"stats\",\"live-2h-chart\"" : "\"blocks\",\"mempool-blocks\",\"stats\""
        try await send("{\"action\":\"want\",\"data\":[\(topics)]}", to: socket)
        try await send("{\"track-mempool-block\":\(tracking ? 0 : -1)}", to: socket)
    }
    private func persist() { seen.persist(to: defaults) }
    private func snapshot(_ blocks: [ChainBlock]) {
        let ordered = blocks.sorted { $0.height > $1.height }
        tip = ordered.first
        for block in ordered { seen.observe(block.id) }
        persist()
        output.yield(.snapshot(ordered))
    }
    private func reconcile(_ id: UUID) async throws {
        let blocks: [ChainBlock] = try await api.get("v1/blocks")
        guard generation == id, !Task.isCancelled else { throw CancellationError() }
        guard !blocks.isEmpty else { throw TelemetryError.invalidData }
        snapshot(blocks)
    }
    private func run(_ id: UUID) async {
        var attempt = 0
        while !Task.isCancelled, generation == id {
            synced = false; book.reset()
            output.yield(.status("Connecting · REST recovery", healthy: false))
            do { try await reconcile(id) }
            catch {
                guard generation == id, !Task.isCancelled else { return }
                output.yield(.status("REST recovery failed: \(error.localizedDescription)", healthy: false))
            }
            guard generation == id, !Task.isCancelled else { return }
            let task = URLSession.shared.webSocketTask(with: URL(string: "wss://mempool.space/api/v1/ws")!)
            socket = task; task.resume(); lastReceipt = Date()
            let started = Date()
            let heartbeat = Task { await self.heartbeat(task, generation: id) }
            do {
                try await send("{\"action\":\"init\"}", to: task)
                try await subscriptions(task)
                while !Task.isCancelled, generation == id {
                    let message = try await task.receive()
                    guard generation == id, !Task.isCancelled else { throw CancellationError() }
                    let data: Data
                    switch message {
                    case .data(let value): data = value
                    case .string(let value): data = Data(value.utf8)
                    @unknown default: throw TelemetryError.invalidData
                    }
                    let frame = try JSONDecoder().decode(LiveFrame.self, from: data)
                    lastReceipt = Date()
                    try await handle(frame, generation: id, socket: task)
                    output.yield(.status(synced ? "Live · mempool.space" : "Synchronizing chain", healthy: synced))
                }
            } catch {
                if generation == id, !Task.isCancelled {
                    output.yield(.status("Disconnected · retrying: \(error.localizedDescription)", healthy: false))
                    output.yield(.templateUnavailable("Disconnected · template stale"))
                }
            }
            heartbeat.cancel(); task.cancel(with: .goingAway, reason: nil)
            guard generation == id, !Task.isCancelled else { return }
            socket = nil
            if Date().timeIntervalSince(started) > 60 { attempt = 0 }
            let delay = min(30, pow(2, Double(min(attempt, 5))) * Double.random(in: 0.8...1.2))
            attempt += 1
            do { try await Task.sleep(nanoseconds: UInt64(max(1, delay) * 1e9)) } catch { return }
        }
    }
    private func heartbeat(_ task: URLSessionWebSocketTask, generation id: UUID) async {
        do {
            while !Task.isCancelled, generation == id {
                try await Task.sleep(nanoseconds: 15_000_000_000)
                guard generation == id else { return }
                if Date().timeIntervalSince(lastReceipt) > 35 {
                    task.cancel(with: .goingAway, reason: nil); return
                }
                try await send("{\"action\":\"ping\"}", to: task)
            }
        } catch {
            if !Task.isCancelled { task.cancel(with: .goingAway, reason: nil) }
        }
    }
    private func handle(_ frame: LiveFrame, generation id: UUID, socket: URLSessionWebSocketTask) async throws {
        if let blocks = frame.blocks, !blocks.isEmpty {
            snapshot(blocks); synced = true // init snapshot is always silent, including reconnects
        }
        if let block = frame.block {
            let fresh = seen.observe(block.id); persist()
            if fresh {
                let extendsTip = tip.map { block.height == $0.height + 1 && block.previousblockhash == $0.id } ?? false
                if synced && extendsTip {
                    tip = block
                    output.yield(.block(block, celebrate: true))
                } else {
                    synced = false
                    output.yield(.status("Reconciling chain discontinuity", healthy: false))
                    try await reconcile(id)
                    synced = true
                }
            }
        }
        output.yield(.frame(frame))
        if let update = frame.template, tracking, update.index == 0 {
            do {
                try book.apply(update)
                output.yield(.template(book.transactions.values.sorted { $0.id < $1.id }))
            } catch {
                book.reset()
                output.yield(.templateUnavailable(error.localizedDescription))
                // Stop/start forces a full snapshot even on servers suppressing duplicate subscriptions.
                try await send("{\"track-mempool-block\":-1}", to: socket)
                try await send("{\"track-mempool-block\":0}", to: socket)
            }
        }
    }
}
