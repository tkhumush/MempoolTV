//
//  MempoolSpaceService.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import Foundation

actor MempoolSpaceService {
    private let baseURL: String
    private let maxRetries = 3
    private let cacheExpiration: TimeInterval = 300
    private let maxCacheSize = 50

    private var requestCount: Int = 0
    private var lastResetTime = Date()
    private var retryDelay: TimeInterval = 1.0
    private var blockFeeCache: [String: (fee: Int, timestamp: Date)] = [:]

    init(baseURL: String = "https://mempool.space/api/v1") {
        self.baseURL = baseURL
    }

    // MARK: - Rate Limiting Helper

    private func makeRequest(to url: URL, retryCount: Int = 0) async throws -> Data {
        let now = Date()
        if now.timeIntervalSince(lastResetTime) > 60 {
            requestCount = 0
            lastResetTime = now
            retryDelay = 1.0
        }

        requestCount += 1

        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 429 {
            if retryCount < maxRetries {
                try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                retryDelay *= 2.0
                return try await makeRequest(to: url, retryCount: retryCount + 1)
            } else {
                throw URLError(.badServerResponse)
            }
        }

        retryDelay = 1.0
        return data
    }

    // MARK: - Public Methods

    func getRecentBlocks() async throws -> [Block] {
        let url = URL(string: "\(baseURL)/blocks")!
        let data = try await makeRequest(to: url)

        let blocksData = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        return blocksData.prefix(5).map { Block.fromMempoolSpace($0) }
    }

    func getBlockAverageFee(blockHash: String) async throws -> Int? {
        // Check cache
        if let cached = blockFeeCache[blockHash] {
            if Date().timeIntervalSince(cached.timestamp) < cacheExpiration {
                return cached.fee
            } else {
                blockFeeCache.removeValue(forKey: blockHash)
            }
        }

        let url = URL(string: "\(baseURL)/block/\(blockHash)")!

        do {
            let data = try await makeRequest(to: url)
            let blockData = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

            var fee: Int?

            if let extras = blockData["extras"] as? [String: Any],
               let medianFeeRate = extras["medianFeeRate"] as? Double {
                fee = Int(medianFeeRate)
            }

            if fee == nil,
               let totalFees = blockData["totalFees"] as? Int,
               let txCount = blockData["tx_count"] as? Int,
               txCount > 0 {
                fee = totalFees / txCount / 250
            }

            if let validFee = fee {
                evictCacheIfNeeded()
                blockFeeCache[blockHash] = (fee: validFee, timestamp: Date())
            }

            return fee
        } catch {
            return nil
        }
    }

    func getRecentMempoolTransactions() async throws -> [MempoolTransaction] {
        let url = URL(string: "\(baseURL)/fees/mempool-blocks")!
        let data = try await makeRequest(to: url)

        let mempoolBlocks = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        let timestamp = Date().timeIntervalSince1970

        var transactions: [MempoolTransaction] = []

        for position in 0..<Constants.blockDisplayCount {
            let apiIndex = (Constants.blockDisplayCount - 1) - position
            let estimatedTime = Constants.blockDurationMinutes + (position * Constants.blockDurationMinutes)

            if apiIndex < mempoolBlocks.count {
                let blockData = mempoolBlocks[apiIndex]
                let medianFee = blockData["medianFee"] as? Double ?? 1.0

                transactions.append(MempoolTransaction(
                    txid: "mempool_block_\(position)_\(Int(timestamp))",
                    fee: Int(medianFee * 250),
                    vsize: 250,
                    position: position,
                    estimatedConfirmationTime: estimatedTime,
                    medianFee: Int(max(ceil(medianFee), 1)),
                    blockSize: blockData["blockSize"] as? Int ?? 0,
                    blockVSize: blockData["blockVSize"] as? Int ?? 0,
                    nTx: blockData["nTx"] as? Int ?? 0,
                    totalFees: blockData["totalFees"] as? Int ?? 0,
                    feeRange: blockData["feeRange"] as? [Double] ?? []
                ))
            } else {
                let medianFee = max(1.0 - (Double(position) * 0.1), 0.1)

                transactions.append(MempoolTransaction(
                    txid: "mempool_block_\(position)_\(Int(timestamp))",
                    fee: Int(medianFee * 250),
                    vsize: 250,
                    position: position,
                    estimatedConfirmationTime: estimatedTime,
                    medianFee: Int(max(ceil(medianFee), 1))
                ))
            }
        }

        return transactions
    }

    // MARK: - Cache Management

    private func evictCacheIfNeeded() {
        guard blockFeeCache.count >= maxCacheSize else { return }
        // Remove oldest entries
        let sorted = blockFeeCache.sorted { $0.value.timestamp < $1.value.timestamp }
        let toRemove = sorted.prefix(blockFeeCache.count - maxCacheSize + 1)
        for (key, _) in toRemove {
            blockFeeCache.removeValue(forKey: key)
        }
    }
}
