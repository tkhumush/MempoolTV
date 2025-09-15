import Foundation
import Network

class NostrService: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private let relayURL = URL(string: "wss://relay.primal.net")!
    private var urlSession: URLSession
    
    @Published var isConnected = false
    @Published var profiles: [String: NostrProfile] = [:]
    @Published var errorMessage: String?
    
    private var subscriptions: [String: [String]] = [:] // subscriptionId -> [pubkeys]
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.urlSession = URLSession(configuration: config)
    }
    
    func connect() {
        guard webSocketTask == nil else { return }
        
        webSocketTask = urlSession.webSocketTask(with: relayURL)
        webSocketTask?.resume()
        
        DispatchQueue.main.async {
            self.isConnected = true
            self.errorMessage = nil
        }
        
        startListening()
    }
    
    func disconnect() {
        guard webSocketTask != nil else { return }
        
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.errorMessage = nil
        }
    }
    
    func fetchProfiles(for developers: [Developer]) {
        guard isConnected else {
            connect()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.fetchProfiles(for: developers)
            }
            return
        }
        
        let pubkeys = developers.compactMap { $0.publicKeyHex.isEmpty ? nil : $0.publicKeyHex }
        
        guard !pubkeys.isEmpty else {
            DispatchQueue.main.async {
                self.errorMessage = "No valid public keys found"
            }
            return
        }
        
        let subscriptionId = NostrUtils.generateSubscriptionId()
        subscriptions[subscriptionId] = pubkeys
        
        print("Fetching profiles for pubkeys: \(pubkeys)")
        
        // Try each author separately to avoid filter issues
        for (index, pubkey) in pubkeys.enumerated() {
            let filterDict: [String: Any] = [
                "kinds": [0],
                "authors": [pubkey]
            ]
            
            let authorSubscriptionId = "\(subscriptionId)_\(index)"
            sendMessage(["REQ", authorSubscriptionId, filterDict])
        }
    }
    
    private func startListening() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.startListening() // Continue listening
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.errorMessage = "WebSocket error: \(error.localizedDescription)"
                    self?.isConnected = false
                }
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
              let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [Any],
              let messageType = jsonArray.first as? String else {
            return
        }
        
        switch messageType {
        case "EVENT":
            handleEventMessage(jsonArray)
        case "EOSE":
            handleEndOfStoredEvents(jsonArray)
        case "NOTICE":
            handleNotice(jsonArray)
        default:
            break
        }
    }
    
    private func handleEventMessage(_ jsonArray: [Any]) {
        guard jsonArray.count >= 3,
              let _ = jsonArray[1] as? String,
              let eventDict = jsonArray[2] as? [String: Any],
              let eventData = try? JSONSerialization.data(withJSONObject: eventDict),
              let event = try? JSONDecoder().decode(NostrEvent.self, from: eventData) else {
            return
        }
        
        if event.kind == 0 { // metadata event
            parseProfileMetadata(event)
        }
    }
    
    private func parseProfileMetadata(_ event: NostrEvent) {
        guard let contentData = event.content.data(using: .utf8),
              let metadata = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any] else {
            return
        }
        
        let profile = NostrProfile(
            id: event.pubkey,
            name: metadata["name"] as? String,
            displayName: metadata["display_name"] as? String,
            about: metadata["about"] as? String,
            picture: metadata["picture"] as? String,
            website: metadata["website"] as? String,
            lud16: metadata["lud16"] as? String,
            nip05: metadata["nip05"] as? String
        )
        
        DispatchQueue.main.async {
            self.profiles[event.pubkey] = profile
        }
    }
    
    private func handleEndOfStoredEvents(_ jsonArray: [Any]) {
        guard let subscriptionId = jsonArray[1] as? String else { return }
        
        // Close the subscription
        sendMessage(["CLOSE", subscriptionId])
        subscriptions.removeValue(forKey: subscriptionId)
    }
    
    private func handleNotice(_ jsonArray: [Any]) {
        guard let notice = jsonArray[1] as? String else { return }
        
        DispatchQueue.main.async {
            self.errorMessage = "Relay notice: \(notice)"
        }
    }
    
    private func sendMessage(_ message: [Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: message)
            guard let text = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to encode message as UTF-8"
                }
                return
            }
            
            let webSocketMessage = URLSessionWebSocketTask.Message.string(text)
            webSocketTask?.send(webSocketMessage) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to send message: \(error.localizedDescription)"
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "JSON serialization error: \(error.localizedDescription)"
            }
        }
    }
    
    deinit {
        disconnect()
    }
}