import SwiftUI

// MARK: - ClipRowView

struct ClipRowView: View {
    let item: ClipItem
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false
    @State private var showCopiedFeedback = false

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    var body: some View {
        Button(action: handleSelect) {
            VStack(alignment: .leading, spacing: 6) {
                // Header line: Data Type Badge + Timestamp
                HStack(spacing: 6) {
                    dataTypeBadge(for: item.dataType)

                    Spacer()

                    // Timestamp
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 8))
                            .foregroundColor(.cvDimWhite)

                        Text(formattedTimestamp(item.timestamp))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.cvDimWhite)
                    }
                }

                // Text preview
                Text(item.preview)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Metadata bottom row: Word count, Char count, Truncation, Copy status
                HStack(spacing: 6) {
                    // Word count badge
                    Text("\(item.wordCount)w")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.cvDimWhite)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.cvBackground.opacity(0.8))
                        .cornerRadius(3)

                    // Char count badge
                    Text("\(item.charCount)c")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(.cvNeonAmber)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.cvBackground.opacity(0.8))
                        .cornerRadius(3)

                    // Truncation badge if item hit 10k character limit
                    if item.isTruncated {
                        Text("MAX 10k")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.cvNeonRed)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.cvNeonRed.opacity(0.15))
                            .cornerRadius(3)
                    }

                    Spacer()

                    // Copy action button / indicator
                    if showCopiedFeedback {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                            Text("COPIED")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.cvNeonGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cvNeonGreen.opacity(0.15))
                        .cornerRadius(3)
                    } else {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10))
                            .foregroundColor(isHovered || isSelected ? .cvNeonCyan : .cvDimWhite)
                            .padding(3)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                isSelected ? Color.cvSurfaceSelected :
                (isHovered ? Color.cvSurfaceHover : Color.cvSurface)
            )
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isSelected ? Color.cvNeonCyan.opacity(0.8) :
                        (isHovered ? Color.cvNeonCyan.opacity(0.3) : Color.cvBorder),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    // MARK: - Data Type Badge View

    @ViewBuilder
    private func dataTypeBadge(for type: ClipDataType) -> some View {
        let badgeColor: Color = {
            switch type {
            case .text:      return .cvBadgeText
            case .file:      return .cvBadgeFile
            case .picture:   return .cvBadgePicture
            case .markdown:  return .cvBadgeMarkdown
            case .formatted: return .cvBadgeFormatted
            }
        }()

        HStack(spacing: 3) {
            Image(systemName: type.iconName)
                .font(.system(size: 8, weight: .semibold))
            Text(type.displayName.uppercased())
                .font(.system(size: 8, weight: .bold, design: .monospaced))
        }
        .foregroundColor(badgeColor)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(badgeColor.opacity(0.16))
        .cornerRadius(3)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(badgeColor.opacity(0.35), lineWidth: 0.8)
        )
    }

    private func handleSelect() {
        showCopiedFeedback = true
        onSelect()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showCopiedFeedback = false
        }
    }

    private func formattedTimestamp(_ date: Date) -> String {
        let elapsed = Date().timeIntervalSince(date)
        if elapsed < 10 {
            return "just now"
        }
        return Self.relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}
