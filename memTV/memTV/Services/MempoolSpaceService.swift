//
//  MempoolSpaceService.swift
//  memTV
//
//  Mempool.space REST client with Codable models and an injectable NetworkClient.
//

import Foundation

private struct URLBuilder {
    private let baseURL: String

    init(baseURL: String) {
        self.baseURL = baseURL
    }

    func url(path: String) throws -> URL {
        guard let url = URL(string: "\(baseURL)/\(path)") else {
            throw NetworkError.invalidURL
        }
        return url
    }
}

private actor CacheActor {
    private var blockFeeCache: [String: (fee: Int, timestamp: Date)] = [:]
    private var requestCount: Int = 0
    private var lastResetTime = Date()
    private var retryDelay: TimeInterval = 1.0

    func cachedFee(for hash: String, now: Date, expiration: TimeInterval) -> Int? {
        guard let cached = blockFeeCache[hash] else { return nil }
        if now.timeIntervalSince(cached.timestamp) < expiration {
            return cached.fee
        } else {
            blockFeeCache.removeValue(forKey: hash)
            return nil
        }
    }

    func storeFee(_ fee: Int, for hash: String) {
        blockFeeCache[hash] = (fee: fee, timestamp: Date())
    }

    func pruneIfNeeded(maxSize: Int) {
        guard blockFeeCache.count >= maxSize else { return }
        let sorted = blockFeeCache.sorted { $0.value.timestamp < $1.value.timestamp }
        let toRemove = sorted.prefix(blockFeeCache.count - maxSize + 1)
        for (key, _) in toRemove {
            blockFeeCache.removeValue(forKey: key)
        }
    }

    func rateLimitState(now: Date) -> (requestCount: Int, delay: TimeInterval, shouldReset: Bool) {
        let shouldReset = now.timeIntervalSince(lastResetTime) > 60
        return (requestCount, retryDelay, shouldReset)
    }

    func resetRateLimit(now: Date) {
        requestCount = 0
        lastResetTime = now
        retryDelay = 1.0
    }

    func incrementRequestCount() {
        requestCount += 1
    }

    func currentRetryDelay() -> TimeInterval {
        retryDelay
    }

    func doubleRetryDelay() {
        retryDelay *= 2.0
    }

    func resetRetryDelay() {
        retryDelay = 1.0
    }
}

final class MempoolSpaceService: @unchecked Sendable {
    private let baseURL: String
    private let networkClient: NetworkClient
    private let maxRetries = 3
    private let cacheExpiration: TimeInterval = 300
    private let maxCacheSize = 50
    private let cache = CacheActor()

    init(baseURL: String = "https://mempool.space/api/v1", networkClient: NetworkClient = URLSessionNetworkClient()) {
        self.baseURL = baseURL
        self.networkClient = networkClient
    }

    // MARK: - Public Methods

    func getRecentBlocks(limit: Int = 5) async throws -> [Block] {
        let url = try URLBuilder(baseURL: baseURL).url(path: "blocks")
        let responses: [MempoolSpaceBlockResponse] = try await networkClient.fetch([MempoolSpaceBlockResponse].self, from: url)
        return responses.prefix(limit).map { Block(from: $0) }
    }

    func getBlockAverageFee(blockHash: String) async throws -> Int? {
        if let cached = await cache.cachedFee(for: blockHash, now: Date(), expiration: cacheExpiration) {
            return cached
        }

        let url = try URLBuilder(baseURL: baseURL).url(path: "block/\(blockHash)")

        do {
            let response: MempoolSpaceBlockResponse = try await networkClient.fetch(MempoolSpaceBlockResponse.self, from: url)
            let fee: Int? = (response.extras?.medianFeeRate ?? response.extras?.medianFee).map { Int($0) }

            if let validFee = fee {
                await cache.storeFee(validFee, for: blockHash)
                await cache.pruneIfNeeded(maxSize: maxCacheSize)
            }

            return fee
        } catch let error as NetworkError {
            switch error {
            case .httpError(404):
                return nil
            default:
                throw error
            }
        }
    }

    func getRecentMempoolTransactions(blockCount: Int = Constants.blockDisplayCount) async throws -> [MempoolTransaction] {
        let url = try URLBuilder(baseURL: baseURL).url(path: "fees/mempool-blocks")
        let responses: [MempoolSpaceMempoolBlockResponse] = try await networkClient.fetch([MempoolSpaceMempoolBlockResponse].self, from: url)

        var transactions: [MempoolTransaction] = []

        for position in 0..<blockCount {
            let apiIndex = (blockCount - 1) - position
            let estimatedTime = Constants.blockDurationMinutes + (position * Constants.blockDurationMinutes)

            if apiIndex < responses.count {
                let blockData = responses[apiIndex]
                let medianFee = max(blockData.medianFee, 1.0)

                transactions.append(MempoolTransaction(
                    txid: "mempool_block_\(position)",
                    fee: Int(medianFee * 250),
                    vsize: 250,
                    position: position,
                    estimatedConfirmationTime: estimatedTime,
                    medianFee: Int(max(ceil(medianFee), 1)),
                    blockSize: blockData.blockSize,
                    blockVSize: blockData.blockVSize,
                    nTx: blockData.nTx,
                    totalFees: blockData.totalFees,
                    feeRange: blockData.feeRange
                ))
            } else {
                let fallbackFee = max(1.0 - (Double(position) * 0.1), 0.1)
                transactions.append(MempoolTransaction(
                    txid: "mempool_block_\(position)",
                    fee: Int(fallbackFee * 250),
                    vsize: 250,
                    position: position,
                    estimatedConfirmationTime: estimatedTime,
                    medianFee: Int(max(ceil(fallbackFee), 1))
                ))
            }
        }

        return transactions
    }

    func getTransactions(forBlockHash hash: String) async throws -> [Transaction] {
        let url = try URLBuilder(baseURL: baseURL).url(path: "block/\(hash)/txs")
        return try await networkClient.fetch([Transaction].self, from: url)
    }

    // MARK: - Rate-limited request wrapper

    func makeRequest(to url: URL, retryCount: Int = 0) async throws -> Data {
        let now = Date()
        let state = await cache.rateLimitState(now: now)
        if state.shouldReset {
            await cache.resetRateLimit(now: now)
        }
        await cache.incrementRequestCount()

        let (data, response) = try await networkClient.data(from: url)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 429 {
            if retryCount < maxRetries {
                let delay = await cache.currentRetryDelay()
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await cache.doubleRetryDelay()
                return try await makeRequest(to: url, retryCount: retryCount + 1)
            } else {
                throw NetworkError.rateLimited
            }
        }

        await cache.resetRetryDelay()
        return data
    }
}
