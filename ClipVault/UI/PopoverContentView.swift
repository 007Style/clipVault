import SwiftUI
import AppKit

// MARK: - PopoverContentView

struct PopoverContentView: View {
    @ObservedObject private var state = AppState.shared
    var onDismiss: (() -> Void)? = nil

    @State private var selectedIndex: Int = 0
    @State private var keyMonitor: Any?

    var body: some View {
        VStack(spacing: 0) {
            // Header: Branding, Search Bar, Badges & Clear Vault
            HeaderView(
                searchQuery: $state.searchQuery,
                totalCount: state.totalCount,
                filteredCount: state.filteredItems.count,
                onClearVault: {
                    state.clearVault()
                    selectedIndex = 0
                }
            )

            // Content Area: List of Clips or Empty State
            if state.filteredItems.isEmpty {
                EmptyStateView(
                    searchQuery: state.searchQuery,
                    onClearSearch: {
                        state.searchQuery = ""
                        selectedIndex = 0
                    }
                )
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(Array(state.filteredItems.enumerated()), id: \.element.id) { index, item in
                                ClipRowView(
                                    item: item,
                                    isSelected: index == selectedIndex,
                                    onSelect: {
                                        copyAndPromote(item: item)
                                    }
                                )
                                .id(item.id)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                    .onChange(of: selectedIndex) { newIndex in
                        let items = state.filteredItems
                        if newIndex >= 0 && newIndex < items.count {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                proxy.scrollTo(items[newIndex].id, anchor: .center)
                            }
                        }
                    }
                }
            }

            // Footer Shortcut Bar
            footerBar
        }
        .frame(width: 380, height: 520)
        .background(Color.cvBackground)
        .onChange(of: state.searchQuery) { _ in
            selectedIndex = 0
        }
        .onAppear {
            setupKeyMonitor()
        }
        .onDisappear {
            removeKeyMonitor()
        }
    }

    // MARK: - Footer Bar

    private var footerBar: some View {
        HStack(spacing: 12) {
            shortcutHint(key: "↑↓", label: "Navigate")
            shortcutHint(key: "↵", label: "Copy")
            shortcutHint(key: "esc", label: "Close")

            Spacer()

            if state.totalCount > 0 {
                Text("\(state.totalCount) / \(AppState.maxItems) max")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.cvTextMuted)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.cvSurface)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.cvBorder),
            alignment: .top
        )
    }

    private func shortcutHint(key: String, label: String) -> some View {
        HStack(spacing: 3) {
            Text(key)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.cvNeonCyan)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.cvBackground)
                .cornerRadius(3)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.cvBorder, lineWidth: 1)
                )

            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.cvDimWhite)
        }
    }

    // MARK: - Copy and Promote

    private func copyAndPromote(item: ClipItem) {
        ClipboardMonitor.shared.writeToPasteboard(item: item)
        state.promoteItem(id: item.id)
        selectedIndex = 0
    }

    // MARK: - Keyboard Monitoring

    private func setupKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 126: // Up arrow
                let count = state.filteredItems.count
                if count > 0 {
                    selectedIndex = max(0, selectedIndex - 1)
                    return nil
                }
            case 125: // Down arrow
                let count = state.filteredItems.count
                if count > 0 {
                    selectedIndex = min(count - 1, selectedIndex + 1)
                    return nil
                }
            case 36: // Enter / Return
                let items = state.filteredItems
                if selectedIndex >= 0 && selectedIndex < items.count {
                    copyAndPromote(item: items[selectedIndex])
                    return nil
                }
            case 53: // Escape
                if !state.searchQuery.isEmpty {
                    state.searchQuery = ""
                    return nil
                } else {
                    onDismiss?()
                    return nil
                }
            default:
                break
            }
            return event
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
}
