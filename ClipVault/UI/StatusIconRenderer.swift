import AppKit

// MARK: - StatusIconRenderer

/// Renders the ClipVault menu-bar icon — a clipboard outline — with an optional
/// numeric badge showing how many items are currently in the vault.
///
/// Returned images use `isTemplate = true` so macOS automatically inverts them
/// for light/dark mode and highlights the active state correctly.
enum StatusIconRenderer {

    // MARK: - Public API

    /// Returns an `NSImage` sized for the menu bar (22 × 22 pt) showing the
    /// clipboard icon and a small badge with `count` when `count > 0`.
    static func render(count: Int) -> NSImage {
        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size, flipped: false) { rect in
            drawClipboard(in: rect)
            if count > 0 {
                drawBadge(count: count, in: rect)
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    // MARK: - Drawing helpers

    /// Draws a minimal clipboard outline centred in `rect`.
    private static func drawClipboard(in rect: NSRect) {
        // Coordinates tuned for a 22×22 canvas
        let bodyX: CGFloat     = 3.5
        let bodyY: CGFloat     = 1.5
        let bodyWidth: CGFloat = 15.0
        let bodyHeight: CGFloat = 17.0
        let cornerRadius: CGFloat = 2.0

        // Clipboard body
        let bodyRect = NSRect(x: bodyX, y: bodyY, width: bodyWidth, height: bodyHeight)
        let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: cornerRadius, yRadius: cornerRadius)
        bodyPath.lineWidth = 1.3
        NSColor.black.setStroke()
        bodyPath.stroke()

        // Clip at the top (the paper-clip tab)
        let clipWidth: CGFloat  = 6.0
        let clipHeight: CGFloat = 3.0
        let clipX = bodyX + (bodyWidth - clipWidth) / 2
        let clipY = bodyY + bodyHeight - clipHeight / 2
        let clipRect = NSRect(x: clipX, y: clipY, width: clipWidth, height: clipHeight)
        let clipPath = NSBezierPath(roundedRect: clipRect, xRadius: 1.5, yRadius: 1.5)
        clipPath.lineWidth = 1.3
        clipPath.stroke()

        // Three content lines inside the body
        let lineStartX = bodyX + 3.0
        let lineEndX   = bodyX + bodyWidth - 3.0
        let lineSpacing: CGFloat = 3.2
        let firstLineY: CGFloat  = bodyY + 4.5

        NSColor.black.setStroke()
        for i in 0..<3 {
            let y = firstLineY + CGFloat(i) * lineSpacing
            let linePath = NSBezierPath()
            linePath.move(to: NSPoint(x: lineStartX, y: y))
            linePath.line(to: NSPoint(x: (i == 2 ? lineEndX - 3.0 : lineEndX), y: y))
            linePath.lineWidth = 1.1
            linePath.stroke()
        }
    }

    /// Draws a small filled circle badge with `count` (capped at 99) in the
    /// bottom-right corner of `rect`.
    private static func drawBadge(count: Int, in rect: NSRect) {
        let label = count > 99 ? "99+" : "\(count)"
        let badgeSize: CGFloat = count > 9 ? 10.0 : 8.5
        let badgeX = rect.maxX - badgeSize - 0.5
        let badgeY = rect.minY + 0.5
        let badgeRect = NSRect(x: badgeX, y: badgeY, width: badgeSize, height: badgeSize)

        // Filled circle
        let circlePath = NSBezierPath(ovalIn: badgeRect)
        NSColor.black.setFill()
        circlePath.fill()

        // Count label
        let fontSize: CGFloat = count > 9 ? 5.5 : 6.0
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let labelSize = label.size(withAttributes: attrs)
        let labelOrigin = NSPoint(
            x: badgeRect.midX - labelSize.width / 2,
            y: badgeRect.midY - labelSize.height / 2
        )
        label.draw(at: labelOrigin, withAttributes: attrs)
    }
}
