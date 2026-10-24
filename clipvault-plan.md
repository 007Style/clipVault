# clipVault Plan

## Top-Level Overview
`clipVault` is a dedicated macOS menu bar (tray) utility that monitors the system clipboard (`NSPasteboard`) and maintains an in-memory chronological history (up to 200 items, capped at 10,000 characters per entry). It provides a responsive SwiftUI popover with real-time fuzzy/substring search, rich item metadata (character count, word count, timestamp, copy badge), and one-click item restoration. When any past entry is clicked, its text is loaded back into the active clipboard and promoted to the head of the vault.

---

## Sub-Tasks

### Sub-Task 1: Project Scaffolding and Build Configuration
- **Intent**: Set up the project structure in `clipVault/` including `project.yml` for XcodeGen, `Package.swift` (or SPM support), `Info.plist` with `LSUIElement=true` for menu bar agent mode, and distribution build script.
- **Expected Outcomes**: A buildable macOS application target (`ClipVault.app`) that runs as a menu bar agent without a Dock icon.
- **Todo List**:
  - [x] Create `clipVault/project.yml` with macOS 13+ deployment target, AppKit and SwiftUI dependencies.
  - [x] Create `clipVault/ClipVault/Info.plist` with `LSUIElement = true` and bundle metadata.
  - [x] Create `clipVault/build-dmg.sh` for automated ad-hoc packaging and DMG creation.
  - [x] Verify clean generation of Xcode project using `xcodegen generate` or verify CLI build.
- **Relevant Context**: Mirrors `portWatch/project.yml` and `diskPulse/project.yml`.
- **Status**: [x] completed

---

### Sub-Task 2: Clipboard Monitor Engine and Data Models
- **Intent**: Implement the core data model (`ClipItem`) and the background clipboard polling engine (`ClipboardMonitor`) that tracks `NSPasteboard.general.changeCount`.
- **Expected Outcomes**: Reliable detection of new clipboard text, truncation of entries exceeding 10,000 characters, deduplication/reordering of repeated content, and strict enforcement of the 200-item vault capacity.
- **Todo List**:
  - [x] Define `ClipItem` model with unique ID, text content, truncated preview string, character/word count, timestamp, and metadata.
  - [x] Create `AppState` observable class managing the `@Published` list of items, search query, active selection, and total entry count.
  - [x] Implement `ClipboardMonitor` timer loop sampling `changeCount` on `NSPasteboard.general`.
  - [x] Implement internal suppression mechanism so that restoring an item from clipVault does not register as a redundant duplicate entry.
  - [x] Implement item promotion logic: when an item is selected, move it to index 0 and write text to `NSPasteboard`.
- **Relevant Context**: `AppState.swift` and `PortMonitor.swift` patterns from `portWatch`.
- **Status**: [x] completed

---

### Sub-Task 3: Status Bar Controller and Menu Bar Integration
- **Intent**: Create the AppKit menu bar controller (`StatusBarController`) that installs the status item, renders the dynamic tray icon, and handles left-click popover and right-click context menu.
- **Expected Outcomes**: Clicking the tray icon opens the transient SwiftUI popover; right-clicking displays a context menu with options to Clear Vault, Toggle Launch at Login, About, and Quit.
- **Todo List**:
  - [x] Create `StatusIconRenderer` to draw an attractive clipboard/vault icon with dynamic entry count badge.
  - [x] Implement `StatusBarController` managing `NSStatusItem`, `NSPopover`, and right-click `NSMenu`.
  - [x] Wire up `AppDelegate` and `ClipVaultApp` lifecycle to initialize monitoring on launch.
- **Relevant Context**: `portWatch/PortWatch/UI/StatusBarController.swift`.
- **Status**: [x] completed

---

### Sub-Task 4: SwiftUI Popover GUI and Search Interface
- **Intent**: Build the GUI popover view hierarchy with modern dark-mode styling, search bar with keyboard navigation, entry list, and empty/search states.
- **Expected Outcomes**: An intuitive, fast UI displaying filtered entries in real time, with highlighted search matches, preview snippets, one-click copy/promote action, and keyboard shortcuts (Enter to copy top result, Esc to dismiss).
- **Todo List**:
  - [x] Define visual palette (`ColorExtensions.swift`) with dark theme styling (neon cyan/amber accents).
  - [x] Build `HeaderView` with vault badge, entry count, search field, and quick clear button.
  - [x] Build `ClipRowView` displaying truncated preview, timestamp relative format, character & word badges, and copy button.
  - [x] Build `EmptyStateView` for when vault is empty or no search results match.
  - [x] Implement keyboard navigation (arrow keys to navigate, Return to copy, Escape to close popover).
- **Relevant Context**: `portWatch/PortWatch/UI/PopoverContentView.swift`.
- **Status**: [x] completed

---

### Sub-Task 5: End-to-End Testing, Validation, and Packaging
- **Intent**: Build, test, and package the application into a standalone DMG and standalone app bundle, verifying clipboard operations and limits.
- **Expected Outcomes**: A verified Release build of `ClipVault.app` and distribution DMG in `clipVault/dist/`.
- **Todo List**:
  - [x] Compile and build project in Release mode using `xcodebuild`.
  - [x] Run automated tests or CLI verification of clipboard capture, 200-item ceiling, 10,000 character limit, and promotion logic.
  - [x] Run `build-dmg.sh` to produce `ClipVault-1.0.dmg`.
  - [x] Update documentation and `README.md` in `clipVault/`.
- **Relevant Context**: `portWatch/build-dmg.sh`.
- **Status**: [x] completed
