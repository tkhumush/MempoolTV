# memTV - Bitcoin Mempool Viewer for Apple TV

## Project Overview
A simple Apple TV app that connects to a local Bitcoin node and displays:
- Last 10 confirmed blocks (yellow)
- Mempool blocks (purple)
- Text-based graphics for blocks
- Black background

## Current Project Structure
```
memTV/
├── memTV.xcodeproj/
├── memTV/
│   ├── Assets.xcassets/
│   ├── memTVApp.swift
│   └── ContentView.swift
├── memTVTests/
└── memTVUITests/
```

## Implementation Plan

### Phase 1: Bitcoin Node Connection
1. Create a Bitcoin node service to connect to local node
2. Implement JSON-RPC calls for:
   - getblockcount (to get latest block height)
   - getblockhash (to get hash for specific block height)
   - getblock (to get block details)
   - getmempoolinfo (to get mempool stats)
   - getrawmempool (to get mempool transactions)

### Phase 2: Data Models
1. Create Block model for confirmed blocks
2. Create MempoolTransaction model
3. Create service response models

### Phase 3: UI Components
1. Customize ContentView for Apple TV
2. Create BlockView component for text-based graphics
3. Implement color scheme (black background, yellow confirmed, purple mempool)
4. Layout blocks in a grid view suitable for TV

### Phase 4: Data Integration
1. Connect UI to Bitcoin node service
2. Implement polling for updates
3. Display last 10 confirmed blocks
4. Display mempool transactions

## Color Scheme
- Background: Black
- Confirmed blocks: Yellow
- Mempool blocks: Purple

## Technical Considerations
- Apple TV remote navigation
- Focus-based interactions
- Network communication with Bitcoin node
- Data refresh/polling mechanism
