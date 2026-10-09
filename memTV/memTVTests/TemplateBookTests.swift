import Testing
@testable import memTV

struct TemplateBookTests {
    @Test func snapshotAndDeltaPreserveProviderPackageRate() throws {
        var book = TemplateBook()
        let frame: LiveFrame = try Fixtures.decode("""
        {"projected-block-transactions":{"index":0,"sequence":7,
         "blockTransactions":[["a",100,100.25,50000,12.5,0],["b",200,200,10000,1,0]]}}
        """)
        try book.apply(try #require(frame.template))
        #expect(book.sequence == 7)
        #expect(book.transactions["a"]?.vsize == 100.25)
        #expect(book.transactions["a"]?.rate == 12.5)
        try book.apply(Fixtures.decode("""
        {"index":0,"sequence":8,"delta":{"added":[["c",300,150,1000,2,0]],
          "removed":["b"],"changed":[["a",20]]}}
        """))
        #expect(book.sequence == 8)
        #expect(Set(book.transactions.keys) == Set(["a", "c"]))
        #expect(book.transactions["a"]?.rate == 20)
        #expect(book.transactions["a"]?.fee == 100)
    }

    @Test func sequenceGapClearsTemplateUntilFreshSnapshot() throws {
        var book = TemplateBook()
        let snapshot: TemplateUpdate = try Fixtures.decode("""
        {"index":0,"sequence":7,"blockTransactions":[["a",100,100,50000,1,0]]}
        """)
        try book.apply(snapshot)
        let gap: TemplateUpdate = try Fixtures.decode("""
        {"index":0,"sequence":9,"delta":{"added":[],"removed":[],"changed":[]}}
        """)
        #expect(throws: (any Error).self) { try book.apply(gap) }
        #expect(book.sequence == nil)
        #expect(book.transactions.isEmpty)
        try book.apply(snapshot)
        #expect(book.transactions.count == 1)
    }
}
