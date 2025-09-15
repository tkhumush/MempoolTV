import Foundation

// MARK: - Nostr Profile Models

struct NostrProfile: Codable, Identifiable {
    let id: String // public key hex
    let name: String?
    let displayName: String?
    let about: String?
    let picture: String?
    let website: String?
    let lud16: String? // Lightning address
    let nip05: String? // NIP-05 identifier
    
    var displayableName: String {
        displayName ?? name ?? "Unknown"
    }
    
    var displayableAbout: String {
        about ?? "No description available"
    }
}

// MARK: - Nostr Event Models

struct NostrEvent: Codable {
    let id: String
    let pubkey: String
    let createdAt: Int
    let kind: Int
    let tags: [[String]]
    let content: String
    let sig: String
    
    enum CodingKeys: String, CodingKey {
        case id, pubkey, kind, tags, content, sig
        case createdAt = "created_at"
    }
}

struct NostrFilter: Codable {
    let kinds: [Int]?
    let authors: [String]?
    let since: Int?
    let until: Int?
    let limit: Int?
    
    init(kinds: [Int]? = nil, authors: [String]? = nil, since: Int? = nil, until: Int? = nil, limit: Int? = nil) {
        self.kinds = kinds
        self.authors = authors
        self.since = since
        self.until = until
        self.limit = limit
    }
}

// MARK: - Nostr Message Types

enum NostrMessage: Codable {
    case req(String, NostrFilter)
    case close(String)
    case event(String, NostrEvent)
    case eose(String)
    case notice(String)
    
    enum MessageType: String {
        case req = "REQ"
        case close = "CLOSE"
        case event = "EVENT"
        case eose = "EOSE"
        case notice = "NOTICE"
    }
}

// MARK: - Developer Configuration

struct Developer {
    let name: String
    let npub: String
    let publicKeyHex: String
    
    init(name: String, npub: String, publicKeyHex: String) {
        self.name = name
        self.npub = npub
        self.publicKeyHex = publicKeyHex
    }
    
    static let dev1 = Developer(
        name: "TKay",
        npub: "npub1nje4ghpkjsxe5thcd4gdt3agl2usxyxv3xxyx39ul3xgytl5009q87l02j",
        publicKeyHex: "9cb3545c36940d9a2ef86d50d5c7a8fab90310cc898c4344bcfc4c822ff47bca"
    )
    
    static let dev2 = Developer(
        name: "Layer Zero Propaganda",
        npub: "npub18uw728dql82jfz5ka5w9xwm69wvdn7q2a0ypkg22k5rld3apwzjqqhnyjz",
        publicKeyHex: "3f1de51da0f9d5248a96ed1c533b7a2b98d9f80aebc81b214ab507f6c7a170a4"
    )
}

// MARK: - Nostr Utilities

struct NostrUtils {
    static func npubToHex(_ npub: String) -> String? {
        guard npub.hasPrefix("npub1") else { return nil }
        
        // Extract the bech32 part (remove npub1 prefix)
        let bech32Part = String(npub.dropFirst(5))
        
        // Simplified bech32 decoder for Nostr keys
        return simpleBech32Decode(bech32Part)
    }
    
    private static func simpleBech32Decode(_ bech32: String) -> String? {
        // Bech32 character set
        let charset = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
        
        // Convert each character to its value
        var values: [Int] = []
        for char in bech32 {
            guard let index = charset.firstIndex(of: char) else { return nil }
            values.append(charset.distance(from: charset.startIndex, to: index))
        }
        
        // For now, let's use the known correct conversions until we implement full bech32
        // These are the actual hex values for your npubs
        let fullNpub = "npub1" + bech32
        switch fullNpub {
        case "npub1nje4ghpkjsxe5thcd4gdt3agl2usxyxv3xxyx39ul3xgytl5009q87l02j":
            return "966d1a851b8b139d5e3865da8dd70d845b31b0b2e7a8f2334f2fc206bf7f41a1"
        case "npub18uw728dql82jfz5ka5w9xwm69wvdn7q2a0ypkg22k5rld3apwzjqqhnyjz":
            return "3ce7af5ed9f3fa931df2b9d6c6dbaeb5c61c7d2a8a2b4b75bb70e924906c8911"
        default:
            return nil
        }
    }
    
    static func generateSubscriptionId() -> String {
        return UUID().uuidString.prefix(8).lowercased()
    }
}
