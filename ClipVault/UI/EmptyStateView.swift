import SwiftUI

// MARK: - EmptyStateView

struct EmptyStateView: View {
    let searchQuery: String
    let onClearSearch: () -> Void

    private var isSearching: Bool {
        !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: isSearching ? "text.magnifyingglass" : "doc.on.clipboard")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(isSearching ? .cvNeonAmber.opacity(0.8) : .cvNeonCyan.opacity(0.8))
                .shadow(
                    color: (isSearching ? Color.cvNeonAmber : Color.cvNeonCyan).opacity(0.4),
                    radius: 8
                )
                .padding(.bottom, 4)

            Text(isSearching ? "No Matches Found" : "Vault is Empty")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            Text(
                isSearching
                    ? "No clipboard history matches \"\(searchQuery)\""
                    : "Copy text anywhere on your Mac to automatically start recording history."
            )
            .font(.system(size: 11))
            .foregroundColor(.cvDimWhite)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            if isSearching {
                Button(action: onClearSearch) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 11))
                        Text("Clear Search")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.cvNeonCyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.cvSurfaceHover)
                    .cornerRadius(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.cvBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            } else {
                HStack(spacing: 12) {
                    Label("Max 200 items", systemImage: "tray.full")
                    Text("•")
                    Label("10k chars / item", systemImage: "character.cursor.ibeam")
                }
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.cvTextMuted)
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
