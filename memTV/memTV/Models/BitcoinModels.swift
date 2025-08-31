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
    
    init(from dictionary: [String: Any]) {
        // Handle both Bitcoin RPC format and mempool.space API format
        if let id = dictionary["id"] as? String {
            // mempool.space format
            self.hash = id
            self.height = dictionary["height"] as? Int ?? 0
            self.time = dictionary["timestamp"] as? Int ?? 0
            self.txCount = dictionary["tx_count"] as? Int ?? 0
        } else {
            // Bitcoin RPC format
            self.hash = dictionary["hash"] as? String ?? ""
            self.height = dictionary["height"] as? Int ?? 0
            self.time = dictionary["time"] as? Int ?? 0
            self.txCount = (dictionary["tx"] as? [Any])?.count ?? 0
        }
    }
    
    init(hash: String, height: Int, time: Int, txCount: Int) {
        self.hash = hash
        self.height = height
        self.time = time
        self.txCount = txCount
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
