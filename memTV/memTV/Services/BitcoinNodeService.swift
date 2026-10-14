//
//  BitcoinNodeService.swift
//  memTV
//
//  Bitcoin Core JSON-RPC client using Codable models and an injectable NetworkClient.
//

import Foundation

struct RPCError: Codable, Error {
    let code: Int
    let message: String
}

enum BitcoinServiceError: Error {
    case invalidURL
    case encodingError
    case networkError(Error)
    case httpError(Int)
    case decodingError(Error)
    case invalidResponse
    case rpcError(RPCError)
    case unauthorized
    case missingCredentials
}

private struct JSONRPCRequest<Params: Encodable>: Encodable {
    let jsonrpc: String
    let id: String
    let method: String
    let params: Params
}

private struct JSONRPCResponse<Result: Decodable>: Decodable {
    let result: Result?
    let error: RPCError?
    let id: String?
}

final class BitcoinNodeService: @unchecked Sendable {
    private let config: BitcoinRPCConfig
    private let networkClient: NetworkClient
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(config: BitcoinRPCConfig, networkClient: NetworkClient) {
        self.config = config
        self.networkClient = networkClient
    }

    // MARK: - Public Methods

    func getBlockCount() async throws -> Int {
        try await performRPC(method: "getblockcount", params: [Int]())
    }

    func getBlockHash(height: Int) async throws -> String {
        try await performRPC(method: "getblockhash", params: [height])
    }

    func getBlock(hash: String) async throws -> Block {
        let response: BitcoinRPCBlockResponse = try await performRPC(method: "getblock", params: [RPCParameter.string(hash), RPCParameter.integer(2)])
        return Block(from: response)
    }

    func getDetailedBlock(hash: String) async throws -> Block {
        let response: BitcoinRPCBlockResponse = try await performRPC(method: "getblock", params: [RPCParameter.string(hash), RPCParameter.integer(2)])
        var block = Block(from: response)

        if let miner = MinerDetector.minerName(from: response.tx) {
            block = Block(
                hash: block.hash,
                height: block.height,
                time: block.time,
                txCount: block.txCount,
                size: block.size,
                weight: block.weight,
                totalFees: block.totalFees,
                medianFee: block.medianFee,
                subsidy: block.subsidy,
                miner: miner
            )
        }

        return block
    }

    func getMempoolInfo() async throws -> MempoolInfo {
        try await performRPC(method: "getmempoolinfo", params: [Int]())
    }

    func getRawMempool() async throws -> [String] {
        try await performRPC(method: "getrawmempool", params: [false])
    }

    // MARK: - Generic RPC

    private func performRPC<Result: Decodable, Params: Encodable>(
        method: String,
        params: Params
    ) async throws -> Result {
        guard let url = URL(string: config.nodeURL) else {
            throw BitcoinServiceError.invalidURL
        }

        let requestPayload = JSONRPCRequest(
            jsonrpc: "1.0",
            id: UUID().uuidString,
            method: method,
            params: params
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let loginString = "\(config.rpcUser):\(config.rpcPassword)"
        guard let loginData = loginString.data(using: .utf8) else {
            throw BitcoinServiceError.encodingError
        }
        request.setValue("Basic \(loginData.base64EncodedString())", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try encoder.encode(requestPayload)
        } catch {
            throw BitcoinServiceError.encodingError
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await networkClient.data(for: request)
        } catch let error as NetworkError {
            switch error {
            case .httpError(401), .httpError(403):
                throw BitcoinServiceError.unauthorized
            case .httpError(let code):
                throw BitcoinServiceError.httpError(code)
            default:
                throw BitcoinServiceError.networkError(error)
            }
        } catch {
            throw BitcoinServiceError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BitcoinServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 401, 403:
            throw BitcoinServiceError.unauthorized
        case 200...299:
            break
        default:
            throw BitcoinServiceError.httpError(httpResponse.statusCode)
        }

        let rpcResponse: JSONRPCResponse<Result>
        do {
            rpcResponse = try decoder.decode(JSONRPCResponse<Result>.self, from: data)
        } catch {
            throw BitcoinServiceError.decodingError(error)
        }

        if let rpcError = rpcResponse.error {
            throw BitcoinServiceError.rpcError(rpcError)
        }

        guard let result = rpcResponse.result else {
            throw BitcoinServiceError.invalidResponse
        }

        return result
    }
}

private enum RPCParameter: Encodable {
    case string(String), integer(Int)
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .integer(let value): try container.encode(value)
        }
    }
}
