//
//  MinerDetector.swift
//  memTV
//
//  Coinbase tag based miner detection with an expanded pool lookup table.
//

import Foundation

enum MinerDetector {
    static let poolIdentifiers: [String: String] = [
        "466f756e647279555341": "FoundryUSA",
        "416e74506f6f6c": "AntPool",
        "4632506f6f6c": "F2Pool",
        "42696e616e6365506f6f6c": "BinancePool",
        "4254432e636f6d": "BTC.com",
        "566961425443": "ViaBTC",
        "4d61726120506f6f6c": "Mara Pool",
        "534c20506f6f6c": "SL Pool",
        "53656661616c6b": "Saferook",
        "6f6365616e": "Ocean",
        "506f6f6c696e": "Poolin",
        "537061776f6f6c": "SpiderPool",
        "6c75786f72": "Luxor",
        "4352616773": "Craggs",
        "776562353": "Web3 Pool",
        "5361746f7368692053696c766572": "Satoshi Silver",
        "4b616e6f706f6f6c": "Kanopool",
        "42544350": "BTCP",
        "454c6967697573": "Eligius",
        "736c757368706f6f6c": "SlushPool",
        "62726169747370617665": "Braiins Pool",
        "6d6d70": "MMP",
        "5465727261666f726d": "TerraForm",
        "64656372656564": "Decreed"
    ]

    static func minerName(from transactions: [BitcoinRPCTransaction]) -> String? {
        guard let coinbase = transactions.first,
              let input = coinbase.vin.first,
              let coinbaseHex = input.coinbase else {
            return nil
        }

        for (identifier, name) in poolIdentifiers {
            if coinbaseHex.contains(identifier) {
                return name
            }
        }
        return "Unknown"
    }

    static func minerName(from coinbaseHex: String) -> String? {
        for (identifier, name) in poolIdentifiers {
            if coinbaseHex.contains(identifier) {
                return name
            }
        }
        return "Unknown"
    }
}
