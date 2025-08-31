# memTV Configuration

## Bitcoin Node Configuration

To connect to your local Bitcoin node, you'll need to configure the following settings:

### Bitcoin.conf Settings
Add these lines to your `bitcoin.conf` file:

```
# Enable RPC server
server=1

# RPC settings
rpcuser=your_rpc_username
rpcpassword=your_rpc_password
rpcport=8332

# Allow connections from localhost
rpcallowip=127.0.0.1

# Bind to localhost only
rpcbind=127.0.0.1
```

### memTV App Configuration
The app looks for Bitcoin node at:
- URL: http://localhost:8332
- Default username: rpcuser
- Default password: rpcpassword

To change these settings, modify the BitcoinNodeService initialization in `ContentView.swift`:

```swift
@StateObject private var viewModel = MempoolViewModel(
    bitcoinService: BitcoinNodeService(
        nodeURL: "http://your.node.ip:8332",
        rpcUser: "your_rpc_username",
        rpcPassword: "your_rpc_password"
    )
)
```

### Network Requirements
- Your Bitcoin node must be fully synced
- Your Apple TV and Bitcoin node must be on the same local network
- Port 8332 must be accessible from your Apple TV
