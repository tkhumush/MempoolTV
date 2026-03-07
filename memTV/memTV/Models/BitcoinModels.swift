//
//  BitcoinModels.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import Foundation

// MARK: - Selection Types

enum SelectedBlockType {
    case confirmed(Block)
    case mempool(MempoolTransaction)
}

enum PersistentSelection: Equatable {
    case confirmedBlock(hash: String)
    case mempoolBlock(position: Int)
    case none
}

// MARK: - Block

struct Block: Identifiable {
    let id = UUID()
    let hash: String
    let height: Int
    let time: Int
    let txCount: Int
    let size: Int?
    let weight: Int?
    let totalFees: Double?
    let medianFee: Double?
    let subsidy: Double?
    let miner: String?

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

    /// Parse from mempool.space API response
    static func fromMempoolSpace(_ dictionary: [String: Any]) -> Block {
        let hash = dictionary["id"] as? String ?? ""
        let height = dictionary["height"] as? Int ?? 0
        let time = dictionary["timestamp"] as? Int ?? 0
        let txCount = dictionary["tx_count"] as? Int ?? 0
        let size = dictionary["size"] as? Int
        let weight = dictionary["weight"] as? Int

        var totalFees: Double?
        var subsidy: Double?
        var medianFee: Double?

        if let extras = dictionary["extras"] as? [String: Any] {
            totalFees = (extras["totalFees"] as? Int).map { Double($0) / 100_000_000.0 }
            subsidy = (extras["reward"] as? Int).map { Double($0) / 100_000_000.0 }
            medianFee = extras["medianFee"] as? Double
        }

        let miner: String?
        if let pool = dictionary["pool"] as? [String: Any] {
            miner = pool["name"] as? String
        } else {
            miner = nil
        }

        return Block(hash: hash, height: height, time: time, txCount: txCount,
                     size: size, weight: weight, totalFees: totalFees,
                     medianFee: medianFee, subsidy: subsidy, miner: miner)
    }

    /// Parse from Bitcoin Core RPC response
    static func fromBitcoinRPC(_ dictionary: [String: Any]) -> Block {
        let hash = dictionary["hash"] as? String ?? ""
        let height = dictionary["height"] as? Int ?? 0
        let time = dictionary["time"] as? Int ?? 0
        let txCount = (dictionary["tx"] as? [Any])?.count ?? 0
        let size = dictionary["size"] as? Int
        let weight = dictionary["weight"] as? Int

        return Block(hash: hash, height: height, time: time, txCount: txCount,
                     size: size, weight: weight,
                     subsidy: Constants.subsidy(atHeight: height))
    }
}

// MARK: - Mempool Transaction

struct MempoolTransaction {
    let txid: String
    let fee: Int
    let vsize: Int
    let position: Int
    let estimatedConfirmationTime: Int
    let medianFee: Int
    let blockSize: Int
    let blockVSize: Int
    let nTx: Int
    let totalFees: Int
    let feeRange: [Double]

    init(txid: String, fee: Int, vsize: Int, position: Int = 0,
         estimatedConfirmationTime: Int = 30, medianFee: Int = 25,
         blockSize: Int = 0, blockVSize: Int = 0, nTx: Int = 0,
         totalFees: Int = 0, feeRange: [Double] = []) {
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

// MARK: - Mempool Info

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

// MARK: - Fee Range

struct FeeRange {
    let minFee: Int
    let maxFee: Int
    let txCount: Int
}
