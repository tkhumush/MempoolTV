//
//  BitcoinModels.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import Foundation

// MARK: - Data Models

struct Block: Identifiable {
    let id = UUID()
    let hash: String
    let height: Int
    let time: Int
    let txCount: Int

    // Additional detailed fields
    let size: Int?
    let weight: Int?
    let totalFees: Double?
    let medianFee: Double?
    let subsidy: Double?
    let miner: String?

    init(from dictionary: [String: Any]) {
        // Handle both Bitcoin RPC format and mempool.space API format
        if let id = dictionary["id"] as? String {
            // mempool.space format
            self.hash = id
            self.height = dictionary["height"] as? Int ?? 0
            self.time = dictionary["timestamp"] as? Int ?? 0
            self.txCount = dictionary["tx_count"] as? Int ?? 0
            self.size = dictionary["size"] as? Int
            self.weight = dictionary["weight"] as? Int

            // Extract data from extras section
            if let extras = dictionary["extras"] as? [String: Any] {
                self.totalFees = (extras["totalFees"] as? Int).map { Double($0) / 100_000_000.0 } // Convert sats to BTC
                self.subsidy = (extras["reward"] as? Int).map { Double($0) / 100_000_000.0 } // Convert sats to BTC
                self.medianFee = extras["medianFee"] as? Double // This is the median fee in sat/vB
            } else {
                self.totalFees = nil
                self.subsidy = nil
                self.medianFee = nil
            }

            // Extract miner info from pool data
            if let pool = dictionary["pool"] as? [String: Any] {
                self.miner = pool["name"] as? String
            } else {
                self.miner = nil
            }
        } else {
            // Bitcoin RPC format
            self.hash = dictionary["hash"] as? String ?? ""
            self.height = dictionary["height"] as? Int ?? 0
            self.time = dictionary["time"] as? Int ?? 0
            self.txCount = (dictionary["tx"] as? [Any])?.count ?? 0
            self.size = dictionary["size"] as? Int
            self.weight = dictionary["weight"] as? Int

            // Calculate total fees from transaction data if available
            if let transactions = dictionary["tx"] as? [String] {
                // For now, we'll set these as nil and calculate them elsewhere
                self.totalFees = nil
                self.medianFee = nil
            } else {
                self.totalFees = nil
                self.medianFee = nil
            }

            // Subsidy calculation: 6.25 BTC for blocks after halving
            let halvings = self.height / 210000
            let baseSubsidy = 50.0
            self.subsidy = halvings < 32 ? baseSubsidy / pow(2.0, Double(halvings)) : 0.0

            // Miner info not available from basic RPC call
            self.miner = nil
        }
    }

    init(hash: String, height: Int, time: Int, txCount: Int, size: Int? = nil, weight: Int? = nil, totalFees: Double? = nil, medianFee: Double? = nil, subsidy: Double? = nil, miner: String? = nil) {
        self.hash = hash
        self.height = height
        self.time = time
        self.txCount = txCount
        self.size = size
        self.weight = weight
        self.totalFees = totalFees
        self.medianFee = medianFee
        self.subsidy = subsidy
        self.miner = miner
    }
}

struct MempoolInfo {
    let size: Int
    let bytes: Int
    let mempoolminfee: Double
    
    init(from dictionary: [String: Any]) {
        self.size = dictionary["size"] as? Int ?? 0
        self.bytes = dictionary["bytes"] as? Int ?? 0
        self.mempoolminfee = dictionary["mempoolminfee"] as? Double ?? 0.0
    }
    
    init(size: Int, bytes: Int, mempoolminfee: Double) {
        self.size = size
        self.bytes = bytes
        self.mempoolminfee = mempoolminfee
    }
}
