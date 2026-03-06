# MempoolTV Refactoring Plan

## Context

MempoolTV is an Apple TV app (~2,700 lines across 28 Swift files) that displays Bitcoin confirmed blocks and mempool transactions from the mempool.space API. The app was originally built with Claude Sonnet 4.5 and has grown organically, accumulating mixed concerns, duplicated logic, dead code, hardcoded values, and oversized files. This refactoring aims to improve maintainability, separation of concerns, and code quality — one component at a time, keeping the app functional after each phase.

---

## Phase 1: Clean Up Dead Code & Hardcoded Values

**Objective:** Remove unused code and extract scattered magic numbers into a central constants file, giving us a clean foundation before structural changes.

**What changes:**
- Remove dead `fetchDetailedBlockInfo()` stub in `MempoolViewModel.swift:168-175`
- Remove unused `onTap` parameter from `BlockView` (always passed as `{ }` in ContentView)
- Remove deprecated/unused `highPriority`, `mediumPriority`, `lowPriority` fields from `FeeInfo` struct in `BlockView.swift`
- Remove `feeRecommendations` property from `MempoolViewModel` (loaded but never displayed in UI) and its `loadFeeRecommendations()` call
- Remove debug `print()` statements from `BlockDetailView.swift:276-312` and `MempoolSpaceService.swift:100,133,217-223`
- Extract magic numbers into a new `Constants.swift` file:
  - Polling interval (60s), block display count (8), block duration estimate (10 min)
  - UI dimensions: block width (160), block height (120), icon size (180), triangle size (40x20)
  - Bitcoin constants: halving interval (210,000), base subsidy (50.0 BTC)

**Files modified:**
- `memTV/memTV/ViewModels/MempoolViewModel.swift`
- `memTV/memTV/Components/BlockView.swift`
- `memTV/memTV/Components/BlockDetailView.swift`
- `memTV/memTV/Services/MempoolSpaceService.swift`
- `memTV/memTV/ContentView.swift`
- **New:** `memTV/memTV/Constants.swift`

---

## Phase 2: Consolidate & Clean Up Models

**Objective:** Unify data models into a single, well-organized models file with clear separation between API formats, and eliminate duplicated subsidy calculation logic.

**What changes:**
- Move `MempoolTransaction` from `MempoolSpaceService.swift:228-270` into `BitcoinModels.swift` (models shouldn't live in service files)
- Move `SelectedBlockType` and `PersistentSelection` enums from `MempoolViewModel.swift:12-22` into `BitcoinModels.swift` (they're data types, not view model logic)
- Move `FeeInfo` and `FeeRange` structs from `BlockView.swift` and `BlockDetailView.swift` into `BitcoinModels.swift`
- Replace the duplicated subsidy calculation in `Block.init(from:)` (line 75-77) and `BitcoinNodeService.calculateSubsidy()` (line 152-156) with a single shared utility using the constants from Phase 1
- Split `Block.init(from dictionary:)` into two factory methods: `Block.fromMempoolSpace(_:)` and `Block.fromBitcoinRPC(_:)` for clarity

**Files modified:**
- `memTV/memTV/Models/BitcoinModels.swift`
- `memTV/memTV/Services/MempoolSpaceService.swift`
- `memTV/memTV/Services/BitcoinNodeService.swift`
- `memTV/memTV/ViewModels/MempoolViewModel.swift`
- `memTV/memTV/Components/BlockView.swift`
- `memTV/memTV/Components/BlockDetailView.swift`

---

## Phase 3: Split BlockDetailView into Focused Components

**Objective:** Break the largest file (507 lines) into smaller, single-purpose view components, and move data transformation logic out of the view layer.

**What changes:**
- Extract `ConfirmedBlockDetailView` — handles the confirmed block table layout (current lines 42-155)
- Extract `MempoolBlockDetailView` — handles mempool block detail with charts (current lines 159-211)
- Move `generateFeeDistributionData()` from BlockDetailView into a helper/extension on `MempoolTransaction` (it's data transformation, not view logic)
- Keep `BlockDetailView` as a thin router that switches on `SelectedBlockType` and delegates to the correct sub-view
- Keep existing supporting views (`StatusBadge`, `DetailCard`, `MempoolDataTable`, `MempoolDataRow`, `BlockDetailCell`) in their own file or grouped logically

**Files modified:**
- `memTV/memTV/Components/BlockDetailView.swift` (simplified to ~50 lines)
- **New:** `memTV/memTV/Components/ConfirmedBlockDetailView.swift`
- **New:** `memTV/memTV/Components/MempoolBlockDetailView.swift`
- `memTV/memTV/Models/BitcoinModels.swift` (add fee distribution extension)

---

## Phase 4: Extract Timeline View from ContentView

**Objective:** Reduce ContentView's complexity by extracting the horizontal block timeline (the most complex UI section) into its own component, and clean up selection logic.

**What changes:**
- Extract the horizontal ScrollView timeline (ContentView lines 90-150) into a new `BlockTimelineView` component
- Move the two `isBlockSelected()` helpers into the ViewModel or simplify them — they can be a single method on `SelectedBlockType` (e.g., `selectedBlock.matches(block:)` / `selectedBlock.matches(txid:)`)
- Move mempool transaction display logic (sorting, prefix, displayNumber calculation) out of the view and into the ViewModel
- Extract the `CardButtonStyle` into a separate `Styles.swift` file
- ContentView becomes a clean composition: Header + TimelineView + DetailView

**Files modified:**
- `memTV/memTV/ContentView.swift` (simplified to ~80 lines)
- **New:** `memTV/memTV/Components/BlockTimelineView.swift`
- **New:** `memTV/memTV/Styles.swift`
- `memTV/memTV/ViewModels/MempoolViewModel.swift`

---

## Phase 5: Refactor MempoolViewModel — Separation of Concerns

**Objective:** Simplify the ViewModel by extracting polling management and fixing the timer/concurrency issues.

**What changes:**
- Fix `deinit` timer cleanup: invalidate timer synchronously instead of wrapping in Task (line 209-212)
- Add a guard against concurrent data loads (if `isLoading`, skip the timer-triggered refresh)
- Simplify selection persistence: collapse `PersistentSelection` into `SelectedBlockType` — they track the same thing redundantly
- Remove `lastKnownBlockHeight` tracking (only logs, never acts on the information)
- Remove `logAPIUsage()` call and the corresponding method in `MempoolSpaceService` (console-only debugging noise)

**Files modified:**
- `memTV/memTV/ViewModels/MempoolViewModel.swift`
- `memTV/memTV/Services/MempoolSpaceService.swift`

---

## Phase 6: Refactor BitcoinNodeService — Generic RPC & Thread Safety

**Objective:** Eliminate duplicated RPC boilerplate and fix thread-safety issues.

**What changes:**
- Create a generic `performRPC<T>(method:params:transform:)` method that handles the shared pattern (build request dict, call sendRequest, increment ID, validate result)
- Replace all 6 public RPC methods to use the generic method (reduces ~120 lines of duplication)
- Replace mutable `requestID` counter with UUID-based request IDs (thread-safe, no shared mutable state)
- Remove unnecessary `ObservableObject` conformance (no `@Published` properties)
- Move the `Array.safe` subscript extension to a shared extensions file
- Fix port default from 8334 to 8332 to match documentation

**Files modified:**
- `memTV/memTV/Services/BitcoinNodeService.swift`
- **New:** `memTV/memTV/Extensions.swift` (for Array safe subscript)

---

## Phase 7: Improve MempoolSpaceService — Thread Safety & Codable

**Objective:** Make the API service thread-safe and modernize JSON parsing.

**What changes:**
- Convert `MempoolSpaceService` from `class` to `actor` for thread-safe mutable state (`requestCount`, `retryDelay`, `blockFeeCache`)
- Add cache eviction (cap cache size or clear on memory warning)
- Make `baseURL` configurable via initializer parameter (enables future testing)
- Consider adopting `Codable` for JSON parsing instead of manual `JSONSerialization` dictionary access (reduces type-casting boilerplate and makes parsing errors explicit)

**Files modified:**
- `memTV/memTV/Services/MempoolSpaceService.swift`
- `memTV/memTV/ViewModels/MempoolViewModel.swift` (update to work with actor)

---

## Verification Plan

After each phase:
1. Open the project in Xcode (`open memTV/memTV.xcodeproj`)
2. Build for Apple TV target — ensure zero compile errors
3. Run the app in simulator — verify blocks and mempool data load and display correctly
4. Verify block selection works (tap a block, see details)
5. Verify navigation to Stats and Developers views still works
6. Run existing tests (`Cmd+U`) — ensure they still pass (even though they're stubs, they shouldn't break)

**Key behaviors to validate across all phases:**
- Confirmed blocks display in yellow with height numbers and average fees
- Mempool blocks display in purple with median fees and estimated times
- Block detail view shows correct information for both confirmed and mempool blocks
- Fee distribution chart renders for mempool blocks
- 60-second polling continues to refresh data
- Bitcoin price displays in header
