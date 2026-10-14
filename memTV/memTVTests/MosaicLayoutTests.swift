import Foundation
import SwiftUI
import Testing
@testable import memTV

struct MosaicLayoutTests {
    @Test func conservesAreaAndVsizeIncludingTinyGroups() throws {
        let transactions = try (0..<100).map { index in
            try Fixtures.transaction("tx-\(index)", vsize: index == 0 ? 1000.25 : 0.25,
                                     rate: Double(index % 5) * 5)
        }
        let width = 400.0, height = 200.0
        let cells = MosaicLayout.make(transactions, width: width, height: height)
        let total = transactions.reduce(0) { $0 + $1.vsize }
        #expect(cells.contains { $0.count > 1 })
        #expect(cells.reduce(0) { $0 + $1.count } == transactions.count)
        #expect(abs(cells.reduce(0) { $0 + $1.vsize } - total) < 1e-8)
        #expect(abs(cells.reduce(0) { $0 + $1.rect.width * $1.rect.height } - width * height) < 1e-8)
        #expect(Set(cells.map(\.id)).count == cells.count)
        for cell in cells {
            // Convert pixel area back to allocated virtual bytes.
            let allocated = cell.rect.width * cell.rect.height / (width * height) * total
            #expect(abs(allocated - cell.vsize) < 1e-8)
            #expect(cell.rect.minX >= -1e-8 && cell.rect.maxX <= width + 1e-8)
            #expect(cell.rect.minY >= -1e-8 && cell.rect.maxY <= height + 1e-8)
        }
        for i in cells.indices {
            for j in cells.indices where j > i {
                let intersection = cells[i].rect.intersection(cells[j].rect)
                #expect(intersection.isNull || intersection.width * intersection.height < 1e-8)
            }
        }
    }

    @Test func effectiveFeeBandsRunHotLeftWithMatchingPalette() throws {
        let rates = [1.99, 2, 4.99, 5, 9.99, 10, 19.99, 20, 100]
        let expected = [0, 1, 1, 2, 2, 3, 3, 4, 4]
        let transactions = try rates.enumerated().map {
            try Fixtures.transaction("tx-\($0.offset)", vsize: 200, rate: $0.element)
        }
        let cells = MosaicLayout.make(transactions, width: 1000, height: 500)
        for (index, band) in expected.enumerated() {
            #expect(TelemetryMath.band(rates[index]) == band)
            #expect(cells.first { $0.id == "tx-\(index)" }?.band == band)
        }
        for hot in cells {
            for cold in cells where hot.band > cold.band {
                #expect(hot.rect.maxX <= cold.rect.minX + 1e-8)
            }
        }
        #expect(ObservatoryStyle.bands.count == 5)
        #expect(ObservatoryStyle.bands[0] == Color(hex: 0x6867B5))
        #expect(ObservatoryStyle.bands[4] == Color(hex: 0xFFBD65))
        #expect(ObservatoryStyle.bandLabels == ["<2", "2–5", "5–10", "10–20", "≥20"])
        let reversed = MosaicLayout.make(Array(transactions.reversed()), width: 1000, height: 500)
        #expect(cells.map(\.id) == reversed.map(\.id))
        #expect(cells.map(\.rect) == reversed.map(\.rect))
    }

    @Test func emptyAndZeroSizedLayoutsAreEmpty() throws {
        let tx = try Fixtures.transaction("a", vsize: 123.25, rate: 1)
        #expect(MosaicLayout.make([], width: 100, height: 100).isEmpty)
        #expect(MosaicLayout.make([tx], width: 0, height: 100).isEmpty)
        #expect(MosaicLayout.make([tx], width: 100, height: -1).isEmpty)
        let cells = MosaicLayout.make([tx], width: 200, height: 100)
        #expect(cells.count == 1)
        #expect(cells.first?.rect == CGRect(x: 0, y: 0, width: 200, height: 100))
    }
}
