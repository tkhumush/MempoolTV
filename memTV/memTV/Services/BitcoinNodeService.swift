//
//  BitcoinNodeService.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import Foundation

class BitcoinNodeService {
    private let nodeURL: String
    private let rpcUser: String
    private let rpcPassword: String

    init(nodeURL: String = "http://localhost:8332", rpcUser: String = "rpcuser", rpcPassword: String = "rpcpassword") {
        self.nodeURL = nodeURL
        self.rpcUser = rpcUser
        self.rpcPassword = rpcPassword
    }

    // MARK: - Generic RPC

    private func performRPC<T>(method: String, params: [Any] = [], transform: ([String: Any]) throws -> T) async throws -> T {
        let requestData: [String: Any] = [
            "jsonrpc": "1.0",
            "id": UUID().uuidString,
            "method": method,
            "params": params
        ]

        let response = try await sendRequest(requestData: requestData)

        guard let result = response["result"] else {
            throw BitcoinServiceError.invalidResponse
        }

        // For simple types, the result is directly the value; for dicts, it's a dict.
        // We pass the full response so the transform can handle both cases.
        return try transform(response)
    }

    // MARK: - Public Methods

    func getBlockCount() async throws -> Int {
        try await performRPC(method: "getblockcount") { response in
            guard let result = response["result"] as? Int else {
                throw BitcoinServiceError.invalidResponse
            }
            return result
        }
    }

    func getBlockHash(height: Int) async throws -> String {
        try await performRPC(method: "getblockhash", params: [height]) { response in
            guard let result = response["result"] as? String else {
                throw BitcoinServiceError.invalidResponse
            }
            return result
        }
    }

    func getBlock(hash: String) async throws -> Block {
        try await performRPC(method: "getblock", params: [hash, 2]) { response in
            guard let result = response["result"] as? [String: Any] else {
                throw BitcoinServiceError.invalidResponse
            }
            return Block.fromBitcoinRPC(result)
        }
    }

    func getDetailedBlock(hash: String) async throws -> Block {
        try await performRPC(method: "getblock", params: [hash, 2]) { response in
            guard let result = response["result"] as? [String: Any] else {
                throw BitcoinServiceError.invalidResponse
            }

            var block = Block.fromBitcoinRPC(result)

            if let transactions = result["tx"] as? [[String: Any]] {
                let fees = self.calculateBlockStats(transactions: transactions)
                block = Block(
                    hash: block.hash,
                    height: block.height,
                    time: block.time,
                    txCount: block.txCount,
                    size: result["size"] as? Int,
                    weight: result["weight"] as? Int,
                    totalFees: fees.totalFees,
                    medianFee: fees.medianFee,
                    subsidy: Constants.subsidy(atHeight: block.height),
                    miner: self.extractMinerInfo(transactions: transactions)
                )
            }

            return block
        }
    }

    func getMempoolInfo() async throws -> MempoolInfo {
        try await performRPC(method: "getmempoolinfo") { response in
            guard let result = response["result"] as? [String: Any] else {
                throw BitcoinServiceError.invalidResponse
            }
            return MempoolInfo(from: result)
        }
    }

    func getRawMempool() async throws -> [String] {
        try await performRPC(method: "getrawmempool", params: [false]) { response in
            guard let result = response["result"] as? [String] else {
                throw BitcoinServiceError.invalidResponse
            }
            return result
        }
    }

    // MARK: - Private Helpers

    private func calculateBlockStats(transactions: [[String: Any]]) -> (totalFees: Double, medianFee: Double) {
        var totalFees: Double = 0
        var fees: [Double] = []

        for tx in transactions.dropFirst() {
            if let vout = tx["vout"] as? [[String: Any]] {
                let outputValue = vout.compactMap { $0["value"] as? Double }.reduce(0, +)
                let estimatedFee = max(0.0001, outputValue * 0.01)
                totalFees += estimatedFee
                fees.append(estimatedFee)
            }
        }

        let medianFee = fees.sorted()[safe: fees.count / 2] ?? 0.0
        return (totalFees, medianFee)
    }

    private func extractMinerInfo(transactions: [[String: Any]]) -> String? {
        guard let coinbase = transactions.first,
              let vin = coinbase["vin"] as? [[String: Any]],
              let firstInput = vin.first,
              let coinbaseHex = firstInput["coinbase"] as? String else {
            return nil
        }

        if coinbaseHex.contains("466f756e647279555341") {
            return "FoundryUSA"
        } else if coinbaseHex.contains("416e74506f6f6c") {
            return "AntPool"
        } else if coinbaseHex.contains("4630506f6f6c") {
            return "F2Pool"
        } else {
            return "Unknown"
        }
    }

    // MARK: - Network

    private func sendRequest(requestData: [String: Any]) async throws -> [String: Any] {
        guard let url = URL(string: nodeURL) else {
            throw BitcoinServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let loginString = "\(rpcUser):\(rpcPassword)"
        guard let loginData = loginString.data(using: .utf8) else {
            throw BitcoinServiceError.encodingError
        }
        request.setValue("Basic \(loginData.base64EncodedString())", forHTTPHeaderField: "Authorization")

        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestData, options: []) else {
            throw BitcoinServiceError.encodingError
        }
        request.httpBody = httpBody

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BitcoinServiceError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            throw BitcoinServiceError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw BitcoinServiceError.decodingError
        }

        if let error = json["error"] as? [String: Any] {
            throw BitcoinServiceError.rpcError(error)
        }

        return json
    }
}

// MARK: - Error Definitions

enum BitcoinServiceError: Error {
    case invalidURL
    case encodingError
    case networkError
    case httpError(Int)
    case decodingError
    case invalidResponse
    case rpcError([String: Any])
}
