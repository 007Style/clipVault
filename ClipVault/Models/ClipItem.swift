import Foundation

// MARK: - ClipDataType

/// Classification of the clipboard payload data.
enum ClipDataType: String, CaseIterable, Codable, Equatable {
    case text      = "Text"
    case file      = "File"
    case picture   = "Picture"
    case markdown  = "Markdown"
    case formatted = "Formatted"

    /// Short label displayed on the badge.
    var displayName: String {
        switch self {
        case .text:      return "Text"
        case .file:      return "File"
        case .picture:   return "Picture"
        case .markdown:  return "Markdown"
        case .formatted: return "Formatted"
        }
    }

    /// SF Symbol icon name associated with this data type.
    var iconName: String {
        switch self {
        case .text:      return "doc.text"
        case .file:      return "doc"
        case .picture:   return "photo"
        case .markdown:  return "text.word.spacing"
        case .formatted: return "textformat"
        }
    }
}

// MARK: - ClipItem

/// A single clipboard history entry stored in the vault.
struct ClipItem: Identifiable, Equatable {

    // MARK: Constants

    /// Maximum number of characters stored per item.
    static let maxCharacters = 10_000

    /// Maximum number of characters shown in the preview line.
    static let previewLength = 120

    // MARK: Properties

    let id: UUID
    /// Full text content, capped at `maxCharacters`.
    let text: String
    /// Classification of the clipboard payload.
    let dataType: ClipDataType
    /// Single-line truncated preview for display in the list row.
    let preview: String
    /// Number of characters in the (possibly truncated) `text`.
    let charCount: Int
    /// Approximate word count of the (possibly truncated) `text`.
    let wordCount: Int
    /// When this item was captured or last promoted.
    var timestamp: Date
    /// `true` when the original clipboard content was longer than `maxCharacters`.
    let isTruncated: Bool
    /// Optional raw payload data (e.g. TIFF image bytes, RTF data) for full fidelity restoration.
    let rawData: Data?

    // MARK: Init

    /// Creates a `ClipItem` from raw clipboard text and data type, applying the 10k-char cap.
    init(
        id: UUID = UUID(),
        text rawText: String,
        dataType: ClipDataType? = nil,
        rawData: Data? = nil,
        timestamp: Date = Date()
    ) {
        let capped: String
        let truncated: Bool
        if rawText.count > ClipItem.maxCharacters {
            capped    = String(rawText.prefix(ClipItem.maxCharacters))
            truncated = true
        } else {
            capped    = rawText
            truncated = false
        }

        let effectiveType = dataType ?? Self.detectType(text: capped)

        self.id          = id
        self.text        = capped
        self.dataType    = effectiveType
        self.rawData     = rawData
        self.isTruncated = truncated
        self.charCount   = capped.count
        self.wordCount   = capped.components(separatedBy: .whitespacesAndNewlines)
                                  .filter { !$0.isEmpty }.count
        self.timestamp   = timestamp

        // Build a compact single-line preview
        let oneLine = capped
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
        self.preview = oneLine.count > ClipItem.previewLength
            ? String(oneLine.prefix(ClipItem.previewLength)) + "…"
            : oneLine
    }

    // MARK: Type Detection

    /// Detects the `ClipDataType` based on text heuristics and optional pasteboard metadata flags.
    static func detectType(
        text: String,
        hasRichFormatting: Bool = false,
        isImage: Bool = false,
        isFile: Bool = false
    ) -> ClipDataType {
        if isImage {
            return .picture
        }
        if isFile {
            return .file
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for File paths or file URLs
        if isFileString(trimmed) {
            return .file
        }

        // Check for Image data URIs
        if trimmed.hasPrefix("data:image/") {
            return .picture
        }

        // Check for Rich / Formatted text (RTF, HTML markup)
        if hasRichFormatting || isHTMLString(trimmed) {
            return .formatted
        }

        // Check for Markdown syntax
        if isMarkdownString(trimmed) {
            return .markdown
        }

        return .text
    }

    // MARK: - Private Detection Helpers

    /// Checks if a string represents a file path or file URL.
    private static func isFileString(_ str: String) -> Bool {
        if str.hasPrefix("file://") {
            return true
        }
        // Single path starting with / or ~
        let lines = str.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !lines.isEmpty else { return false }

        // All lines are valid paths
        let allPaths = lines.allSatisfy { line in
            let path = line.trimmingCharacters(in: .whitespaces)
            return (path.hasPrefix("/") || path.hasPrefix("~/")) && !path.contains("\n")
        }

        if allPaths {
            // Check if any path exists or looks like a typical unix/macOS path with components
            for line in lines {
                let path = (line as NSString).expandingTildeInPath
                if FileManager.default.fileExists(atPath: path) {
                    return true
                }
                // Path with at least 2 components like /Users/foo or /System/...
                let comps = path.split(separator: "/")
                if comps.count >= 2 {
                    return true
                }
            }
        }
        return false
    }

    /// Checks if a string contains HTML document structure or common HTML tags.
    private static func isHTMLString(_ str: String) -> Bool {
        let lower = str.lowercased()
        if lower.contains("<!doctype html") || lower.contains("<html") || lower.contains("<body") {
            return true
        }
        let htmlTagPattern = #"<([a-z]+[1-6]?)([^>]*)>(.*?)</\1>"#
        if let regex = try? NSRegularExpression(pattern: htmlTagPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let range = NSRange(location: 0, length: (str as NSString).length)
            if regex.firstMatch(in: str, options: [], range: range) != nil {
                return true
            }
        }
        return false
    }

    /// Checks if a string contains distinct Markdown formatting syntax.
    private static func isMarkdownString(_ str: String) -> Bool {
        // Multi-line code block: ``` ... ```
        if str.contains("```") {
            return true
        }

        // Markdown headings: ^# Header or ^## Subheader
        let lines = str.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.range(of: #"^#{1,6}\s+\S+"#, options: .regularExpression) != nil {
                return true
            }
            // Markdown list with checkboxes: - [ ] or - [x]
            if trimmed.range(of: #"^[-*+]\s+\[[ xX]\]"#, options: .regularExpression) != nil {
                return true
            }
            // Markdown blockquotes: > quote
            if trimmed.range(of: #"^>\s+\S+"#, options: .regularExpression) != nil {
                return true
            }
        }

        // Markdown links: [text](http...) or images: ![alt](http...)
        if str.range(of: #"!?\[[^\]\n]+\]\([^\)\n]+\)"#, options: .regularExpression) != nil {
            return true
        }

        // Markdown bold / italic: **bold** or *italic* or __bold__
        if str.range(of: #"(\*\*|__)[^\*\n_]+(\*\*|__)"#, options: .regularExpression) != nil {
            return true
        }

        // Markdown tables: | col1 | col2 |
        let tableLines = lines.filter { $0.contains("|") }
        if tableLines.count >= 2 {
            let hasHeaderDivider = tableLines.contains { $0.range(of: #"\|\s*[-:]+[-| :]*\|"#, options: .regularExpression) != nil }
            if hasHeaderDivider {
                return true
            }
        }

        return false
    }

    // MARK: Equatable

    static func == (lhs: ClipItem, rhs: ClipItem) -> Bool {
        lhs.id == rhs.id
    }
}
