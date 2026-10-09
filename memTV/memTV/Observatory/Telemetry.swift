import Foundation

// Wire models deliberately preserve missing fields and fractional virtual bytes.
struct ChainBlock: Decodable, Identifiable, Equatable, Sendable {
    let id: String
    let height: Int
    let timestamp: Int
    let tx_count: Int
    let weight: Int
    let previousblockhash: String?
    let extras: Extras?
    struct Extras: Decodable, Equatable, Sendable {
        let totalFees: Double?
        let reward: Double?
        let medianFee: Double?
        let pool: Pool?
        let firstSeen: Double?
        struct Pool: Decodable, Equatable, Sendable { let name: String }
    }
    var subsidy: Double {
        let halvings = height / 210_000
        return halvings < 64 ? Double(5_000_000_000 >> halvings) / 1e8 : 0
    }
    var vsize: Double { Double(weight) / 4 }
}
struct Projection: Decodable, Equatable, Sendable {
    let blockVSize: Double
    let nTx: Int
    let totalFees: Double?
    let medianFee: Double?
    let feeRange: [Double]?
}
struct QueueInfo: Decodable, Sendable { let size: Int; let bytes: Double }
struct RecommendedFees: Decodable, Sendable {
    let fastestFee: Double?
    let halfHourFee: Double?
    let hourFee: Double?
    let economyFee: Double?
    let minimumFee: Double?
}
struct Retarget: Decodable, Sendable {
    let progressPercent: Double
    let difficultyChange: Double
    let estimatedRetargetDate: Double // milliseconds, including future estimates
    let remainingBlocks: Int
    let nextRetargetHeight: Int
    let timeAvg: Double // milliseconds
    var estimatedDate: Date { Date(timeIntervalSince1970: estimatedRetargetDate / 1000) }
}
struct PoolWindow: Decodable, Sendable {
    let pools: [Entry]
    let blockCount: Int
    struct Entry: Decodable, Identifiable, Sendable {
        let poolId: Int
        let name: String
        let blockCount: Int
        var id: Int { poolId }
    }
}
struct HashrateHistory: Decodable, Sendable {
    let currentHashrate: Double
    let hashrates: [Point]
    struct Point: Decodable, Identifiable, Sendable {
        let timestamp: Double
        let avgHashrate: Double
        var id: Double { timestamp }
    }
}
struct Quote: Decodable, Sendable { let time: Double; let USD: Double }
struct PriceHistory: Decodable, Sendable {
    let prices: [Point]
    struct Point: Decodable, Sendable { let time: Double; let USD: Double }
}
struct LightningSnapshot: Decodable, Identifiable, Sendable {
    let added: String
    let channel_count: Int
    let node_count: Int
    let total_capacity: Double // satoshis
    var id: String { added }
    var date: Date? { SourceDate.parse(added) }
    var capacityBTC: Double { total_capacity / 1e8 }
}
struct LightningLatest: Decodable, Sendable { let latest: LightningSnapshot }

enum SourceDate {
    static func parse(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
    static func validObservation(_ date: Date, now: Date = Date()) -> Bool {
        date.timeIntervalSince1970 > 0 && date <= now.addingTimeInterval(60)
    }
}

struct BacklogSample: Decodable, Sendable {
    let added: Double
    let vsizes: [Double]
    let vbytes_per_second: Double?
    // Current upstream optimized REST/WS object, not an array-indexed WS frame.
    var bands: [Double]? { TelemetryMath.backlog(vsizes) }
}

enum TelemetryMath {
    static let feeFloors: [Double] = [0,1,2,3,4,5,6,8,10,12,15,20,30,40,50,60,70,80,90,100,125,150,175,200,250,300,350,400,500,600,700,800,900,1000,1200,1400,1600,1800,2000]
    static func band(_ rate: Double) -> Int { rate < 2 ? 0 : rate < 5 ? 1 : rate < 10 ? 2 : rate < 20 ? 3 : 4 }
    static func backlog(_ vsizes: [Double]) -> [Double]? {
        // Unknown/legacy schemas must not silently acquire invented buckets.
        guard vsizes.count == feeFloors.count, vsizes.allSatisfy({ $0.isFinite && $0 >= 0 }) else { return nil }
        var result = Array(repeating: 0.0, count: 5)
        for (floor, size) in zip(feeFloors, vsizes) { result[band(floor)] += size }
        return result
    }
    static func shares(_ counts: [Int]) -> [Int] {
        let total = counts.reduce(0, +)
        guard total > 0, counts.allSatisfy({ $0 >= 0 }) else { return [] }
        let raw = counts.map { Double($0) * 1000 / Double(total) }
        var result = raw.map { Int($0.rounded(.down)) }
        let order = raw.indices.sorted {
            let a = raw[$0] - Double(result[$0]), b = raw[$1] - Double(result[$1])
            return a == b ? $0 < $1 : a > b
        }
        for index in order.prefix(1000 - result.reduce(0, +)) { result[index] += 1 }
        return result // tenths of a percent; total exactly 100.0%
    }
    static func epoch(height: Int) -> (remaining: Int, progress: Double) {
        // The retarget takes effect at the next multiple of 2016.
        let completed = ((height % 2016) + 2016) % 2016
        return (2016 - completed, Double(completed) / 2016)
    }
    static func priceChange(current: Quote, history: [PriceHistory.Point], now: Date) -> (percent: Double, date: Date)? {
        let date = Date(timeIntervalSince1970: current.time)
        guard current.USD > 0, SourceDate.validObservation(date, now: now), now.timeIntervalSince(date) < 3600 else { return nil }
        let target = current.time - 86400
        guard let previous = history.filter({ $0.time <= target && $0.USD > 0 }).max(by: { $0.time < $1.time }), target - previous.time <= 7200 else { return nil }
        return ((current.USD / previous.USD - 1) * 100, Date(timeIntervalSince1970: previous.time))
    }
}

struct TemplateTransaction: Decodable, Identifiable, Equatable, Sendable {
    let id: String
    let fee: Double
    let vsize: Double
    let value: Double
    var rate: Double // effective/package rate, supplied by provider
    init(from decoder: Decoder) throws {
        var c = try decoder.unkeyedContainer()
        id = try c.decode(String.self)
        fee = try c.decode(Double.self)
        vsize = try c.decode(Double.self)
        value = try c.decode(Double.self)
        rate = try c.decode(Double.self)
        guard vsize > 0, rate >= 0, fee >= 0 else { throw TelemetryError.invalidData }
        // Classification flags and acceleration fields do not affect encoded area/color.
    }
}
struct TemplateUpdate: Decodable, Sendable {
    let index: Int
    let sequence: Int
    let blockTransactions: [TemplateTransaction]?
    let delta: Delta?
    struct Delta: Decodable, Sendable {
        let added: [TemplateTransaction]
        let removed: [String]
        let changed: [Change]
    }
    struct Change: Decodable, Sendable {
        let id: String
        let rate: Double
        init(from decoder: Decoder) throws {
            var c = try decoder.unkeyedContainer()
            id = try c.decode(String.self); rate = try c.decode(Double.self)
            guard rate >= 0 else { throw TelemetryError.invalidData }
        }
    }
}
struct TemplateBook: Sendable {
    private(set) var sequence: Int?
    private(set) var transactions: [String: TemplateTransaction] = [:]
    mutating func reset() { sequence = nil; transactions = [:] }
    mutating func apply(_ update: TemplateUpdate) throws {
        if let snapshot = update.blockTransactions {
            guard Set(snapshot.map(\.id)).count == snapshot.count else { throw TelemetryError.invalidData }
            transactions = Dictionary(uniqueKeysWithValues: snapshot.map { ($0.id, $0) })
        } else {
            guard let sequence, update.sequence == sequence + 1, let delta = update.delta else {
                reset(); throw TelemetryError.sequenceGap
            }
            var next = transactions
            for id in delta.removed { next.removeValue(forKey: id) }
            for tx in delta.added { next[tx.id] = tx }
            for change in delta.changed {
                guard next[change.id] != nil else { reset(); throw TelemetryError.sequenceGap }
                next[change.id]?.rate = change.rate
            }
            transactions = next
        }
        sequence = update.sequence
    }
}
struct SeenBlocks: Sendable {
    static let persistenceKey = "observatory.seenBlockHashes"
    private(set) var hashes: [String]
    let capacity: Int
    init(hashes: [String] = [], capacity: Int = 512) {
        self.capacity = max(1, capacity)
        var unique: [String] = []
        for hash in hashes where !unique.contains(hash) { unique.append(hash) }
        self.hashes = Array(unique.suffix(max(1, capacity)))
    }
    init(defaults: UserDefaults) {
        self.init(hashes: defaults.stringArray(forKey: Self.persistenceKey) ?? [])
    }
    func persist(to defaults: UserDefaults) { defaults.set(hashes, forKey: Self.persistenceKey) }
    @discardableResult mutating func observe(_ hash: String) -> Bool {
        guard !hashes.contains(hash) else { return false }
        hashes.append(hash)
        if hashes.count > capacity { hashes.removeFirst(hashes.count - capacity) }
        return true
    }
}
enum TelemetryError: Error, LocalizedError {
    case invalidData, sequenceGap, timeout
    var errorDescription: String? {
        switch self {
        case .invalidData: return "Provider data unavailable or invalid"
        case .sequenceGap: return "Template sequence gap; requesting a fresh snapshot"
        case .timeout: return "Live feed timed out"
        }
    }
}
struct LiveFrame: Decodable, Sendable {
    let blocks: [ChainBlock]?
    let block: ChainBlock?
    let projections: [Projection]?
    let fees: RecommendedFees?
    let mempoolInfo: QueueInfo?
    let vBytesPerSecond: Double?
    let da: Retarget?
    let template: TemplateUpdate?
    let backlog: BacklogSample?
    let loadingIndicators: [String: Double]?
    enum CodingKeys: String, CodingKey {
        case blocks, block, fees, mempoolInfo, vBytesPerSecond, da, loadingIndicators
        case projections = "mempool-blocks"
        case template = "projected-block-transactions"
        case backlog = "live-2h-chart"
    }
}
