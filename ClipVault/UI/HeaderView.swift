import SwiftUI

// MARK: - HeaderView

struct HeaderView: View {
    @Binding var searchQuery: String
    let totalCount: Int
    let filteredCount: Int
    let onClearVault: () -> Void

    @State private var showingClearConfirmation = false

    var body: some View {
        VStack(spacing: 10) {
            // Top Title & Action Bar
            HStack(spacing: 8) {
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.cvNeonCyan)
                    .shadow(color: Color.cvNeonCyan.opacity(0.8), radius: 4)

                Text("CLIPVAULT")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(2.5)
                    .foregroundColor(.cvNeonCyan)
                    .shadow(color: Color.cvNeonCyan.opacity(0.5), radius: 5)

                Spacer()

                // Entry count badge
                HStack(spacing: 4) {
                    Text(searchQuery.isEmpty ? "\(totalCount)" : "\(filteredCount)/\(totalCount)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.cvNeonCyan)

                    Text(totalCount == 1 ? "CLIP" : "CLIPS")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(.cvDimWhite)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.cvSurfaceHover)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.cvBorder, lineWidth: 1)
                )

                // Clear vault button
                if totalCount > 0 {
                    Button(action: { showingClearConfirmation = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.cvDimWhite)
                            .padding(5)
                            .background(Color.cvSurfaceHover)
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.cvBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Clear all clipboard history")
                    .confirmationDialog(
                        "Clear all clipboard history?",
                        isPresented: $showingClearConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Clear Vault", role: .destructive) {
                            onClearVault()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will remove all \(totalCount) items from your history.")
                    }
                }
            }

            // Search Bar Input
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(searchQuery.isEmpty ? .cvDimWhite : .cvNeonCyan)

                TextField("Search history... (↑↓ navigate, ↵ copy)", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(.white)

                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.cvDimWhite)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.cvBackground)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        searchQuery.isEmpty ? Color.cvBorder : Color.cvNeonCyan.opacity(0.6),
                        lineWidth: 1
                    )
            )
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Color.cvSurface)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.cvBorder),
            alignment: .bottom
        )
    }
}
