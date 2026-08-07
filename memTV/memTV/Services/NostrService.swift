//
//  NostrService.swift
//  memTV
//
//  Async/await WebSocket client for Nostr relay communication.
//

import Foundation

@MainActor
final class NostrService: ObservableObject {
    @Published var isConnected = false
    @Published var profiles: [String: NostrProfile] = [:]
    @Published var errorMessage: String?

    private let relayURLString: String
    private var webSocketTask: URLSessionWebSocketTask?
    private var listeningTask: Task<Void, Never>?
    private var urlSession: URLSession

    init(relayURL: String = "wss://relay.primal.net") {
        self.relayURLString = relayURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.urlSession = URLSession(configuration: config)
    }

    deinit {
        disconnect()
    }

    func connect() {
        guard webSocketTask == nil else { return }

        guard let url = URL(string: relayURLString) else {
            errorMessage = "Invalid relay URL"
            return
        }

        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        errorMessage = nil

        listeningTask = Task { [weak self] in
            await self?.listen()
        }
    }

    func disconnect() {
        listeningTask?.cancel()
        listeningTask = nil
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
        errorMessage = nil
    }

    func fetchProfiles(for developers: [Developer]) async {
        if !isConnected {
            connect()
            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        guard !Task.isCancelled else { return }

        let pubkeys = developers.compactMap { $0.publicKeyHex.isEmpty ? nil : $0.publicKeyHex }
        guard !pubkeys.isEmpty else {
            errorMessage = "No valid public keys found"
            return
        }

        let subscriptionId = NostrUtils.generateSubscriptionId()

        for (index, pubkey) in pubkeys.enumerated() {
            guard !Task.isCancelled else { return }
            let filter = NostrFilter(kinds: [0], authors: [pubkey])
            let request = NostrMessage.req("\(subscriptionId)_\(index)", filter)
            await send(request)
        }
    }

    private func listen() async {
        defer {
            isConnected = false
        }

        do {
            while !Task.isCancelled {
                guard let task = webSocketTask else { return }
                let message = try await task.receive()
                handleMessage(message)
            }
        } catch {
            if !Task.isCancelled {
                errorMessage = "WebSocket error: \(error.localizedDescription)"
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseNostrMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseNostrMessage(text)
            }
        @unknown default:
            break
        }
    }

    private func parseNostrMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let message = try? JSONDecoder().decode(NostrMessage.self, from: data) else {
            return
        }

        switch message {
        case .event(_, let event):
            if event.kind == 0 {
                parseProfileMetadata(event)
            }
        case .eose(let subscriptionId):
            Task { await send(.close(subscriptionId)) }
        case .notice(let notice):
            errorMessage = "Relay notice: \(notice)"
        default:
            break
        }
    }

    private func parseProfileMetadata(_ event: NostrEvent) {
        guard let contentData = event.content.data(using: .utf8),
              let profile = try? JSONDecoder().decode(NostrProfile.self, from: contentData) else {
            return
        }

        profiles[event.pubkey] = NostrProfile(
            id: event.pubkey,
            name: profile.name,
            displayName: profile.displayName,
            about: profile.about,
            picture: profile.picture,
            website: profile.website,
            lud16: profile.lud16,
            nip05: profile.nip05
        )
    }

    private func send(_ message: NostrMessage) async {
        guard let task = webSocketTask else { return }
        do {
            let data = try JSONEncoder().encode(message)
            guard let text = String(data: data, encoding: .utf8) else { return }
            try await task.send(.string(text))
        } catch {
            errorMessage = "Failed to send message: \(error.localizedDescription)"
        }
    }
}
