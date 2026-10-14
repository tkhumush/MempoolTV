import Testing
@testable import memTV

struct LiveFrameTests {
    // stats is a subscription name; its payload fields live at the top level.
    private let stats = """
    {"mempoolInfo":{"size":123,"bytes":456.25,"usage":999},
     "vBytesPerSecond":12.5,"fees":{"fastestFee":3.25,"minimumFee":1},
     "loadingIndicators":{"mempool":42,"blocks":100},
     "da":{"progressPercent":50,"difficultyChange":-1.25,
           "estimatedRetargetDate":1800000000000,"remainingBlocks":1008,
           "nextRetargetHeight":846720,"timeAvg":610000}}
    """

    @Test func decodesBlockAndInitSnapshot() throws {
        let json = """
        {"id":"abc","height":840000,"timestamp":1700000000,"tx_count":2,"weight":401}
        """
        let frame: LiveFrame = try Fixtures.decode("{\"block\":\(json),\"blocks\":[\(json)]}")
        #expect(frame.block?.id == "abc")
        #expect(frame.blocks?.first == frame.block)
        #expect(frame.block?.vsize == 100.25)
        #expect(frame.block?.extras == nil)
        #expect(frame.projections == nil)
    }

    @Test func projectionsRetainFractionalVsizeAndMissingMedian() throws {
        let frame: LiveFrame = try Fixtures.decode("""
        {"mempool-blocks":[{"blockVSize":1000.25,"nTx":2,"feeRange":[1,7,99]},
                           {"blockVSize":200,"nTx":1,"medianFee":0,"totalFees":0}]}
        """)
        let projections = try #require(frame.projections)
        #expect(projections.count == 2)
        #expect(projections[0].blockVSize == 1000.25)
        #expect(projections[0].medianFee == nil)
        #expect(projections[0].totalFees == nil)
        #expect(projections[0].feeRange == [1, 7, 99])
        #expect(projections[1].medianFee == 0)
    }

    @Test func decodesStatsAndLoadingIndicators() throws {
        let frame: LiveFrame = try Fixtures.decode(stats)
        #expect(frame.mempoolInfo?.size == 123)
        #expect(frame.mempoolInfo?.bytes == 456.25)
        #expect(frame.vBytesPerSecond == 12.5)
        #expect(frame.fees?.fastestFee == 3.25)
        #expect(frame.fees?.halfHourFee == nil)
        #expect(frame.loadingIndicators == ["mempool": 42, "blocks": 100])
        #expect(frame.da?.difficultyChange == -1.25)
    }

    @Test @MainActor func absentAndNullFieldsLeaveObservationsUnchanged() throws {
        let model = ObservatoryModel()
        model.consume(.frame(try Fixtures.decode(stats)))
        let received = model.queue.received
        for json in ["{}", "{\"block\":null,\"fees\":null,\"mempoolInfo\":null}",
                     "{\"loadingIndicators\":{\"mempool\":75}}", "{\"unknownFutureField\":123}"] {
            model.consume(.frame(try Fixtures.decode(json)))
        }
        #expect(model.queue.value?.size == 123)
        #expect(model.queue.received == received)
        #expect(model.incoming.value == 12.5)
        #expect(model.fees.value?.fastestFee == 3.25)
        #expect(model.difficulty.value?.remainingBlocks == 1008)
        #expect(model.loadingIndicators == ["mempool": 75])
        #expect(model.projections.value == nil)
        model.consume(.frame(try Fixtures.decode("""
        {"mempoolInfo":{"size":0,"bytes":0},"vBytesPerSecond":0,"mempool-blocks":[]}
        """)))
        #expect(model.queue.value?.size == 0)
        #expect(model.incoming.value == 0)
        #expect(model.projections.value == [])
    }

    @Test func emptyFrameDoesNotInventData() throws {
        let frame: LiveFrame = try Fixtures.decode("{}")
        #expect(frame.blocks == nil && frame.block == nil && frame.projections == nil)
        #expect(frame.fees == nil && frame.mempoolInfo == nil && frame.vBytesPerSecond == nil)
        #expect(frame.da == nil && frame.backlog == nil && frame.template == nil)
        #expect(frame.loadingIndicators == nil)
    }
}
