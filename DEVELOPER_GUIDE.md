# memTV Developer Guide

## Project Overview
memTV is a simple Apple TV app that connects to a local Bitcoin node and displays:
- Last 10 confirmed blocks (in yellow)
- Mempool transactions (in purple)
- Text-based graphics for blocks
- Black background

## Project Structure
```
memTV/
├── BITCOIN_RPC.md          # Bitcoin RPC documentation
├── CONFIGURATION.md        # Configuration instructions
├── DEVELOPER_GUIDE.md      # This file
├── IMPLEMENTATION_SUMMARY.md # Implementation details
├── PROJECT_CONTEXT.md      # Project planning context
├── README.md               # Project overview
├── memTV/                  # Main Xcode project
│   ├── memTVApp.swift      # App entry point
│   ├── ContentView.swift   # Main view implementation
│   ├── Services/           # Network services
│   │   └── BitcoinNodeService.swift
│   ├── ViewModels/         # View models
│   │   └── MempoolViewModel.swift
│   ├── Components/         # UI components
│   │   └── BlockView.swift
│   └── Assets.xcassets/    # Images and colors
```

## Getting Started

### Prerequisites
1. Xcode 14 or later
2. A fully synced Bitcoin node
3. Apple TV 4K or Apple TV HD (or simulator)

### Setting Up Bitcoin Node
1. Ensure your Bitcoin node is running with RPC enabled
2. Configure `bitcoin.conf` with:
   ```
   server=1
   rpcuser=your_rpc_username
   rpcpassword=your_rpc_password
   rpcport=8332
   rpcallowip=127.0.0.1
   rpcbind=127.0.0.1
   ```
3. Restart your Bitcoin node

### Building the Project
1. Open `memTV.xcodeproj` in Xcode
2. Select your Apple TV as the target device
3. Build and run the project

### Configuring Node Connection
Modify the BitcoinNodeService initialization in `ContentView.swift`:
```swift
@StateObject private var viewModel = MempoolViewModel(
    bitcoinService: BitcoinNodeService(
        nodeURL: "http://your.node.ip:8332",
        rpcUser: "your_rpc_username",
        rpcPassword: "your_rpc_password"
    )
)
```

## Codebase Overview

### BitcoinNodeService
Handles all communication with the Bitcoin node using JSON-RPC:
- `getBlockCount()`: Returns current block height
- `getBlockHash(height:)`: Returns hash for a given block height
- `getBlock(hash:)`: Returns block details
- `getMempoolInfo()`: Returns mempool statistics
- `getRawMempool()`: Returns list of mempool transactions

### MempoolViewModel
Manages the application state:
- Fetches data from BitcoinNodeService
- Updates UI with confirmed blocks and mempool transactions
- Implements automatic polling every 30 seconds
- Handles loading states and errors

### ContentView
Main UI implementation:
- Black background
- Displays title and sections for confirmed/mempool blocks
- Uses BlockView components for visualization
- Responsive grid layout for Apple TV

### BlockView
Simple component to visualize blocks:
- Rectangle with block number
- Yellow for confirmed blocks
- Purple for mempool transactions

## Testing
1. Run in Apple TV simulator
2. Connect to actual Bitcoin node
3. Verify block display updates every 30 seconds

## Customization

### Colors
Modify colors in `BlockView.swift`:
```swift
.fill(isConfirmed ? Color.yellow : Color.purple)
```

### Layout
Adjust grid in `ContentView.swift`:
```swift
LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3)
```

### Polling Interval
Change interval in `MempoolViewModel.swift`:
```swift
timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true)
```

## Troubleshooting

### Connection Issues
1. Verify Bitcoin node is running
2. Check RPC credentials in `bitcoin.conf`
3. Ensure port 8332 is accessible
4. Confirm same network between Apple TV and Bitcoin node

### Display Issues
1. Check Xcode console for errors
2. Verify sufficient mempool transactions exist
3. Confirm block data is being received

### Performance
1. Reduce number of blocks displayed
2. Increase polling interval
3. Optimize BlockView rendering

## Future Enhancements

### UI Improvements
1. Add block timestamps
2. Show transaction counts per block
3. Implement focus-based navigation
4. Add settings screen

### Feature Additions
1. Transaction detail views
2. Block explorer functionality
3. Network statistics display
4. Customizable refresh intervals

## Contributing
1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create pull request

## License
MIT License - see LICENSE file for details.
