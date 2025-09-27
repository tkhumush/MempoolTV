# 📺 MempoolTV

<div align="center">

**Real-time Bitcoin Network Monitoring for Apple TV**

*Transform your living room into a Bitcoin command center*

---

[![App Store](https://img.shields.io/badge/App_Store-Coming_Soon-blue?style=for-the-badge&logo=apple)](https://apps.apple.com)
[![Platform](https://img.shields.io/badge/Platform-Apple_TV-black?style=for-the-badge&logo=apple)](https://www.apple.com/apple-tv-4k/)
[![Swift](https://img.shields.io/badge/Swift-5.0-orange?style=for-the-badge&logo=swift)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

</div>

---

## 🚀 About MempoolTV

MempoolTV brings the Bitcoin network directly to your living room. Connect to your local Bitcoin node and watch the blockchain come alive with real-time block confirmations and mempool activity. Perfect for Bitcoin enthusiasts, developers, and anyone fascinated by the world's most revolutionary monetary network.

### ✨ Key Features

🟡 **Live Block Confirmations** - Watch the last 10 confirmed blocks as they're added to the blockchain

🟣 **Mempool Visualization** - Real-time display of unconfirmed transactions waiting for confirmation

⚡ **30-Second Updates** - Automatic refresh every 30 seconds to keep you up-to-date

🎯 **Apple TV Optimized** - Designed specifically for the big screen experience with focus navigation

🔒 **Local Node Connection** - Connects directly to your Bitcoin node via JSON-RPC for maximum privacy

🎨 **Clean Interface** - Minimalist design with clear visual distinction between block types

---

## 📱 Screenshots

*Screenshots coming soon - App Store submission in progress*

---

## 🎯 Perfect For

- **Bitcoin Node Operators** - Monitor your node's activity from the comfort of your couch
- **Bitcoin Developers** - Keep an eye on network activity while working
- **Bitcoin Enthusiasts** - Stay connected to the network 24/7
- **Educators** - Demonstrate Bitcoin's real-time operation to students and newcomers
- **HODLers** - Watch your digital gold's network in action

---

## 🔧 Technical Requirements

### Apple TV
- Apple TV 4K (1st generation or later)
- Apple TV HD (4th generation)
- tvOS 14.0 or later

### Bitcoin Node
- Fully synchronized Bitcoin Core node
- JSON-RPC interface enabled
- Local network access
- Required RPC methods: `getblockcount`, `getblockhash`, `getblock`, `getmempoolinfo`, `getrawmempool`

---

## ⚙️ Bitcoin Node Setup

### 1. Configure Your Bitcoin Node

Add these lines to your `bitcoin.conf` file:

```conf
# Enable RPC server
server=1
rpcuser=your_rpc_username
rpcpassword=your_secure_rpc_password
rpcbind=127.0.0.1
rpcallowip=192.168.1.0/24
```

### 2. Restart Bitcoin Core
```bash
bitcoind -daemon
```

### 3. Verify Connection
```bash
bitcoin-cli getblockcount
```

---

## 📲 Installation

### From App Store (Coming Soon)
1. Search for "MempoolTV" in the App Store on your Apple TV
2. Download and install
3. Configure your Bitcoin node connection
4. Start monitoring!

### For Developers
```bash
git clone https://github.com/tkhumush/MempoolTV.git
cd MempoolTV/memTV
open memTV.xcodeproj
```

---

## 🎮 How to Use

1. **Launch MempoolTV** on your Apple TV
2. **Configure Connection** - Enter your Bitcoin node details:
   - Node URL (default: `http://localhost:8332`)
   - RPC Username
   - RPC Password
3. **Watch the Magic** - See real-time blockchain activity:
   - **Yellow blocks** = Confirmed blocks
   - **Purple blocks** = Mempool transactions
4. **Enjoy** - Sit back and watch Bitcoin work in real-time

---

## 🏗️ Architecture

MempoolTV is built with modern iOS development practices:

- **SwiftUI** - Native Apple TV interface
- **Combine** - Reactive data flow
- **JSON-RPC** - Direct Bitcoin node communication
- **async/await** - Modern Swift concurrency

### Core Components
- `BitcoinNodeService` - Handles all Bitcoin node communication
- `MempoolViewModel` - Manages UI state with 30-second polling
- `ContentView` - Main interface with block visualization
- `BlockView` - Reusable block display component

---

## 🔐 Privacy & Security

- **No Data Collection** - MempoolTV doesn't collect or transmit any personal data
- **Local Connection Only** - Connects directly to your Bitcoin node
- **Open Source** - Full source code available for review
- **No Third Parties** - No external services or analytics

---

## 🌟 Why MempoolTV?

In a world of complex trading interfaces and overwhelming data dashboards, MempoolTV offers something different: **simplicity**.

Watch Bitcoin's heartbeat from your living room. See the network's pulse as blocks are mined and transactions flow through the mempool. It's Bitcoin monitoring, reimagined for the big screen.

---

## 🛠️ Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
1. Clone the repository
2. Open `memTV.xcodeproj` in Xcode 14+
3. Select Apple TV as target device
4. Build and run

---

## 📞 Support

Need help? Have questions?

- 📧 Email: Email comming soon, report issues on github.
- 🐛 Issues: [GitHub Issues](https://github.com/tkhumush/MempoolTV/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/tkhumush/MempoolTV/discussions)

---

## 🔒 Privacy Policy

MempoolTV respects your privacy. We do not collect any personal data. See our [Privacy Policy](PRIVACY_POLICY.md) for full details.

## 📄 License

MempoolTV is released under the MIT License. See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- **Bitcoin Core** - The foundation that makes this possible
- **Apple** - For creating the incredible Apple TV platform
- **Swift Community** - For the amazing development tools

---

<div align="center">

**Made with ❤️ for the Bitcoin community**

[⭐ Star us on GitHub](https://github.com/tkhumush/MempoolTV) | [📱 Download from App Store (Soon)](https://apps.apple.com)

*"Don't trust, verify"* - Watch Bitcoin work in real-time

</div>
