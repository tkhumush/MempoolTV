//
//  MempoolSpaceService.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import Foundation

class MempoolSpaceService: ObservableObject {
    private let baseURL = "https://mempool.space/api/v1"
    
    // Rate limiting tracking
    private var requestCount: Int = 0
    private var lastResetTime = Date()
    private var retryDelay: TimeInterval = 1.0
    private let maxRetries = 3
    
    // Caching for block fees (hash -> (fee, timestamp))
    private var blockFeeCache: [String: (fee: Int, timestamp: Date)] = [:]
    private let cacheExpiration: TimeInterval = 300 // 5 minutes cache
    
    // MARK: - Rate Limiting Helper
    
    private func makeRequest(to url: URL, retryCount: Int = 0) async throws -> Data {
        // Reset request counter every minute
        let now = Date()
        if now.timeIntervalSince(lastResetTime) > 60 {
            requestCount = 0
            lastResetTime = now
            retryDelay = 1.0 // Reset retry delay
        }
        
        requestCount += 1
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check for rate limiting
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 429 {
                    // Rate limited - implement exponential backoff
                    if retryCount < maxRetries {
                        print("Rate limited. Retrying in \(retryDelay) seconds...")
                        try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                        retryDelay *= 2.0 // Exponential backoff
                        return try await makeRequest(to: url, retryCount: retryCount + 1)
                    } else {
                        throw URLError(.badServerResponse)
                    }
                }
                
                // Reset retry delay on successful request
                retryDelay = 1.0
            }
            
            return data
        } catch {
            // Log API usage statistics
            print("API Request failed. Current usage: \(requestCount) requests in last minute")
            throw error
        }
    }
    
    // MARK: - Public Methods
    
    func getRecentBlocks() async throws -> [Block] {
        let url = URL(string: "\(baseURL)/blocks")!
        let data = try await makeRequest(to: url)
        
        let blocksData = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        return blocksData.prefix(5).compactMap { blockData in
            Block(from: blockData)
        }
    }
    
    // Get fee recommendations (priority levels and confirmation estimates)
    func getFeeRecommendations() async throws -> (high: Int, medium: Int, low: Int, estimatedMinutes: Int) {
        let url = URL(string: "\(baseURL)/fees/recommended")!
        let data = try await makeRequest(to: url)
        
        let feeData = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        let high = feeData["fastestFee"] as? Int ?? 45
        let medium = feeData["halfHourFee"] as? Int ?? 30
        let low = feeData["hourFee"] as? Int ?? 15
        
        // Estimate confirmation time based on medium priority (typically ~30 minutes)
        let estimatedMinutes = 30
        
        return (high: high, medium: medium, low: low, estimatedMinutes: estimatedMinutes)
    }
    
    // Get average fee for a specific block by hash (with caching)
    func getBlockAverageFee(blockHash: String) async throws -> Int? {
        // Check cache first
        if let cached = blockFeeCache[blockHash] {
            let age = Date().timeIntervalSince(cached.timestamp)
            if age < cacheExpiration {
                print("Using cached block fee for \(blockHash.prefix(8))")
                return cached.fee
            } else {
                // Remove expired cache entry
                blockFeeCache.removeValue(forKey: blockHash)
            }
        }
        
        let url = URL(string: "\(baseURL)/block/\(blockHash)")!
        
        do {
            let data = try await makeRequest(to: url)
            let blockData = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            var fee: Int?
            
            // Calculate average fee from block data
            if let extras = blockData["extras"] as? [String: Any],
               let medianFeeRate = extras["medianFeeRate"] as? Double {
                fee = Int(medianFeeRate)
            }
            
            // Fallback: estimate based on total fees and transaction count
            if fee == nil,
               let totalFees = blockData["totalFees"] as? Int,
               let txCount = blockData["tx_count"] as? Int,
               txCount > 0 {
                fee = totalFees / txCount / 250 // Approximate sat/vB
            }
            
            // Cache the result if we got one
            if let validFee = fee {
                blockFeeCache[blockHash] = (fee: validFee, timestamp: Date())
                print("Cached block fee for \(blockHash.prefix(8)): \(validFee) sat/vB")
            }
            
            return fee
        } catch {
            // Return nil if block data cannot be fetched
            return nil
        }
    }
    
    // Get recent mempool blocks with median fee information
    func getRecentMempoolTransactions() async throws -> [MempoolTransaction] {
        let url = URL(string: "\(baseURL)/fees/mempool-blocks")!
        let data = try await makeRequest(to: url)
        
        let mempoolBlocks = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        let timestamp = Date().timeIntervalSince1970
        
        var transactions: [MempoolTransaction] = []
        
        // Create 8 mempool blocks with correct positioning
        // Position 0 = rightmost (next to confirm), Position 7 = leftmost (furthest)
        for position in 0..<8 {
            let apiIndex = 7 - position // Map position to API array: position 0 uses mempoolBlocks[7], position 7 uses mempoolBlocks[0]
            let medianFee: Double
            let estimatedTime: Int
            
            if apiIndex < mempoolBlocks.count {
                // Use real data from mempool.space - medianFee is a Double
                let blockData = mempoolBlocks[apiIndex]
                medianFee = blockData["medianFee"] as? Double ?? 1.0
                // Position 0 (rightmost) = shortest time (~10min), Position 7 (leftmost) = longest time (~80min)
                estimatedTime = 10 + (position * 10)
                
                // Extract additional mempool block data
                let blockSize = blockData["blockSize"] as? Int ?? 0
                let blockVSize = blockData["blockVSize"] as? Int ?? 0
                let nTx = blockData["nTx"] as? Int ?? 0
                let totalFees = blockData["totalFees"] as? Int ?? 0
                let feeRange = blockData["feeRange"] as? [Double] ?? []
                
                let transaction = MempoolTransaction(
                    txid: "mempool_block_\(position)_\(Int(timestamp))",
                    fee: Int(medianFee * 250), // Convert sat/vB to total fee (assuming ~250 vB transaction)
                    vsize: 250,
                    position: position,
                    estimatedConfirmationTime: estimatedTime,
                    medianFee: Int(max(ceil(medianFee), 1)), // Round up, minimum 1 sat/vB for display
                    blockSize: blockSize,
                    blockVSize: blockVSize,
                    nTx: nTx,
                    totalFees: totalFees,
                    feeRange: feeRange
                )
                
                transactions.append(transaction)
            } else {
                // Fallback for positions beyond available data
                medianFee = max(1.0 - (Double(position) * 0.1), 0.1) // Lower fees for higher positions
                estimatedTime = 10 + (position * 10)
                
                let transaction = MempoolTransaction(
                    txid: "mempool_block_\(position)_\(Int(timestamp))",
                    fee: Int(medianFee * 250), // Convert sat/vB to total fee (assuming ~250 vB transaction)
                    vsize: 250,
                    position: position,
                    estimatedConfirmationTime: estimatedTime,
                    medianFee: Int(max(ceil(medianFee), 1)) // Round up, minimum 1 sat/vB for display
                )
                
                transactions.append(transaction)
            }
        }
        
        return transactions
    }
    
    // MARK: - Monitoring
    
    func getAPIUsageStats() -> (requestsPerMinute: Int, cacheHits: Int, totalRequests: Int) {
        let cacheHits = blockFeeCache.count
        return (requestsPerMinute: requestCount, cacheHits: cacheHits, totalRequests: requestCount)
    }
    
    func logAPIUsage() {
        let stats = getAPIUsageStats()
        print("📊 API Usage Stats:")
        print("   • Requests this minute: \(stats.requestsPerMinute)")
        print("   • Cached block fees: \(stats.cacheHits)")
        print("   • Cache hit rate: ~\(stats.cacheHits > 0 ? Int((Double(stats.cacheHits) / Double(stats.totalRequests + stats.cacheHits)) * 100) : 0)%")
    }
}

// MARK: - Data Models for mempool.space

struct MempoolTransaction {
    let txid: String
    let fee: Int
    let vsize: Int
    let position: Int // Position in confirmation queue (0 = next to confirm)
    let estimatedConfirmationTime: Int // Minutes until confirmation
    let medianFee: Int // Median fee in sat/vB from mempool.space
    
    // Additional mempool block data from API
    let blockSize: Int // Total block size in bytes
    let blockVSize: Int // Virtual block size
    let nTx: Int // Number of transactions
    let totalFees: Int // Total fees in satoshis
    let feeRange: [Double] // Array of fee values showing the spread
    
    init(from dictionary: [String: Any]) {
        self.txid = dictionary["txid"] as? String ?? ""
        self.fee = dictionary["fee"] as? Int ?? 0
        self.vsize = dictionary["vsize"] as? Int ?? 0
        self.position = dictionary["position"] as? Int ?? 0
        self.estimatedConfirmationTime = dictionary["estimatedConfirmationTime"] as? Int ?? 30
        self.medianFee = dictionary["medianFee"] as? Int ?? 25
        self.blockSize = dictionary["blockSize"] as? Int ?? 0
        self.blockVSize = dictionary["blockVSize"] as? Int ?? 0
        self.nTx = dictionary["nTx"] as? Int ?? 0
        self.totalFees = dictionary["totalFees"] as? Int ?? 0
        self.feeRange = dictionary["feeRange"] as? [Double] ?? []
    }
    
    init(txid: String, fee: Int, vsize: Int, position: Int = 0, estimatedConfirmationTime: Int = 30, medianFee: Int = 25, blockSize: Int = 0, blockVSize: Int = 0, nTx: Int = 0, totalFees: Int = 0, feeRange: [Double] = []) {
        self.txid = txid
        self.fee = fee
        self.vsize = vsize
        self.position = position
        self.estimatedConfirmationTime = estimatedConfirmationTime
        self.medianFee = medianFee
        self.blockSize = blockSize
        self.blockVSize = blockVSize
        self.nTx = nTx
        self.totalFees = totalFees
        self.feeRange = feeRange
    }
}

