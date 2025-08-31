//
//  BitcoinNodeService.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import Foundation

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
            "params": [hash, 1] // verbosity = 1
        ]
        
        let response = try await sendRequest(requestData: requestData)
        requestID += 1
        
        guard let result = response["result"] as? [String: Any] else {
            throw BitcoinServiceError.invalidResponse
        }
        
        return Block(from: result)
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

