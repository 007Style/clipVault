import AppKit
import SwiftUI
import Combine

// MARK: - StatusBarController

/// Owns the `NSStatusItem`, the `NSPopover` panel, and the right-click `NSMenu`.
///
/// - **Left-click**  → opens/closes the SwiftUI popover.
/// - **Right-click** → shows the context menu (Clear Vault, About, Quit).
///
/// The menu is *never* permanently assigned to `statusItem.menu` — that would
/// intercept all clicks and prevent the popover from opening.  Instead every
/// click is routed through `handleClick(_:)` which selects the correct action.
final class StatusBarController {

    // MARK: Private properties

    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var contextMenu: NSMenu
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    init() {
        statusItem   = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover      = NSPopover()
        contextMenu  = NSMenu()

        statusItem.button?.action = #selector(handleClick(_:))
        statusItem.button?.target = self
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        buildContextMenu()
        buildPopover()
        subscribeToState()
    }

    // MARK: - Context menu

    private func buildContextMenu() {
        // Non-interactive header
        let header = NSMenuItem(title: "ClipVault", action: nil, keyEquivalent: "")
        header.isEnabled = false
        contextMenu.addItem(header)
        contextMenu.addItem(.separator())

        // Clear vault
        let clearItem = NSMenuItem(
            title: "Clear Vault",
            action: #selector(clearVault),
            keyEquivalent: ""
        )
        clearItem.target = self
        contextMenu.addItem(clearItem)

        contextMenu.addItem(.separator())

        // About
        let aboutItem = NSMenuItem(
            title: "About ClipVault",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        contextMenu.addItem(aboutItem)

        contextMenu.addItem(.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit ClipVault",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        contextMenu.addItem(quitItem)
    }

    // MARK: - Popover

    private func buildPopover() {
        popover.contentSize  = NSSize(width: 380, height: 520)
        popover.behavior     = .transient
        popover.animates     = true
        popover.appearance   = NSAppearance(named: .darkAqua)

        let contentView = PopoverContentView(onDismiss: { [weak self] in
            guard let self = self else { return }
            if self.popover.isShown {
                self.popover.performClose(nil)
            }
        })
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.wantsLayer = true
        popover.contentViewController = hostingController
    }

    // MARK: - Click handling

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            // Temporarily assign the menu so the system can display it under the button.
            statusItem.menu = contextMenu
            statusItem.button?.performClick(nil)
            // Immediately clear it so left-clicks still reach this handler.
            DispatchQueue.main.async { [weak self] in
                self?.statusItem.menu = nil
            }
        } else {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                guard let button = statusItem.button else { return }
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }

    // MARK: - Menu actions

    @objc private func clearVault() {
        AppState.shared.clearVault()
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText     = "ClipVault"
        alert.informativeText = "Clipboard history manager for macOS.\nVersion 1.0"
        alert.alertStyle      = .informational
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    // MARK: - State subscription

    private func subscribeToState() {
        AppState.shared.$items
            .map(\.count)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.updateIcon(count: count)
            }
            .store(in: &cancellables)
    }

    private func updateIcon(count: Int) {
        let image = StatusIconRenderer.render(count: count)
        statusItem.button?.image        = image
        statusItem.button?.imageScaling = .scaleNone
    }
}

