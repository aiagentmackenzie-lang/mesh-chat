# Mesh Chat 📡🔒

A privacy-first, peer-to-peer messaging app that works without internet or cellular service. Built on Bluetooth Low Energy mesh networking with end-to-end encryption.

![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![Platform](https://img.shields.io/badge/Platform-iOS-lightgrey.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

---

## ✨ Features

### 🔐 End-to-End Encryption
- **P-256 Key Exchange** - Elliptic curve cryptography for secure pairing
- **AES-256-GCM** - Industry-standard symmetric encryption for messages
- **Zero Trust Architecture** - No central servers, no data collection
- **Self-Destructing Messages** - Configurable TTL (1h, 24h, 7d, infinite)

### 📡 Bluetooth Mesh Networking
- **Offline-First** - Works without internet or cellular
- **Multi-Hop Relay** - Messages hop through nodes (up to 7 hops)
- **Range Estimation** - Signal strength-based distance calculation
- **Automatic Discovery** - Scans for nearby Darknet nodes

### 👤 Anonymous Identities
- **Node Aliases** - Pseudonymous identifiers (e.g., GHOST-X9, WRAITH-B2)
- **Color Coding** - Visual identity system (Green, Blue, Red, Purple, Orange, White)
- **Cryptographic Keys** - Each node generates P-256 key pairs
- **Pairing System** - Secure 4-digit code verification

### 💬 Messaging Features
| Feature | Description |
|---------|-------------|
| **Channels** | Public mesh, private 1:1, and group chats |
| **TTL Control** | Time-to-live for message self-destruction |
| **Delivery Receipts** | Real-time status: queued → sent → delivered |
| **Relay Tracking** | See how many hops your message took |
| **Password Protection** | Optional channel passwords |
| **System Messages** | Join/leave notifications |

### 🎯 Tactical Interface
- **Radar View** - Discover and visualize nearby nodes
- **Signal Strength Meters** - 10-bar RSSI visualization
- **Distance Estimation** - <5m, 5-15m, 15-30m, 30m+
- **OPS Panel** - Military-style operations settings
- **Emergency Wipe** - Triple-tap data destruction

---

## 🏗️ Architecture

```
DarknetMeshChat/
├── DarknetMeshChatApp.swift           # App entry point
├── ContentView.swift                   # Navigation coordinator
├── Models/
│   ├── NodeIdentity.swift              # User identity + key pairs
│   ├── MeshNode.swift                  # Discovered peer nodes
│   ├── ChatMessage.swift               # Message model with TTL
│   ├── Channel.swift                   # Chat channels (public/group/private)
│   └── AppSettings.swift               # User preferences
├── Services/
│   ├── BLEMeshService.swift            # Bluetooth mesh networking
│   ├── CryptoService.swift             # Encryption/decryption
│   └── StorageService.swift            # Secure local storage
├── ViewModels/
│   └── MeshViewModel.swift             # App state management
├── Views/
│   ├── SplashView.swift                # App launch
│   ├── IdentitySetupView.swift         # Initial node configuration
│   ├── RadarView.swift                 # Node discovery and scanning
│   ├── ChannelsView.swift              # Channel list
│   ├── ChatTerminalView.swift          # Chat interface
│   ├── OpsView.swift                   # Settings and operations
│   └── PermissionsView.swift           # BLE permission handling
└── Utilities/
    └── DarknetTheme.swift              # Dark cyberpunk UI theme
```

---

## 🔐 Security Features

| Feature | Implementation |
|---------|----------------|
| **Key Generation** | P-256 Elliptic Curve (CryptoKit) |
| **Message Encryption** | AES-256-GCM |
| **Channel Keys** | 256-bit symmetric keys |
| **Pairing** | 4-digit code + key exchange |
| **Storage** | iOS Keychain for private keys |
| **No Metadata** | No phone numbers, emails, or accounts |

### Key Rotation
- Manual key rotation from OPS Panel
- Keeps alias, generates new key pair
- Requires re-pairing with existing contacts

### Emergency Features
- **NUKE ALL CHATS** - Delete all message history
- **RESET IDENTITY** - Regenerate entire identity
- **EMERGENCY WIPE** - Triple-tap destruction

---

## 🚀 Getting Started

### Prerequisites
- **macOS 14.0+**
- **Xcode 15.0+**
- **iOS 17.0+** device (simulator doesn't support BLE)
- **Bluetooth enabled** on your device

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/aiagentmackenzie-lang/darknet-mesh-chat.git
   cd darknet-mesh-chat
   ```

2. **Open in Xcode**
   ```bash
   open DarknetMeshChat.xcodeproj
   ```

3. **Build to Physical Device**
   - Darknet requires real hardware (BLE unavailable in Simulator)
   - Connect your iPhone
   - Select your device as target
   - Press `Cmd+R` to run

---

## 📱 Screens

### Identity Setup
- Set your node alias (max 12 chars)
- Choose your color identity
- Generates P-256 key pair automatically

### Radar View
- Discover nearby Darknet nodes
- Shows signal strength bars
- Distance estimation (meters)
- Pairing requests with 4-digit codes
- Create new channels

### Channels
- **#void** - Default public channel
- **#mesh** - Mesh network channel
- **#null** - Null channel
- Custom channels (public/group/private)
- Unread message badges

### Chat Terminal
- Monospace hacker aesthetic
- Real-time delivery status indicators
- Self-destruct timers visible
- Quick attachments (GPS, passphrase, sys info)
- Typing indicators
- Message relay hop count

### OPS Panel
- Identity management (alias, keys, color)
- Encryption protocol selection
- Mesh config (hop limit, scan interval)
- Message defaults (TTL, receipts)
- Appearance settings (accent colors)
- Danger Zone (nuke, reset, wipe)

---

## 🎨 Design System

### Cyberpunk Aesthetic
- **Pure black background** (`#000000`)
- **Monospace typography** throughout
- **Bracket-style UI** `[> SEND]` `[< BACK]`
- **Terminal-inspired** interface
- **Accent colors**: Neon cyan green (`#00FF88`)

### Color Palette
| Element | Color | Hex |
|---------|-------|-----|
| Background | Pure Black | `#000000` |
| Accent | Neon Cyan | `#00FF88` |
| Text Primary | White | `#FFFFFF` |
| Text Secondary | Gray | `#8E8E93` |
| Border | Dark Gray | `#1C1C1E` |
| Danger | Red | `#FF453A` |
| Warning | Orange | `#FFAA00` |

### Node Colors
- **Green** - `#00FF88` (default)
- **Blue** - `#00AAFF`
- **Red** - `#FF0033`
- **Orange** - `#FF8800`
- **Purple** - `#AA00FF`
- **White** - `#FFFFFF`

---

## 🛠️ Technical Stack

| Component | Technology |
|-----------|------------|
| Framework | SwiftUI |
| Language | Swift 5.9+ |
| Encryption | CryptoKit (P-256, AES-GCM) |
| Networking | CoreBluetooth (BLE) |
| Architecture | MVVM |
| Persistence | iOS Keychain + UserDefaults |

---

## 📡 Mesh Networking

### How It Works
1. **Each node** advertises BLE services
2. **Scanning** discovers nearby nodes within ~10m
3. **Relay** - Messages hop through intermediate nodes
4. **Range extension** - Up to 7 hops (~70m theoretical max)

### Message Types
| Type | Description |
|------|-------------|
| `msg` | Standard encrypted message |
| `typing` | Typing indicator broadcast |
| `join` | Node joined notification |
| `leave` | Node disconnected |
| `ping` | Heartbeat/keepalive |

### Simulated Nodes
Demo mode generates simulated nodes for testing:
- Ghost aliases: GHOST-X9, WRAITH-B2, SPECTER-7F
- Random signal strengths
- Random pairing states

---

## 🔒 Privacy

### What's Stored Locally
- ✅ Private key (Keychain)
- ✅ Public key
- ✅ Message history
- ✅ Channel memberships
- ✅ Node aliases

### What's Never Stored
- ❌ No server logs
- ❌ No phone numbers
- ❌ No email addresses
- ❌ No location history (except last message GPS)

### No Internet Required
- Pure P2P via Bluetooth
- No cloud services
- No registration
- No accounts

---

## ⚠️ Limitations

### Bluetooth Range
- **Direct**: ~10 meters (30 feet)
- **Via Mesh**: Up to ~70 meters with 7 hops
- **Requires**: Devices must remain in range

### Device Requirements
- **Only iOS**: iPhone with BLE 5.0+
- **Physical device**: Simulator not supported
- **Bluetooth**: Must be enabled

### Battery Impact
- Continuous BLE scanning uses battery
- Background scanning configurable in OPS

---

## 🐛 Troubleshooting

### "No nodes detected"
- Ensure Bluetooth is enabled
- Check Location permissions (BLE requires this on iOS)
- Other users need Darknet running nearby
- Range is limited to ~10m per hop

### "Messages not delivering"
- Check recipient is in range
- Verify pairing status
- Look at relay hop count
- Try shorter hop limit

### Encryption Issues
- Rotate keys if needed (OPS Panel)
- Re-pair with contacts
- Check channel shared key

---

## 🤝 Contact & Support

Designed by **Raphael Main** and **Agent Mackenzie**.

For questions, feedback, or collaboration:

**📧 Email:** aiagent.mackenzie@gmail.com

---

## 🙏 Acknowledgments

- End-to-end encryption via [CryptoKit](https://developer.apple.com/documentation/cryptokit)
- Bluetooth LE via [CoreBluetooth](https://developer.apple.com/documentation/corebluetooth)
- Icons by [SF Symbols](https://developer.apple.com/sf-symbols/)
- Monospace fonts: San Francisco Mono
- Inspired by mesh networking and privacy research

---

## 📝 License

MIT License - feel free to use for personal or research purposes.

---

<p align="center">
  <strong>DARKNET</strong> — 
  <em>Zero trust. Zero servers. Pure mesh.</em> 📡
</p>
