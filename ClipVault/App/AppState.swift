import Foundation
import Combine

// MARK: - AppState

/// Central observable store for the clipboard vault.
/// All mutations happen on the main thread.
final class AppState: ObservableObject {

    // MARK: Singleton

    static let shared = AppState()

    // MARK: Published state

    /// Chronological vault — newest item at index 0, capped at `maxItems`.
    @Published private(set) var items: [ClipItem] = []

    /// Live search query entered by the user.
    @Published var searchQuery: String = ""

    // MARK: Constants

    static let maxItems = 200

    // MARK: Derived

    /// Items filtered by the current `searchQuery` (case- and diacritic-insensitive substring match).
    var filteredItems: [ClipItem] {
        let q = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return items }
        return items.filter {
            $0.text.localizedCaseInsensitiveContains(q) ||
            $0.preview.localizedCaseInsensitiveContains(q) ||
            $0.dataType.displayName.localizedCaseInsensitiveContains(q)
        }
    }

    /// Total number of items currently held in the vault.
    var totalCount: Int { items.count }

    // MARK: Init

    init() {}

    // MARK: Mutation API

    /// Add a new clipboard entry. Deduplicates by text — if a matching item
    /// already exists it is promoted to head and its timestamp/type refreshed instead
    /// of creating a duplicate. Trims vault to `maxItems` after insertion.
    func addItem(text: String, dataType: ClipDataType? = nil, rawData: Data? = nil) {
        precondition(Thread.isMainThread, "addItem must be called on the main thread")
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Deduplication: if the text already exists, promote and refresh rather than duplicate.
        if let existingIdx = items.firstIndex(where: { $0.text == trimmed }) {
            let existing = items[existingIdx]
            let resolvedType = dataType ?? existing.dataType
            let resolvedData = rawData ?? existing.rawData
            var updated = ClipItem(
                id: existing.id,
                text: trimmed,
                dataType: resolvedType,
                rawData: resolvedData,
                timestamp: Date()
            )
            items.remove(at: existingIdx)
            items.insert(updated, at: 0)
            return
        }

        let newItem = ClipItem(text: trimmed, dataType: dataType, rawData: rawData)
        items.insert(newItem, at: 0)

        // Enforce capacity ceiling
        if items.count > AppState.maxItems {
            items.removeLast(items.count - AppState.maxItems)
        }
    }

    /// Move the item with the given `id` to index 0 (most recent) and refresh its
    /// timestamp. Called by `ClipboardMonitor` / UI when an item is selected.
    @discardableResult
    func promoteItem(id: UUID) -> ClipItem? {
        precondition(Thread.isMainThread, "promoteItem(id:) must be called on the main thread")
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return nil }
        var item = items[idx]
        item.timestamp = Date()
        items.remove(at: idx)
        items.insert(item, at: 0)
        return item
    }

    /// Remove all items from the vault.
    func clearVault() {
        precondition(Thread.isMainThread, "clearVault() must be called on the main thread")
        items.removeAll()
    }
}
