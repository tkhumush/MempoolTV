//
//  MempoolSpaceService.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import Foundation

class MempoolSpaceService: ObservableObject {
    private let baseURL = "https://mempool.space/api"
    
    // MARK: - Public Methods
    
    func getRecentBlocks() async throws -> [Block] {
        let url = URL(string: "\(baseURL)/blocks")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let blocksData = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        return blocksData.prefix(5).compactMap { blockData in
            Block(from: blockData)
        }
    }
    
    // Get recent mempool transactions using the correct endpoint
    func getRecentMempoolTransactions() async throws -> [MempoolTransaction] {
        // Use the mempool endpoint to get current mempool data
        let url = URL(string: "\(baseURL)/mempool")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let mempoolData = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        // Create mock transactions based on mempool count - showing top 5 next to confirm
        let count = mempoolData["count"] as? Int ?? 0
        let minCount = min(count, 5) // Limit to 5 transactions (next to be confirmed)
        
        var transactions: [MempoolTransaction] = []
        for i in 0..<minCount {
            // Create synthetic transaction data for display (ordered by priority/fee)
            transactions.append(MempoolTransaction(
                txid: "next_tx_\(i)",
                fee: 5000 - i * 200, // Higher fees first (more likely to confirm next)
                vsize: 220 + i * 15
            ))
        }
        
        return transactions
    }
}

// MARK: - Data Models for mempool.space

struct MempoolTransaction {
    let txid: String
    let fee: Int
    let vsize: Int
    
    init(from dictionary: [String: Any]) {
        self.txid = dictionary["txid"] as? String ?? ""
        self.fee = dictionary["fee"] as? Int ?? 0
        self.vsize = dictionary["vsize"] as? Int ?? 0
    }
    
    init(txid: String, fee: Int, vsize: Int) {
        self.txid = txid
        self.fee = fee
        self.vsize = vsize
    }
}

