//
//  BitcoinModels.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import Foundation

// MARK: - Selection Types

enum SelectedBlockType: Equatable {
    case confirmed(Block)
    case mempool(MempoolTransaction)
}

enum PersistentSelection: Equatable {
    case confirmedBlock(hash: String)
    case mempoolBlock(position: Int)
    case none
}

// MARK: - Block

struct Block: Identifiable, Equatable, Codable {
    let id: String
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

    var isValid: Bool {
        !hash.isEmpty && height > 0
    }

    init(hash: String, height: Int, time: Int, txCount: Int, size: Int? = nil, weight: Int? = nil, totalFees: Double? = nil, medianFee: Double? = nil, subsidy: Double? = nil, miner: String? = nil) {
        self.id = hash
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

// MARK: - Mempool Space Block Response

struct MempoolSpaceBlockResponse: Codable {
    let id: String
    let height: Int
    let timestamp: Int
    let txCount: Int
    let size: Int
    let weight: Int
    let pool: MempoolSpacePool?
    let extras: MempoolSpaceBlockExtras?

    enum CodingKeys: String, CodingKey {
        case id, height, timestamp, size, weight, pool, extras
        case txCount = "tx_count"
    }
}

struct MempoolSpacePool: Codable {
    let name: String
}

struct MempoolSpaceBlockExtras: Codable {
    let totalFees: Int?
    let reward: Int?
    let medianFee: Double?
    let medianFeeRate: Double?

    enum CodingKeys: String, CodingKey {
        case totalFees = "totalFees"
        case reward
        case medianFee = "medianFee"
        case medianFeeRate = "medianFeeRate"
    }
}

extension Block {
    init(from response: MempoolSpaceBlockResponse) {
        let minerName: String? = response.pool?.name
        let totalFeesBTC: Double? = response.extras?.totalFees.map { Double($0) / 100_000_000.0 }
        let subsidyBTC: Double? = response.extras?.reward.map { Double($0) / 100_000_000.0 }

        self.init(
            hash: response.id,
            height: response.height,
            time: response.timestamp,
            txCount: response.txCount,
            size: response.size,
            weight: response.weight,
            totalFees: totalFeesBTC,
            medianFee: response.extras?.medianFee,
            subsidy: subsidyBTC,
            miner: minerName
        )
    }
}

// MARK: - Bitcoin RPC Block Response

struct BitcoinRPCBlockResponse: Codable {
    let hash: String
    let height: Int
    let time: Int
    let size: Int
    let weight: Int
    let tx: [BitcoinRPCTransaction]
    let previousblockhash: String?
}

struct BitcoinRPCTransaction: Codable {
    let txid: String
    let vin: [BitcoinRPCInput]
    let vout: [BitcoinRPCOutput]
    let fee: Double?
    let vsize: Int?
    let weight: Int?
}

struct BitcoinRPCInput: Codable {
    let coinbase: String?
    let sequence: UInt32?
}

struct BitcoinRPCOutput: Codable {
    let value: Double
    let n: Int
}

extension Block {
    init(from response: BitcoinRPCBlockResponse) {
        self.init(
            hash: response.hash,
            height: response.height,
            time: response.time,
            txCount: response.tx.count,
            size: response.size,
            weight: response.weight,
            subsidy: Constants.subsidy(atHeight: response.height)
        )
    }
}

// MARK: - Mempool Transaction

struct MempoolTransaction: Identifiable, Equatable, Codable {
    let id: Int
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

    var displayLabel: String {
        switch position {
        case 0: return "Next"
        default: return "+\(position)"
        }
    }

    init(txid: String, fee: Int, vsize: Int, position: Int = 0,
         estimatedConfirmationTime: Int = 30, medianFee: Int = 25,
         blockSize: Int = 0, blockVSize: Int = 0, nTx: Int = 0,
         totalFees: Int = 0, feeRange: [Double] = []) {
        self.id = position
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

// MARK: - Mempool Space Mempool Block Response

struct MempoolSpaceMempoolBlockResponse: Codable {
    let blockSize: Int
    let blockVSize: Int
    let nTx: Int
    let totalFees: Int
    let medianFee: Double
    let feeRange: [Double]

    enum CodingKeys: String, CodingKey {
        case blockSize, blockVSize, nTx, totalFees, medianFee, feeRange
    }
}

// MARK: - Mempool Info

struct MempoolInfo: Codable {
    let size: Int
    let bytes: Int
    let mempoolminfee: Double
}

// MARK: - Fee Range

struct FeeRange: Codable {
    let minFee: Int
    let maxFee: Int
    let txCount: Int

    var feeRate: Double {
        Double(minFee) / 1000.0
    }
}

// MARK: - Transaction

struct Transaction: Identifiable, Equatable, Codable {
    let id: String
    let txid: String
    let version: Int
    let locktime: Int
    let vin: [TxInput]
    let vout: [TxOutput]
    let size: Int
    let weight: Int
    let fee: Int
    let status: TransactionStatus?

    var shortTxid: String {
        String(txid.prefix(8)) + "..."
    }

    var totalOutputValue: Int {
        vout.reduce(0) { $0 + $1.value }
    }

    var totalOutputBTC: Double {
        Double(totalOutputValue) / 100_000_000.0
    }
}

struct TxInput: Codable {
    let txid: String?
    let vout: Int?
    let isCoinbase: Bool
    let sequence: Int?
    let scriptsig: String?
    let scriptsigAsm: String?
    let witness: [String]?
    let innerRedeemscriptAsm: String?
    let innerWitnessscriptAsm: String?
    let prevout: TxOutput?

    enum CodingKeys: String, CodingKey {
        case txid, vout, sequence, witness, prevout
        case isCoinbase = "is_coinbase"
        case scriptsig = "scriptsig"
        case scriptsigAsm = "scriptsig_asm"
        case innerRedeemscriptAsm = "inner_redeemscript_asm"
        case innerWitnessscriptAsm = "inner_witnessscript_asm"
    }
}

struct TxOutput: Codable {
    let scriptpubkey: String
    let scriptpubkeyAsm: String?
    let scriptpubkeyType: String
    let scriptpubkeyAddress: String?
    let value: Int

    enum CodingKeys: String, CodingKey {
        case value
        case scriptpubkey = "scriptpubkey"
        case scriptpubkeyAsm = "scriptpubkey_asm"
        case scriptpubkeyType = "scriptpubkey_type"
        case scriptpubkeyAddress = "scriptpubkey_address"
    }
}

struct TransactionStatus: Codable {
    let confirmed: Bool
    let blockHeight: Int?
    let blockHash: String?
    let blockTime: Int?

    enum CodingKeys: String, CodingKey {
        case confirmed
        case blockHeight = "block_height"
        case blockHash = "block_hash"
        case blockTime = "block_time"
    }
}

// MARK: - MiningPool

struct MiningPool: Codable, Identifiable {
    let poolId: Int
    let name: String
    let link: String
    let blockCount: Int
    let rank: Int
    let emptyBlocks: Int
    let slug: String
    let avgMatchRate: Double?
    let avgFeeDelta: String?
    let poolUniqueId: Int

    var id: Int { poolId }

    enum CodingKeys: String, CodingKey {
        case poolId = "poolId"
        case name, link
        case blockCount = "blockCount"
        case rank
        case emptyBlocks = "emptyBlocks"
        case slug
        case avgMatchRate = "avgMatchRate"
        case avgFeeDelta = "avgFeeDelta"
        case poolUniqueId = "poolUniqueId"
    }
}

struct MiningPoolsResponse: Codable {
    let pools: [MiningPool]
    let blockCount: Int
    let lastEstimatedHashrate: Double
    let lastEstimatedHashrate3d: Double?
    let lastEstimatedHashrate1w: Double?

    enum CodingKeys: String, CodingKey {
        case pools, blockCount
        case lastEstimatedHashrate
        case lastEstimatedHashrate3d
        case lastEstimatedHashrate1w
    }
}

// MARK: - Hashrate

struct HashrateDataPoint: Codable, Identifiable {
    let timestamp: Int
    let avgHashrate: Double

    var id: Int { timestamp }
}

struct HashrateResponse: Codable {
    let hashrates: [HashrateDataPoint]
    let currentHashrate: Double
    let currentDifficulty: Double
}

// MARK: - Price

struct PriceResponse: Codable {
    let time: Int
    let USD: Int
    let EUR: Int?
    let GBP: Int?
    let CAD: Int?
    let CHF: Int?
    let AUD: Int?
    let JPY: Int?
}

// MARK: - Fees

struct FeeEstimate: Codable {
    let fastestFee: Double
    let halfHourFee: Double
    let hourFee: Double
    let economyFee: Double
    let minimumFee: Double
}

// MARK: - Difficulty

struct DifficultyAdjustment: Codable {
    let progressPercent: Double
    let difficultyChange: Double
    let estimatedRetargetDate: Int
    let remainingBlocks: Int
    let remainingTime: Int
    let previousRetarget: Double
    let previousTime: Int
    let nextRetargetHeight: Int
    let timeAvg: Double
    let adjustedTimeAvg: Double?
    let timeOffset: Double
    let expectedBlocks: Double
}
