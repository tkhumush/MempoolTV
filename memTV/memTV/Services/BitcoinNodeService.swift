//
//  BitcoinNodeService.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import Foundation

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

class BitcoinNodeService: ObservableObject {
    // Node connection settings
    private let nodeURL: String
    private let rpcUser: String
    private let rpcPassword: String
    
    // JSON-RPC request ID
    private var requestID = 1
    
    init(nodeURL: String = "http://localhost:8334", rpcUser: String = "rpcuser", rpcPassword: String = "rpcpassword") {
        self.nodeURL = nodeURL
        self.rpcUser = rpcUser
        self.rpcPassword = rpcPassword
    }
    
    // MARK: - Public Methods
    
    func getBlockCount() async throws -> Int {
        let requestData: [String: Any] = [
            "jsonrpc": "1.0",
            "id": requestID,
            "method": "getblockcount",
            "params": []
        ]
        
        let response = try await sendRequest(requestData: requestData)
        requestID += 1
        
        guard let result = response["result"] as? Int else {
            throw BitcoinServiceError.invalidResponse
        }
        
        return result
    }
    
    func getBlockHash(height: Int) async throws -> String {
        let requestData: [String: Any] = [
            "jsonrpc": "1.0",
            "id": requestID,
            "method": "getblockhash",
            "params": [height]
        ]
        
        let response = try await sendRequest(requestData: requestData)
        requestID += 1
        
        guard let result = response["result"] as? String else {
            throw BitcoinServiceError.invalidResponse
        }
        
        return result
    }
    
    func getBlock(hash: String) async throws -> Block {
        let requestData: [String: Any] = [
            "jsonrpc": "1.0",
            "id": requestID,
            "method": "getblock",
            "params": [hash, 2] // verbosity = 2 for detailed transaction info
        ]

        let response = try await sendRequest(requestData: requestData)
        requestID += 1

        guard let result = response["result"] as? [String: Any] else {
            throw BitcoinServiceError.invalidResponse
        }

        return Block(from: result)
    }

    func getDetailedBlock(hash: String) async throws -> Block {
        let requestData: [String: Any] = [
            "jsonrpc": "1.0",
            "id": requestID,
            "method": "getblock",
            "params": [hash, 2] // verbosity = 2 for full transaction details
        ]

        let response = try await sendRequest(requestData: requestData)
        requestID += 1

        guard let result = response["result"] as? [String: Any] else {
            throw BitcoinServiceError.invalidResponse
        }

        // Calculate additional fields from transaction data
        var block = Block(from: result)

        // Calculate total fees and fee statistics if transaction data is available
        if let transactions = result["tx"] as? [[String: Any]] {
            let fees = calculateBlockStats(transactions: transactions)
            let subsidy = calculateSubsidy(height: block.height)

            // Create enhanced block with calculated data
            block = Block(
                hash: block.hash,
                height: block.height,
                time: block.time,
                txCount: block.txCount,
                size: result["size"] as? Int,
                weight: result["weight"] as? Int,
                totalFees: fees.totalFees,
                medianFee: fees.medianFee,
                subsidy: subsidy,
                miner: extractMinerInfo(transactions: transactions)
            )
        }

        return block
    }

    private func calculateBlockStats(transactions: [[String: Any]]) -> (totalFees: Double, medianFee: Double) {
        var totalFees: Double = 0
        var fees: [Double] = []

        // Skip coinbase transaction (first transaction)
        for tx in transactions.dropFirst() {
            if let vout = tx["vout"] as? [[String: Any]],
               let vin = tx["vin"] as? [[String: Any]] {

                let outputValue = vout.compactMap { $0["value"] as? Double }.reduce(0, +)
                let inputValue = vin.compactMap { _ in 0.0 }.reduce(0, +) // Would need to fetch input transactions for accurate value

                // For now, use a simplified fee calculation
                // In a real implementation, you'd need to fetch input transaction details
                let estimatedFee = max(0.0001, outputValue * 0.01) // Rough estimate
                totalFees += estimatedFee
                fees.append(estimatedFee)
            }
        }

        let medianFee = fees.sorted()[safe: fees.count / 2] ?? 0.0
        return (totalFees, medianFee)
    }

    private func calculateSubsidy(height: Int) -> Double {
        let halvings = height / 210000
        let baseSubsidy = 50.0
        return halvings < 32 ? baseSubsidy / pow(2.0, Double(halvings)) : 0.0
    }

    private func extractMinerInfo(transactions: [[String: Any]]) -> String? {
        // Extract miner info from coinbase transaction
        guard let coinbase = transactions.first,
              let vin = coinbase["vin"] as? [[String: Any]],
              let firstInput = vin.first,
              let coinbaseHex = firstInput["coinbase"] as? String else {
            return nil
        }

        // Basic miner detection - this is simplified
        if coinbaseHex.contains("466f756e647279555341") { // FoundryUSA
            return "FoundryUSA"
        } else if coinbaseHex.contains("416e74506f6f6c") { // AntPool
            return "AntPool"
        } else if coinbaseHex.contains("4630506f6f6c") { // F2Pool
            return "F2Pool"
        } else {
            return "Unknown"
        }
    }

    func getMempoolInfo() async throws -> MempoolInfo {
        let requestData: [String: Any] = [
            "jsonrpc": "1.0",
            "id": requestID,
            "method": "getmempoolinfo",
            "params": []
        ]
        
        let response = try await sendRequest(requestData: requestData)
        requestID += 1
        
        guard let result = response["result"] as? [String: Any] else {
            throw BitcoinServiceError.invalidResponse
        }
        
        return MempoolInfo(from: result)
    }
    
    func getRawMempool() async throws -> [String] {
        let requestData: [String: Any] = [
            "jsonrpc": "1.0",
            "id": requestID,
            "method": "getrawmempool",
            "params": [false] // verbose = false
        ]
        
        let response = try await sendRequest(requestData: requestData)
        requestID += 1
        
        guard let result = response["result"] as? [String] else {
            throw BitcoinServiceError.invalidResponse
        }
        
        return result
    }
    
    // MARK: - Private Methods
    
    private func sendRequest(requestData: [String: Any]) async throws -> [String: Any] {
        guard let url = URL(string: nodeURL) else {
            throw BitcoinServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add basic authentication
        let loginString = "\(rpcUser):\(rpcPassword)"
        guard let loginData = loginString.data(using: .utf8) else {
            throw BitcoinServiceError.encodingError
        }
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        // Add request body
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestData, options: []) else {
            throw BitcoinServiceError.encodingError
        }
        request.httpBody = httpBody
        
        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BitcoinServiceError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            throw BitcoinServiceError.httpError(httpResponse.statusCode)
        }
        
        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw BitcoinServiceError.decodingError
        }
        
        // Check for RPC errors
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

