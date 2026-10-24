# ⚡️ ClipVault

> **The ultra-slick, zero-bloat clipboard superpower for macOS.**  
> *From the minds of **IBM Bob & Daneyand**.*

[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-F05138.svg?style=flat&logo=swift&logoColor=white)](https://swift.org)
[![macOS 13+](https://img.shields.io/badge/macOS-13.0%2B-000000.svg?style=flat&logo=apple&logoColor=white)](https://apple.com/macos)
[![License: MIT](https://img.shields.io/badge/License-MIT-00F0FF.svg?style=flat)](LICENSE)
[![Universal Binary](https://img.shields.io/badge/Arch-Apple%20Silicon%20%7C%20Intel-34D399.svg?style=flat)]()
[![In-Memory Privacy](https://img.shields.io/badge/Privacy-100%25%20In--Memory-C084FC.svg?style=flat)]()

---

## 🚀 Never Lose a Snippet Again

Ever copied a genius snippet of code, a critical token, a file path, or a hilarious quote, only to accidentally overwrite it 3 seconds later with a stray `⌘C`?

**ClipVault** lives quietly in your macOS menu bar. Every time you cut or copy, ClipVault catches it, categorizes it, and locks it into an ultra-fast, searchable in-memory vault. 

Need it back? Click your tray icon, hit the snippet, and boom — it's loaded right back into the head of your clipboard, ready to paste into anything.

```
       [ ⌘C Anything ] ──▶ ⚡️ ClipVault ──▶ [ Search & Instant Restore ] ──▶ [ ⌘V Anywhere ]
```

---

## ✨ Features That Slap

### 🧠 Smart Data Type Intelligence
ClipVault doesn't just treat your clipboard as dumb bytes — it instantly recognizes and tags what you copied with high-visibility color-coded badges:

| Badge | Type | What It Detects |
|---|---|---|
| `TEXT` | **Plain Text** | URLs, strings, notes, tokens, code lines |
| `FILE` | **File & Paths** | `file://` URLs, Finder file copies, Unix paths (`/Users/...`, `~/...`) |
| `PICTURE` | **Pictures & Screenshots** | TIFF/PNG images, screenshots (`⌘⇧4`), image data URIs |
| `MARKDOWN` | **Markdown** | Headers (`#`), code fences (```` ``` ````), bold/italic (`**`), tables, checklists (`- [x]`) |
| `FORMATTED` | **Rich Formatted** | RTF, HTML markup, formatted text payloads from rich editors |

### ⚡️ Re-Organizing Vault Head
Whenever you select any past entry from the vault, ClipVault dynamically re-organizes your history:
1. Pushes the exact payload (text, rich formatting, image data, or file reference) back into `NSPasteboard.general`.
2. Promotes that entry to **Index 0 (The Head)** of your vault.
3. Automatically suppresses self-write loops so you don't get messy duplicates.

### 🔍 Lightning-Fast Substring & Type Search
Search in real-time as you type. Search by content, preview snippets, or filter directly by data type name (`"markdown"`, `"file"`, `"picture"`, `"formatted"`).

### ⌨️ Full Keyboard Navigation
- <kbd>↑</kbd> / <kbd>↓</kbd> — Move selection up and down the list
- <kbd>↵ Enter</kbd> — Copy & promote selected entry immediately
- <kbd>Esc</kbd> — Clear search filter or dismiss popover

### 🔒 100% In-Memory Privacy (Zero Disk Residue)
- No tracking. No telemetry. Zero network calls.
- Stored exclusively in volatile RAM while the app runs — quitting the app completely wipes the vault clean.

---

## 📦 Download & Quick Install

Pre-compiled **Universal Binaries** (Apple Silicon + Intel macOS 13.0+) are ready to go in the repository:

| Download | File | Description |
|---|---|---|
| 💿 **Apple Disk Image** | [`dist/ClipVault-1.0.0.dmg`](dist/ClipVault-1.0.0.dmg) | Drag-and-drop installer for `/Applications` |
| 🗜 **Portable ZIP** | [`dist/ClipVault-1.0.0-macos-universal.zip`](dist/ClipVault-1.0.0-macos-universal.zip) | Standalone application bundle + docs |
| 🚀 **Direct App** | [`dist/ClipVault.app`](dist/ClipVault.app) | Direct runnable bundle |

### Quick Launch Helper
```bash
./run.sh
```

---

## ⚙️ Specifications & Limits

| Spec | Value | Why? |
|---|---|---|
| **Max Capacity** | **200 items** | Strict FIFO ceiling keeps memory lean and browsing snappy. |
| **Max Character Cap** | **10,000 chars** | Protects against accidental gigabyte clipboard copies. Badged with `MAX 10k`. |
| **Polling Rate** | **500 ms** | DispatchSource timer polling `changeCount` with ~0% CPU overhead. |
| **Window Dimensions** | **380 × 520 px** | Compact, responsive dark Aqua popover. |

---

## 🛠 Building & Testing

### Prerequisites
- macOS 13.0+
- Xcode 15+ / Command Line Tools
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Build Distributables & Run Tests
```bash
# 1. Build release binaries, DMG, and ZIP with full test suite verification:
./package.sh

# 2. Or run tests directly with xcodebuild:
xcodebuild test -project ClipVault.xcodeproj -scheme ClipVault -destination 'platform=macOS'
```

---

## 🧪 Unit Test Suite

ClipVault features a **55-test automated test suite** covering:
- **`DataTypeDetectionTests` (20 tests)**: Exhaustive classification verification for Plain Text, File Paths/URLs, Data URIs, Markdown structures (code blocks, headers, checklists, links, bold/italics, blockquotes, tables), and HTML/RTF payloads.
- **`ClipItemTests` (12 tests)**: Character count, word count, 10,000 char capping, preview single-line formatting, UUID identity.
- **`AppStateTests` (23 tests)**: 200-item ceiling, deduplication, timestamp promotion, search filters, and type-based queries.

---

## 📜 Architecture

```
clipVault/
├── project.yml                          ← XcodeGen project blueprint
├── package.sh                           ← Automated universal distributable packager
├── build-dmg.sh                         ← Standalone DMG packaging script
├── run.sh                               ← Fast local test launcher
├── dist/                                ← Downloadable release artifacts
│   ├── ClipVault-1.0.0.dmg              ← Apple Disk Image
│   ├── ClipVault-1.0.0-macos-universal.zip
│   └── ClipVault.app
├── ClipVault/
│   ├── ClipVaultApp.swift               ← @main App entry
│   ├── Info.plist                       ← LSUIElement=true menu bar agent config
│   ├── App/
│   │   ├── AppDelegate.swift            ← NSApp lifecycle & monitor orchestration
│   │   └── AppState.swift               ← Central @Published reactive store (200 cap)
│   ├── IO/
│   │   └── ClipboardMonitor.swift       ← ChangeCount monitor & self-suppression engine
│   ├── Models/
│   │   └── ClipItem.swift               ← Immutable clip model & data type classifier
│   ├── UI/
│   │   ├── StatusBarController.swift    ← NSStatusItem, NSPopover & NSMenu manager
│   │   ├── StatusIconRenderer.swift     ← Vector badge & clipboard icon generator
│   │   ├── PopoverContentView.swift     ← SwiftUI popover root with keyboard handlers
│   │   ├── HeaderView.swift             ← Search bar & vault statistics
│   │   ├── ClipRowView.swift            ← Row view with color-coded type badges
│   │   └── EmptyStateView.swift         ← Empty vault & search result placeholder
│   └── Extensions/
│       └── ColorExtensions.swift        ← Cyberpunk neon theme palette
└── ClipVaultTests/
    └── ClipVaultTests.swift             ← 55 comprehensive unit tests
```

---

## 👥 Credits

*From the minds of **IBM Bob & Daneyand**.*  
Crafted with Swift, SwiftUI, AppKit, and pure passion for high-performance macOS tooling.

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
