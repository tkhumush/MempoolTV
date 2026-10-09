import Foundation
import Testing
@testable import memTV

struct SourceDateAndPriceTests {
    @Test func parsesOffsetsAndFractionalSecondsAsAbsoluteInstants() throws {
        let utc = try #require(SourceDate.parse("2026-10-09T12:30:00Z"))
        #expect(SourceDate.parse("2026-10-09T08:30:00-04:00") == utc)
        #expect(SourceDate.parse("2026-10-09T18:00:00+05:30") == utc)
        let fractional = try #require(SourceDate.parse("2026-10-09T08:30:00.250-04:00"))
        #expect(abs(fractional.timeIntervalSince(utc) - 0.25) < 1e-6)
        #expect(SourceDate.parse("not a date") == nil)
        #expect(SourceDate.parse("") == nil)
    }

    @Test func futureParsingIsSeparateFromObservationValidation() throws {
        let now = try #require(SourceDate.parse("2026-10-09T12:30:00Z"))
        let future = try #require(SourceDate.parse("2030-01-01T00:00:00Z"))
        #expect(!SourceDate.validObservation(future, now: now))
        #expect(SourceDate.validObservation(now, now: now))
        #expect(SourceDate.validObservation(now.addingTimeInterval(60), now: now))
        #expect(!SourceDate.validObservation(now.addingTimeInterval(61), now: now))
        #expect(!SourceDate.validObservation(Date(timeIntervalSince1970: 0), now: now))
    }

    @Test func comparesLatestObservationAtOrBeforeQuoteMinus24Hours() throws {
        let time = 1_700_000_000.0
        let target = time - 86400
        // Unsorted history, including points after the comparison cutoff. The
        // cutoff is relative to quote time, even when the quote is 30 min old.
        let history = [PriceHistory.Point(time: target + 1, USD: 200),
                       .init(time: target - 3600, USD: 50),
                       .init(time: target, USD: 100),
                       .init(time: time, USD: 120)]
        let result = try #require(TelemetryMath.priceChange(
            current: Quote(time: time, USD: 120), history: history,
            now: Date(timeIntervalSince1970: time + 1800)))
        #expect(abs(result.percent - 20) < 1e-10)
        #expect(result.date == Date(timeIntervalSince1970: target))
    }

    @Test func comparisonToleranceAndNegativeChange() throws {
        let time = 1_700_000_000.0
        let now = Date(timeIntervalSince1970: time)
        let quote = Quote(time: time, USD: 80)
        let result = try #require(TelemetryMath.priceChange(current: quote,
            history: [.init(time: time - 86400 - 7200, USD: 100)], now: now))
        #expect(abs(result.percent + 20) < 1e-10)
        #expect(TelemetryMath.priceChange(current: quote,
            history: [.init(time: time - 86400 - 7201, USD: 100)], now: now) == nil)
        #expect(TelemetryMath.priceChange(current: quote,
            history: [.init(time: time - 86400 + 1, USD: 100)], now: now) == nil)
    }

    @Test func unavailablePriceComparisonsStayUnavailable() {
        let time = 1_700_000_000.0
        let now = Date(timeIntervalSince1970: time)
        let history = [PriceHistory.Point(time: time - 86400, USD: 100)]
        for quote in [Quote(time: time, USD: 0), Quote(time: time, USD: -1),
                      Quote(time: time - 3600, USD: 120), Quote(time: time + 61, USD: 120)] {
            #expect(TelemetryMath.priceChange(current: quote, history: history, now: now) == nil)
        }
        let quote = Quote(time: time, USD: 100)
        #expect(TelemetryMath.priceChange(current: quote, history: [], now: now) == nil)
        #expect(TelemetryMath.priceChange(current: quote,
            history: [.init(time: time - 86400, USD: 0)], now: now) == nil)
    }
}
