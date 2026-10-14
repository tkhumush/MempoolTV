import Foundation
@testable import memTV

enum Fixtures {
    static func decode<T: Decodable>(_ json: String, as type: T.Type = T.self) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    static func block(_ id: String = "a", height: Int = 840_000) throws -> ChainBlock {
        try decode("""
        {"id":"\(id)","height":\(height),"timestamp":1700000000,
         "tx_count":2,"weight":400001,"previousblockhash":"parent",
         "extras":{"totalFees":1000000,"reward":313500000,"medianFee":2.25}}
        """)
    }

    static func transaction(_ id: String, vsize: Double, rate: Double) throws -> TemplateTransaction {
        // Wire fee is deliberately independent of the effective/package rate.
        try decode("[\"\(id)\",100,\(vsize),10000,\(rate),0]")
    }
}
