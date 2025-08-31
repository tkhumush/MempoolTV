# memTV Project Session Context

## Project Goal
Create a simple Bitcoin mempool viewer app for Apple TV that:
- Connects to local Bitcoin node over network
- Displays last 10 confirmed blocks (yellow) and mempool blocks (purple)
- Uses text-based graphics on black background
- Keeps it simple - no fancy graphics needed

## Current Implementation Status

### ✅ What's Already Built
- **Complete Architecture**: Services layer, ViewModels, UI Components, Data Models
- **Bitcoin Integration**: Full JSON-RPC client with all necessary methods (getblockcount, getblockhash, getblock, getmempoolinfo, getrawmempool)
- **UI Design**: Black background, yellow confirmed blocks, purple mempool blocks
- **Data Flow**: 30-second polling, async/await, proper error handling
- **Apple TV Setup**: Xcode project configured for tvOS

### 🔍 Current Issues (Why App Doesn't Run)
1. **Model Duplication**: Block and MempoolInfo defined in both BitcoinNodeService.swift and BitcoinModels.swift
2. **Build Configuration**: Need to verify Apple TV target settings
3. **Network Configuration**: Default localhost connection may need adjustment

## Key Files Overview

### Core Structure
```
memTV/memTV/
├── memTVApp.swift              # App entry point
├── ContentView.swift           # Main UI (3-column grid, black bg)
├── Services/
│   └── BitcoinNodeService.swift    # Bitcoin RPC client + duplicate models
├── ViewModels/
│   └── MempoolViewModel.swift      # State management, 30s polling
├── Models/
│   └── BitcoinModels.swift         # Data models (duplicates)
└── Components/
    └── BlockView.swift             # Block visualization component
```

### Network Configuration
- **Default**: http://localhost:8332 with rpcuser/rpcpassword
- **Configurable**: Via BitcoinNodeService init parameters
- **Required**: Bitcoin node with RPC enabled on local network

## Next Development Session Priorities

### 🚨 Phase 1: Fix Build Issues
1. **Resolve Model Conflicts**: Remove duplicate Block/MempoolInfo definitions
2. **Build & Test**: Get app running in Apple TV simulator
3. **Debug Connection**: Test Bitcoin node connectivity

### ⚙️ Phase 2: Configuration  
1. **Bitcoin Node Setup**: Configure your actual node connection details
2. **Network Testing**: Verify RPC calls work with your node
3. **Error Handling**: Improve feedback for connection issues

### 📺 Phase 3: Apple TV Polish
1. **Focus Navigation**: Implement proper TV remote navigation
2. **Layout Testing**: Optimize for TV screen sizes
3. **Performance**: Test with real mempool data

## Development Commands

```bash
# Build for Apple TV
cd memTV && xcodebuild -scheme memTV -destination 'platform=tvOS Simulator,name=Apple TV' build

# Open in Xcode
open memTV.xcodeproj
```

## Bitcoin Node Requirements
- Fully synced Bitcoin node
- RPC enabled with credentials
- Accessible over local network
- Required RPC methods available

## Success Criteria
- [ ] App builds and runs on Apple TV simulator
- [ ] Connects to Bitcoin node successfully  
- [ ] Displays 10 recent confirmed blocks (yellow)
- [ ] Shows mempool transactions (purple)
- [ ] Updates every 30 seconds
- [ ] Clean text-based interface on black background

## Notes for Next Session
- The architecture is solid - main focus should be fixing build issues
- Most of the hard work is already done
- UI already matches your requirements exactly
- Just needs debugging and configuration