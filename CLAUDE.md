# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
memTV is an Apple TV app built in SwiftUI that connects to a local Bitcoin node via JSON-RPC to display confirmed blocks and mempool transactions in real-time.

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
- **BitcoinNodeService** (`Services/BitcoinNodeService.swift`): Handles all Bitcoin node communication via JSON-RPC
- **MempoolViewModel** (`ViewModels/MempoolViewModel.swift`): Main UI state management with 30-second polling
- **ContentView** (`ContentView.swift`): Primary UI with black background, yellow confirmed blocks, purple mempool blocks
- **BlockView** (`Components/BlockView.swift`): Reusable block visualization component

### Data Flow
1. `MempoolViewModel` polls `BitcoinNodeService` every 30 seconds
2. Service fetches last 10 confirmed blocks and up to 20 mempool transactions
3. UI updates automatically via `@Published` properties
4. Error handling displays connection issues to user

### Configuration
Bitcoin node connection configured in `MempoolViewModel` initialization:
```swift
BitcoinNodeService(
    nodeURL: "http://localhost:8332",
    rpcUser: "rpcuser", 
    rpcPassword: "rpcpassword"
)
```

### Key Files Structure
```
memTV/memTV/
├── memTVApp.swift           # App entry point
├── ContentView.swift        # Main UI view
├── Services/
│   └── BitcoinNodeService.swift  # Bitcoin RPC client
├── ViewModels/
│   └── MempoolViewModel.swift    # UI state management
├── Components/
│   └── BlockView.swift      # Block visualization
└── Models/
    └── BitcoinModels.swift  # Data models (Block, MempoolInfo)
```

## Development Notes

### Bitcoin Node Requirements
- Fully synced Bitcoin node with RPC enabled
- Default connection: http://localhost:8332 with basic auth
- Required RPC methods: getblockcount, getblockhash, getblock, getmempoolinfo, getrawmempool

### UI Design Constraints
- Apple TV-specific layout with focus navigation
- 3-column grid layout for blocks
- Fixed color scheme: black background, yellow confirmed blocks, purple mempool
- Text-based graphics using colored rectangles with block numbers

### Error Handling
- Network errors display in red text in UI
- Service errors logged to console
- Graceful fallback for missing data

### Performance Considerations  
- Limited to 10 confirmed blocks and 20 mempool transactions for display
- 30-second polling interval to avoid overwhelming node
- Async/await pattern for network requests