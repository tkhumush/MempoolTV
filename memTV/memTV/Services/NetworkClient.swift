//
//  NetworkClient.swift
//  memTV
//
//  Shared network abstraction for mempool.space REST calls and RPC transport.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case httpError(Int)
    case decodingError(Error)
    case networkError(Error)
    case rateLimited
    case invalidResponse
}

protocol NetworkClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension NetworkClient {
    func fetch<T: Decodable>(_ type: T.Type, from url: URL, decoder: JSONDecoder = JSONDecoder()) async throws -> T {
        let (data, response) = try await data(from: url)
        try validate(response: response)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    func fetch<T: Decodable>(_ type: T.Type, for request: URLRequest, decoder: JSONDecoder = JSONDecoder()) async throws -> T {
        let (data, response) = try await data(for: request)
        try validate(response: response)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 429:
            throw NetworkError.rateLimited
        default:
            throw NetworkError.httpError(httpResponse.statusCode)
        }
    }
}

struct URLSessionNetworkClient: NetworkClient, @unchecked Sendable {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw NetworkError.networkError(error)
        }
    }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(from: url)
        } catch {
            throw NetworkError.networkError(error)
        }
    }
}
