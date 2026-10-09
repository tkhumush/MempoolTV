import Foundation
import Combine

struct Observation<Value> {
    var value: Value?
    var received: Date?
    var source: Date?
    var error: String?
    var refreshing = false
    var origin = "mempool.space"
    mutating func accept(_ value: Value, source: Date? = nil, origin: String = "mempool.space") {
        self.value = value; received = Date(); self.source = source
        error = nil; refreshing = false; self.origin = origin
    }
    func status(now: Date, maxAge: TimeInterval) -> String {
        if let error { return value == nil ? "Unavailable · \(error)" : "Stale · \(error)" }
        guard let received else { return refreshing ? "Loading…" : "Unavailable" }
        let dated = source ?? received
        if !SourceDate.validObservation(dated, now: now) { return "Unavailable · invalid source timestamp" }
        let stale = now.timeIntervalSince(dated) > maxAge
        return "\(stale ? "Stale" : refreshing ? "Refreshing" : origin) · \(dated.formatted(date: .abbreviated, time: .shortened))"
    }
}

enum ObservatoryScreen: String, CaseIterable, Identifiable {
    case overview = "Overview", fees = "Fee Market", mining = "Mining", lightning = "Lightning"
    var id: String { rawValue }
}

@MainActor
final class ObservatoryModel: ObservableObject {
    @Published var blocks = Observation<[ChainBlock]>()
    @Published var projections = Observation<[Projection]>()
    @Published var fees = Observation<RecommendedFees>()
    @Published var queue = Observation<QueueInfo>()
    @Published var incoming = Observation<Double>()
    @Published var template = Observation<[TemplateTransaction]>()
    @Published var backlog = Observation<BacklogSample>()
    @Published var difficulty = Observation<Retarget>()
    @Published var pools = Observation<PoolWindow>()
    @Published var hashrate = Observation<HashrateHistory>()
    @Published var price = Observation<Quote>()
    @Published var priceHistory = Observation<PriceHistory>()
    @Published var lightning = Observation<LightningSnapshot>()
    @Published var lightningHistory = Observation<[LightningSnapshot]>()
    @Published var connection = "Connecting"
    @Published var healthy = false
    @Published var celebration: ChainBlock?
    @Published var dossier: ChainBlock?
    @Published var screen: ObservatoryScreen = .overview
    @Published var ambientEnabled = false
    @Published var ambientPaused = false
    @Published var rotationProgress = 0.0
    private var lastInput = Date()
    private var lastRotation = Date()
    private let session: LiveSession
    let api: TelemetryAPI
    private var eventsTask: Task<Void, Never>?
    private var pollingTask: Task<Void, Never>?
    private var active = false
    private var generation = UUID()

    init(api: TelemetryAPI = TelemetryAPI()) {
        self.api = api; session = LiveSession(api: api)
    }
    func setActive(_ active: Bool) {
        guard self.active != active else { return }
        self.active = active; generation = UUID()
        blocks.refreshing = false; projections.refreshing = false; fees.refreshing = false
        queue.refreshing = false; incoming.refreshing = false; template.refreshing = false
        backlog.refreshing = false; difficulty.refreshing = false; pools.refreshing = false
        hashrate.refreshing = false; price.refreshing = false; priceHistory.refreshing = false
        lightning.refreshing = false; lightningHistory.refreshing = false
        pollingTask?.cancel(); pollingTask = nil
        if active {
            if eventsTask == nil {
                eventsTask = Task { [weak self, session] in
                    for await event in session.events {
                        guard !Task.isCancelled else { return }
                        self?.consume(event)
                    }
                }
            }
            Task { await session.start() }
            let id = generation
            pollingTask = Task { [weak self] in
                var cycle = 0
                while let self, !Task.isCancelled, self.generation == id {
                    await self.refresh(slow: cycle % 5 == 0)
                    cycle += 1
                    do { try await Task.sleep(nanoseconds: 60_000_000_000) } catch { return }
                }
            }
        } else {
            celebration = nil
            Task { await session.stop() }
        }
    }
    func select(_ screen: ObservatoryScreen, user: Bool = true) {
        if user { input() }
        self.screen = screen
        Task { await session.trackTemplate(screen == .fees) }
    }
    func input() { lastInput = Date(); lastRotation = Date(); ambientPaused = ambientEnabled; rotationProgress = 0 }
    func toggleAmbient() {
        ambientEnabled.toggle(); ambientPaused = false
        lastInput = Date(); lastRotation = Date(); rotationProgress = 0
    }
    func tick(now: Date) {
        guard active, ambientEnabled, dossier == nil, celebration == nil else { lastRotation = now; return }
        if ambientPaused {
            guard now.timeIntervalSince(lastInput) >= 60 else { return }
            ambientPaused = false; lastRotation = now
        }
        rotationProgress = min(1, now.timeIntervalSince(lastRotation) / 16)
        if rotationProgress >= 1 {
            let screens = ObservatoryScreen.allCases
            let index = screens.firstIndex(of: screen) ?? 0
            select(screens[(index + 1) % screens.count], user: false)
            lastRotation = now; rotationProgress = 0
        }
    }
    func dismissCelebration() { celebration = nil; lastRotation = Date() }
    func retryLive() { Task { await session.retry() } }
    func retryTemplate() {
        Task { await session.trackTemplate(false); await session.trackTemplate(screen == .fees) }
    }
    private func consume(_ event: SessionEvent) {
        guard active else { return }
        switch event {
        case .status(let message, let live):
            connection = message; healthy = live
            if !live {
                projections.error = message
                blocks.error = message; fees.error = message; queue.error = message; incoming.error = message
            }
        case .snapshot(let values): blocks.accept(Array(values.prefix(12)), origin: "Chain snapshot")
        case .block(let block, let celebrate):
            var values = blocks.value ?? []
            values.removeAll { $0.id == block.id || $0.height >= block.height }
            values.insert(block, at: 0)
            blocks.accept(Array(values.prefix(12)), origin: "Live chain")
            // Seen hashes are persisted before this event is emitted. Rapid arrivals are
            // committed to the wall but coalesced into the current takeover, never queued.
            if celebrate, celebration == nil, dossier == nil {
                celebration = block
            }
        case .frame(let frame):
            if let value = frame.projections { projections.accept(value, origin: "Live projection") }
            if let value = frame.fees { fees.accept(value, origin: "Live recommendations") }
            if let value = frame.mempoolInfo { queue.accept(value, origin: "Live queue") }
            if let value = frame.vBytesPerSecond, value >= 0 { incoming.accept(value, origin: "Live arrivals") }
            if let value = frame.da { difficulty.accept(value, origin: "Live estimate") }
            if let value = frame.backlog {
                if value.bands != nil { backlog.accept(value, source: Date(timeIntervalSince1970: value.added)) }
                else { backlog.error = "Unsupported fee-band schema" }
            }
        case .template(let values): template.accept(values, origin: "Live template")
        case .templateUnavailable(let message): template.error = message
        }
    }
    func refresh(slow: Bool = true) async {
        async let a: Void = load("v1/fees/recommended", into: \.fees)
        async let b: Void = load("v1/fees/mempool-blocks", into: \.projections)
        async let c: Void = load("mempool", into: \.queue)
        async let d: Void = refreshPrice()
        async let e: Void = refreshBacklog()
        async let f: Void = refreshSlow(enabled: slow)
        _ = await (a,b,c,d,e,f)
    }
    func refreshBacklog() async {
        await load("v1/statistics/2h", into: \.backlog) { (values: [BacklogSample]) in
            guard let sample = values.max(by: { $0.added < $1.added }), sample.bands != nil,
                  SourceDate.validObservation(Date(timeIntervalSince1970: sample.added)) else { throw TelemetryError.invalidData }
            return (sample, Date(timeIntervalSince1970: sample.added))
        }
    }
    func refreshPrice() async {
        await load("v1/prices", into: \.price) { (quote: Quote) in
            let date = Date(timeIntervalSince1970: quote.time)
            guard quote.USD > 0, SourceDate.validObservation(date) else { throw TelemetryError.invalidData }
            return (quote, date)
        }
        guard let quote = price.value else { return }
        await load("v1/historical-price?currency=USD&timestamp=\(Int(quote.time - 86400))", into: \.priceHistory)
    }
    func refreshSlow(enabled: Bool = true) async {
        guard enabled else { return }
        async let a: Void = load("v1/difficulty-adjustment", into: \.difficulty)
        async let b: Void = load("v1/mining/pools/1w", into: \.pools)
        async let c: Void = load("v1/mining/hashrate/3m", into: \.hashrate)
        async let d: Void = refreshLightning()
        _ = await (a,b,c,d)
    }
    func refreshLightning() async {
        async let a: Void = load("v1/lightning/statistics/latest", into: \.lightning) { (response: LightningLatest) in
            guard let date = response.latest.date, SourceDate.validObservation(date) else { throw TelemetryError.invalidData }
            return (response.latest, date)
        }
        async let b: Void = load("v1/lightning/statistics/1m", into: \.lightningHistory) { (values: [LightningSnapshot]) in
            let valid = values.filter { $0.date.map { SourceDate.validObservation($0) } == true }.sorted { $0.date! < $1.date! }
            guard valid.count == values.count, !valid.isEmpty else { throw TelemetryError.invalidData }
            return (valid, valid.last?.date)
        }
        _ = await (a,b)
    }
    private func load<T: Decodable>(_ path: String, into key: ReferenceWritableKeyPath<ObservatoryModel, Observation<T>>) async {
        await load(path, into: key) { (value: T) in (value, nil) }
    }
    private func load<Wire: Decodable, Value>(_ path: String, into key: ReferenceWritableKeyPath<ObservatoryModel, Observation<Value>>,
                                             transform: (Wire) throws -> (Value, Date?)) async {
        guard !self[keyPath: key].refreshing else { return }
        let id = generation, started = Date()
        self[keyPath: key].refreshing = true
        defer { if generation == id { self[keyPath: key].refreshing = false } }
        do {
            let response: Wire = try await api.get(path)
            let (value, date) = try transform(response)
            guard generation == id, !Task.isCancelled else { return }
            // A slower REST response must never overwrite a newer socket observation.
            if let received = self[keyPath: key].received, received > started { return }
            self[keyPath: key].accept(value, source: date, origin: "REST snapshot")
        } catch {
            guard generation == id, !Task.isCancelled else { return }
            if let received = self[keyPath: key].received, received > started { return }
            self[keyPath: key].error = error.localizedDescription
        }
    }
}
