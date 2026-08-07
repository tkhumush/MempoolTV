# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
memTV is an Apple TV app built in SwiftUI that connects to a local Bitcoin node via JSON-RPC and to mempool.space REST APIs to display confirmed blocks, mempool transactions, network statistics, and Nostr developer profiles in real-time.

## Build and Development Commands

### Building the App
```bash
# Open Xcode project
open memTV/memTV.xcodeproj

# Build for Apple TV
# Use Xcode's build system - select Apple TV as target device
```

### Testing
```bash
# Run tests in Xcode
# Product -> Test (⌘U)
# Tests are located in memTVTests/ and memTVUITests/
```

## Architecture Overview

### Core Components
- **NetworkClient** (`Services/NetworkClient.swift`): Injectable network abstraction used by all services
- **BitcoinNodeService** (`Services/BitcoinNodeService.swift`): Bitcoin Core JSON-RPC client using Codable models
- **MempoolSpaceService** (`Services/MempoolSpaceService.swift`): Mempool.space REST client using Codable models
- **MinerDetector** (`Services/MinerDetector.swift`): Expanded coinbase-tag miner detection
- **MempoolViewModel** (`ViewModels/MempoolViewModel.swift`): Main UI state with cancellable async polling
- **NetworkStatsViewModel** (`ViewModels/NetworkStatsViewModel.swift`): Shared state for network statistics widgets
- **TopTransactionsViewModel** (`ViewModels/TopTransactionsViewModel.swift`): Real per-transaction data loader
- **LoadableState** (`ViewModels/LoadableState.swift`): Unified loading/error/data enum
- **ContentView** (`ContentView.swift`): Primary UI with black/yellow confirmed blocks and purple mempool blocks
- **BlockView** (`Components/BlockView.swift`): Reusable block visualization component
- **ThemeManager** (`ViewModels/ThemeManager.swift`): Shared theme state via environmentObject

### Data Flow
1. `memTVApp` creates a single `ThemeManager` shared via `environmentObject`
2. `ContentView` creates `MempoolViewModel` and `NetworkStatsViewModel`, injects them into child views
3. `MempoolViewModel` uses a single cancellable `Task` loop with 60-second polling
4. Services return plain data; `@Published` state lives in ViewModels
5. Error handling is per-section (`LoadableState`) instead of a single global error

### Configuration
Bitcoin node credentials are no longer hardcoded. The app reads them from `RPCCredentialStore` (Keychain). Use the static helper to configure:
```swift
try? RPCCredentialStore.shared.save(config: BitcoinRPCConfig(
    nodeURL: "http://localhost:8332",
    rpcUser: "rpcuser",
    rpcPassword: "rpcpassword"
))
```
If no credentials are saved, `ContentView` shows an onboarding placeholder (future UI).

### Key Files Structure
```
memTV/memTV/
├── memTVApp.swift                     # App entry point
├── ContentView.swift                  # Main UI view
├── Constants.swift                    # Polling interval, dimensions, Bitcoin constants
├── Extensions.swift                   # Array[safe:] helper
├── Styles.swift                       # Apple TV button style
├── Services/
│   ├── NetworkClient.swift            # NetworkClient protocol + URLSessionNetworkClient
│   ├── BitcoinNodeService.swift       # JSON-RPC client (Codable)
│   ├── MempoolSpaceService.swift      # Mempool.space REST client (Codable)
│   ├── MinerDetector.swift            # Expanded pool detection
│   └── RPCCredentialStore.swift       # Keychain-backed RPC credentials
├── ViewModels/
│   ├── MempoolViewModel.swift         # Main timeline state + polling
│   ├── NetworkStatsViewModel.swift     # Stats widget state + refresh
│   ├── TopTransactionsViewModel.swift # Real transaction loader
│   ├── LoadableState.swift            # Loading/error/data enum
│   └── ThemeManager.swift             # Shared theme
├── Components/
│   ├── BlockView.swift                # Block visualization
│   ├── BlockTimelineView.swift        # Horizontal timeline
│   ├── BlockDetailView.swift          # Detail container
│   ├── ConfirmedBlockDetailView.swift # Confirmed block stats
│   ├── MempoolBlockDetailView.swift   # Mempool block stats + top txs
│   ├── TopTransactionsChart.swift     # Real top transaction bar chart
│   ├── FeeDistributionChart.swift     # Fee distribution area chart
│   ├── MiningPoolsChartView.swift     # Horizontal bar chart
│   ├── HashrateChartView.swift        # Hashrate area chart
│   ├── DifficultyAdjustmentWidget.swift
│   ├── FeesPriorityWidget.swift
│   └── BitcoinPriceView.swift
├── Models/
│   ├── BitcoinModels.swift            # Codable Block, MempoolTransaction, Transaction, etc.
│   └── NostrModels.swift              # Nostr event/profile/message models
└── Views/
    ├── NetworkStatisticsView.swift
    └── DevelopersView.swift
```

## Development Notes

### Bitcoin Node Requirements
- Fully synced Bitcoin node with RPC enabled
- Default connection: http://localhost:8332 with basic auth
- Required RPC methods: getblockcount, getblockhash, getblock, getmempoolinfo, getrawmempool
- Credentials must be provided via `RPCCredentialStore`

### UI Design Constraints
- Apple TV-specific layout with focus navigation
- 3-column grid layout for blocks
- Fixed color scheme: black background, yellow confirmed blocks, purple mempool
- Text-based graphics using colored rectangles with block numbers

### Error Handling
- Per-section `LoadableState.failed(String)` surfaced in the relevant widget/section
- Network errors mapped to typed `NetworkError` and propagated as user-facing strings
- Service errors no longer swallowed or defaulted to synthetic data

### Performance Considerations
- 60-second polling interval
- Single cancellable `Task` polling loop in `MempoolViewModel`
- Network statistics refresh every 5 minutes
- Async/await + `withTaskGroup` for parallel fee fetches
- Stable SwiftUI identity using block hash and mempool position
