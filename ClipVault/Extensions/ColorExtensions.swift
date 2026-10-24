import SwiftUI
import AppKit

// MARK: - Color Palette

extension Color {
    /// Deep dark background for the popover root
    static let cvBackground     = Color(red: 0.08, green: 0.08, blue: 0.12)
    /// Elevated card / section surface
    static let cvSurface        = Color(red: 0.12, green: 0.12, blue: 0.18)
    /// Hover state for clip rows and interactive elements
    static let cvSurfaceHover   = Color(red: 0.16, green: 0.16, blue: 0.24)
    /// Selection state for keyboard-highlighted clip row
    static let cvSurfaceSelected = Color(red: 0.20, green: 0.22, blue: 0.32)
    /// Subtle divider and container stroke
    static let cvBorder         = Color(red: 0.18, green: 0.18, blue: 0.26)

    /// Primary vibrant cyan accent (search focus, active badges, copy highlights)
    static let cvNeonCyan       = Color(red: 0.00, green: 0.94, blue: 1.00)
    /// Warm amber accent (character counts, notifications, warnings)
    static let cvNeonAmber      = Color(red: 1.00, green: 0.70, blue: 0.00)
    /// Energetic green accent (success states, copied feedback)
    static let cvNeonGreen      = Color(red: 0.00, green: 0.90, blue: 0.46)
    /// Red accent for clear vault / destructive actions
    static let cvNeonRed        = Color(red: 1.00, green: 0.32, blue: 0.32)

    /// Data type badge colors
    static let cvBadgeText      = Color(red: 0.35, green: 0.75, blue: 1.00) // Sky Blue
    static let cvBadgeFile      = Color(red: 0.18, green: 0.84, blue: 0.75) // Teal / Cyan
    static let cvBadgePicture   = Color(red: 0.78, green: 0.52, blue: 1.00) // Purple / Magenta
    static let cvBadgeMarkdown  = Color(red: 0.20, green: 0.88, blue: 0.55) // Mint / Emerald
    static let cvBadgeFormatted = Color(red: 1.00, green: 0.75, blue: 0.20) // Amber / Gold

    /// Dimmed secondary white label text
    static let cvDimWhite       = Color.white.opacity(0.60)
    /// Muted caption text
    static let cvTextMuted      = Color.white.opacity(0.40)
}

// MARK: - NSColor Palette

extension NSColor {
    static let cvBackground     = NSColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)
    static let cvSurface        = NSColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1.0)
    static let cvBorder         = NSColor(red: 0.18, green: 0.18, blue: 0.26, alpha: 1.0)
    static let cvNeonCyan       = NSColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 1.0)
    static let cvNeonAmber      = NSColor(red: 1.00, green: 0.70, blue: 0.00, alpha: 1.0)
    static let cvNeonGreen      = NSColor(red: 0.00, green: 0.90, blue: 0.46, alpha: 1.0)
    static let cvNeonRed        = NSColor(red: 1.00, green: 0.32, blue: 0.32, alpha: 1.0)
}
