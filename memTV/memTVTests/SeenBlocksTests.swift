import Foundation
import Testing
@testable import memTV

struct SeenBlocksTests {
    @Test func firstSightAndReplay() {
        var seen = SeenBlocks()
        #expect(seen.observe("a"))
        #expect(!seen.observe("a"))
        #expect(seen.observe("b"))
        #expect(seen.hashes == ["a", "b"])
    }

    @Test func persistsAcrossRestart() throws {
        let suite = "SeenBlocksTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var seen = SeenBlocks(defaults: defaults)
        #expect(seen.observe("a"))
        #expect(seen.observe("b"))
        seen.persist(to: defaults)
        let restartedDefaults = try #require(UserDefaults(suiteName: suite))
        var restarted = SeenBlocks(defaults: restartedDefaults)
        #expect(restarted.hashes == ["a", "b"])
        #expect(!restarted.observe("a"))
        #expect(!restarted.observe("b"))
        #expect(restarted.observe("c"))
    }

    @Test func boundedHistoryDeduplicatesWithoutRefreshingReplays() {
        var seen = SeenBlocks(hashes: ["a", "a", "b", "c"], capacity: 2)
        #expect(seen.hashes == ["b", "c"])
        #expect(!seen.observe("b"))
        #expect(seen.observe("d"))
        #expect(seen.hashes == ["c", "d"])
        var minimum = SeenBlocks(capacity: 0)
        minimum.observe("a"); minimum.observe("b")
        #expect(minimum.hashes == ["b"])
    }

    @Test @MainActor func rapidArrivalsUpdateWallWithoutQueuingCelebrations() throws {
        let model = ObservatoryModel()
        var seen = SeenBlocks()
        let first = try Fixtures.block("a")
        let second = try Fixtures.block("b", height: 840_001)
        for block in [first, second] where seen.observe(block.id) {
            model.consume(.block(block, celebrate: true))
        }
        #expect(model.celebration?.id == "a")
        #expect(model.blocks.value?.map(\.id) == ["b", "a"])
        model.dismissCelebration()
        #expect(model.celebration == nil)
        for block in [first, second] where seen.observe(block.id) {
            model.consume(.block(block, celebrate: true))
        }
        #expect(model.celebration == nil)
        let third = try Fixtures.block("c", height: 840_002)
        if seen.observe(third.id) { model.consume(.block(third, celebrate: true)) }
        #expect(model.celebration?.id == "c")
    }

    @Test @MainActor func snapshotAndDossierAreSilent() throws {
        let model = ObservatoryModel()
        let block = try Fixtures.block()
        model.consume(.snapshot([block]))
        #expect(model.celebration == nil)
        model.dossier = block
        model.consume(.block(try Fixtures.block("b", height: 840_001), celebrate: true))
        #expect(model.celebration == nil)
        #expect(model.blocks.value?.first?.id == "b")
        model.dossier = nil
        #expect(model.celebration == nil)
        model.consume(.block(try Fixtures.block("c", height: 840_002), celebrate: false))
        #expect(model.celebration == nil)
    }
}
