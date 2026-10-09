import Foundation
import Testing
@testable import memTV

struct TelemetryMathTests {
    @Test func statisticsSamplesAggregateMeasuredBuckets() throws {
        // Fixed 39-bucket fixture in upstream /statistics/2h order. Do not derive
        // its length or expected band totals from the production feeFloors array.
        let buckets = (1...39).map(String.init).joined(separator: ",")
        let samples: [BacklogSample] = try Fixtures.decode("""
        [{"added":1700000060,"vsizes":[\(buckets)],"vbytes_per_second":12.5},
         {"added":1700000000,"vsizes":[\(buckets)]}]
        """)
        #expect(samples[0].bands == [3, 12, 21, 30, 714])
        #expect(samples[0].bands?.reduce(0, +) == 780)
        #expect(samples[1].vbytes_per_second == nil)
        let frame: LiveFrame = try Fixtures.decode("""
        {"live-2h-chart":{"added":1700000060,"vsizes":[\(buckets)],"vbytes_per_second":12.5}}
        """)
        #expect(frame.backlog?.bands == samples[0].bands)
    }

    @Test func unknownOrInvalidBacklogIsUnavailableNotZero() {
        #expect(TelemetryMath.backlog([]) == nil)
        #expect(TelemetryMath.backlog(Array(repeating: 1, count: 38)) == nil)
        #expect(TelemetryMath.backlog(Array(repeating: 1, count: 40)) == nil)
        for invalid in [-1.0, Double.nan, Double.infinity] {
            var buckets = Array(repeating: 0.0, count: 39)
            buckets[20] = invalid
            #expect(TelemetryMath.backlog(buckets) == nil)
        }
        #expect(TelemetryMath.backlog(Array(repeating: 0, count: 39)) == [0, 0, 0, 0, 0])
        #expect(TelemetryMath.backlog(Array(repeating: 0.25, count: 39)) == [0.5, 0.75, 0.75, 0.75, 7])
    }

    @Test func largestRemainderRoundsToExactlyOneHundredPercent() {
        #expect(TelemetryMath.shares([1, 1, 1]) == [334, 333, 333])
        #expect(TelemetryMath.shares([1, 2, 3]) == [167, 333, 500])
        #expect(TelemetryMath.shares([0, 7, 0]) == [0, 1000, 0])
        #expect(TelemetryMath.shares([]).isEmpty)
        #expect(TelemetryMath.shares([0, 0]).isEmpty)
        #expect(TelemetryMath.shares([-1, 2]).isEmpty)
        for counts in [[1, 1, 1, 1, 1, 1, 1], [34, 27, 19, 11, 5, 4], [1, 9999]] {
            let rounded = TelemetryMath.shares(counts)
            #expect(rounded.reduce(0, +) == 1000)
            let total = Double(counts.reduce(0, +))
            for index in counts.indices {
                #expect(abs(Double(rounded[index]) - Double(counts[index]) / total * 1000) < 1)
            }
        }
    }

    @Test func epochBoundariesCountUntilNextRetargetBlock() {
        for (height, remaining, progress) in [(0, 2016, 0.0), (1008, 1008, 0.5),
                                              (2015, 1, 2015.0 / 2016), (2016, 2016, 0.0),
                                              (4031, 1, 2015.0 / 2016), (4032, 2016, 0.0)] {
            let clock = TelemetryMath.epoch(height: height)
            #expect(clock.remaining == remaining)
            #expect(abs(clock.progress - progress) < 1e-12)
            #expect((height + clock.remaining) % 2016 == 0)
        }
    }

    @Test func retargetUsesProviderMillisecondsAndAllowsFutureEstimate() throws {
        let retarget: Retarget = try Fixtures.decode("""
        {"progressPercent":50,"difficultyChange":2,"remainingBlocks":1008,
         "nextRetargetHeight":4032,"timeAvg":600000,"estimatedRetargetDate":1700604800000}
        """)
        let now = Date(timeIntervalSince1970: 1700000000)
        #expect(retarget.estimatedDate.timeIntervalSince(now) == 1008 * 600)
        #expect(!SourceDate.validObservation(retarget.estimatedDate, now: now))
        // Forecast dates are not observations; the UI must still show this date.
        #expect(retarget.estimatedDate > now)
    }

    @Test func rewardIncludesFeesWithoutChangingProtocolSubsidy() throws {
        let block = try Fixtures.block()
        #expect(block.subsidy == 3.125)
        #expect(block.extras?.reward == 313_500_000)
        #expect(block.extras?.totalFees == 1_000_000)
        let reward = try #require(block.extras?.reward)
        let fees = try #require(block.extras?.totalFees)
        #expect(reward / 1e8 == block.subsidy + fees / 1e8)
        #expect(try Fixtures.block(height: 839_999).subsidy == 6.25)
        #expect(try Fixtures.block(height: 210_000 * 64).subsidy == 0)
    }
}
