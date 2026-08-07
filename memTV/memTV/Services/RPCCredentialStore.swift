//
//  RPCCredentialStore.swift
//  memTV
//
//  Keychain-backed storage for Bitcoin RPC credentials.
//

import Foundation
import Security

struct BitcoinRPCConfig: Equatable, Sendable {
    let nodeURL: String
    let rpcUser: String
    let rpcPassword: String
}

enum RPCCredentialStoreError: Error {
    case saveError(OSStatus)
    case readError(OSStatus)
    case deleteError(OSStatus)
    case missingValue
}

final class RPCCredentialStore: @unchecked Sendable {
    static let shared = RPCCredentialStore()

    private let service = "com.tkay.memTV.bitcoinRPC"
    private let accountURL = "nodeURL"
    private let accountUser = "rpcUser"
    private let accountPassword = "rpcPassword"

    func save(config: BitcoinRPCConfig) throws {
        try save(value: config.nodeURL, account: accountURL)
        try save(value: config.rpcUser, account: accountUser)
        try save(value: config.rpcPassword, account: accountPassword)
    }

    func load() throws -> BitcoinRPCConfig? {
        guard let nodeURL = try load(account: accountURL),
              let rpcUser = try load(account: accountUser),
              let rpcPassword = try load(account: accountPassword) else {
            return nil
        }
        return BitcoinRPCConfig(nodeURL: nodeURL, rpcUser: rpcUser, rpcPassword: rpcPassword)
    }

    func clear() throws {
        try delete(account: accountURL)
        try delete(account: accountUser)
        try delete(account: accountPassword)
    }

    // MARK: - Private helpers

    private func save(value: String, account: String) throws {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw RPCCredentialStoreError.saveError(status)
        }
    }

    private func load(account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data, let value = String(data: data, encoding: .utf8) else {
                throw RPCCredentialStoreError.missingValue
            }
            return value
        case errSecItemNotFound:
            return nil
        default:
            throw RPCCredentialStoreError.readError(status)
        }
    }

    private func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw RPCCredentialStoreError.deleteError(status)
        }
    }
}
