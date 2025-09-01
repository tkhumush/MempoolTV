//
//  MempoolSpaceService.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import Foundation

class MempoolSpaceService: ObservableObject {
    private let baseURL = "https://mempool.space/api/v1"
    
    // MARK: - Public Methods
    
    func getRecentBlocks() async throws -> [Block] {
        let url = URL(string: "\(baseURL)/blocks")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let blocksData = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        return blocksData.prefix(5).compactMap { blockData in
            Block(from: blockData)
        }
    }
    
    // Get fee recommendations (priority levels and confirmation estimates)
    func getFeeRecommendations() async throws -> (high: Int, medium: Int, low: Int, estimatedMinutes: Int) {
        let url = URL(string: "\(baseURL)/fees/recommended")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let feeData = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        let high = feeData["fastestFee"] as? Int ?? 45
        let medium = feeData["halfHourFee"] as? Int ?? 30
        let low = feeData["hourFee"] as? Int ?? 15
        
        // Estimate confirmation time based on medium priority (typically ~30 minutes)
        let estimatedMinutes = 30
        
        return (high: high, medium: medium, low: low, estimatedMinutes: estimatedMinutes)
    }
    
    // Get average fee for a specific block by hash
    func getBlockAverageFee(blockHash: String) async throws -> Int? {
        let url = URL(string: "\(baseURL)/block/\(blockHash)")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let blockData = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            // Calculate average fee from block data
            if let extras = blockData["extras"] as? [String: Any],
               let medianFeeRate = extras["medianFeeRate"] as? Double {
                return Int(medianFeeRate)
            }
            
            // Fallback: estimate based on total fees and transaction count
            if let totalFees = blockData["totalFees"] as? Int,
               let txCount = blockData["tx_count"] as? Int,
               txCount > 0 {
                return totalFees / txCount / 250 // Approximate sat/vB
            }
            
            return nil
        } catch {
            // Return nil if block data cannot be fetched
            return nil
        }
    }
    
    // Get recent mempool transactions with position-based fee information
    func getRecentMempoolTransactions() async throws -> [MempoolTransaction] {
        // Get base fee recommendations first
        let baseFees = try await getFeeRecommendations()
        
        // Create mock transactions representing the next few blocks to be confirmed
        // Each position represents different confirmation priority and timing
        var transactions: [MempoolTransaction] = []
        let timestamp = Date().timeIntervalSince1970
        
        for i in 0..<8 {
            // Position 0 = furthest from confirmation (lowest fees, longest time) - leftmost
            // Position 7 = next to confirm (highest fees, shortest time) - rightmost, next to confirmed blocks
            let position = i
            
            // Calculate position-based fee multipliers (reversed logic)
            let feeMultiplier = 1.0 + (Double(position) * 0.1) // Increases by 10% each position (higher fees as we get closer to confirmation)
            let timeMultiplier = 1.0 - (Double(position) * 0.1) // Decreases by 10% each position (shorter time as we get closer to confirmation)
            
            let transaction = MempoolTransaction(
                txid: "mempool_tx_\(i)_\(Int(timestamp))",
                fee: Int(Double(baseFees.high) * feeMultiplier) + (position * 5), // Higher fees for positions closer to confirmation
                vsize: 220 + i * 15,
                position: position,
                estimatedConfirmationTime: max(Int(Double(baseFees.estimatedMinutes) * timeMultiplier), 5) // Shorter time for positions closer to confirmation, minimum 5 minutes
            )
            
            transactions.append(transaction)
        }
        
        return transactions
    }
}

// MARK: - Data Models for mempool.space

struct MempoolTransaction {
    let txid: String
    let fee: Int
    let vsize: Int
    let position: Int // Position in confirmation queue (0 = next to confirm)
    let estimatedConfirmationTime: Int // Minutes until confirmation
    
    init(from dictionary: [String: Any]) {
        self.txid = dictionary["txid"] as? String ?? ""
        self.fee = dictionary["fee"] as? Int ?? 0
        self.vsize = dictionary["vsize"] as? Int ?? 0
        self.position = dictionary["position"] as? Int ?? 0
        self.estimatedConfirmationTime = dictionary["estimatedConfirmationTime"] as? Int ?? 30
    }
    
    init(txid: String, fee: Int, vsize: Int, position: Int = 0, estimatedConfirmationTime: Int = 30) {
        self.txid = txid
        self.fee = fee
        self.vsize = vsize
        self.position = position
        self.estimatedConfirmationTime = estimatedConfirmationTime
    }
    
    // Calculate fee rates based on position for display
    var displayFeeInfo: (high: Int, medium: Int, low: Int) {
        let baseFee = fee / vsize // Calculate sat/vB
        let high = baseFee + (5 - position) // Higher priority fees for earlier positions
        let medium = Int(Double(high) * 0.7) // 70% of high fee
        let low = Int(Double(high) * 0.5) // 50% of high fee
        return (high: max(high, 1), medium: max(medium, 1), low: max(low, 1))
    }
}

