import AppKit
import Foundation

// MARK: - ClipboardMonitor

/// Polls `NSPasteboard.general` on a background timer and forwards clipboard
/// content with classified data types to `AppState`. A self-suppression flag
/// prevents items written back to the pasteboard by ClipVault from being captured
/// as new duplicate entries.
final class ClipboardMonitor {

    // MARK: Singleton

    static let shared = ClipboardMonitor()

    // MARK: Private state

    private var timer: DispatchSourceTimer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount

    /// Set to `true` before writing to the pasteboard on behalf of the user
    /// (e.g. when promoting an item). The next polling tick that detects a
    /// `changeCount` increment will consume the flag without creating a new entry.
    private(set) var isSuppressed: Bool = false

    private let pollInterval: TimeInterval
    private let queue = DispatchQueue(label: "com.clipvault.monitor", qos: .utility)

    // MARK: Init

    private init(pollInterval: TimeInterval = 0.5) {
        self.pollInterval = pollInterval
    }

    // MARK: Lifecycle

    func start() {
        guard timer == nil else { return }
        lastChangeCount = NSPasteboard.general.changeCount

        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + pollInterval, repeating: pollInterval, leeway: .milliseconds(50))
        t.setEventHandler { [weak self] in self?.poll() }
        t.resume()
        timer = t
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    // MARK: Suppression

    /// Call this immediately before writing text to `NSPasteboard` on behalf of
    /// clipVault (e.g. item promotion) so the next `changeCount` increment is
    /// silently absorbed without creating a duplicate vault entry.
    func suppress() {
        isSuppressed = true
    }

    // MARK: Write Back to Pasteboard

    /// Writes a `ClipItem` back to `NSPasteboard.general` with appropriate types,
    /// suppressing the next polling loop tick.
    func writeToPasteboard(item: ClipItem) {
        suppress()
        let pb = NSPasteboard.general
        pb.clearContents()

        switch item.dataType {
        case .picture:
            if let rawData = item.rawData, let image = NSImage(data: rawData) {
                pb.writeObjects([image])
            }
            pb.setString(item.text, forType: .string)

        case .file:
            pb.setString(item.text, forType: .string)
            let lines = item.text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
            let urls = lines.compactMap { line -> NSURL? in
                if line.hasPrefix("file://"), let u = URL(string: line) {
                    return u as NSURL
                }
                let expanded = (line as NSString).expandingTildeInPath
                if expanded.hasPrefix("/") {
                    return NSURL(fileURLWithPath: expanded)
                }
                return nil
            }
            if !urls.isEmpty {
                pb.writeObjects(urls)
            }

        case .formatted:
            if let rawData = item.rawData {
                pb.setData(rawData, forType: .rtf)
            }
            pb.setString(item.text, forType: .string)

        case .markdown, .text:
            pb.setString(item.text, forType: .string)
        }
    }

    // MARK: - Private polling

    private func poll() {
        let pb = NSPasteboard.general
        let current = pb.changeCount

        guard current != lastChangeCount else { return }
        lastChangeCount = current

        // Consume suppression flag if set
        if isSuppressed {
            isSuppressed = false
            return
        }

        let types = pb.types ?? []

        // 1. Check for Image / Picture payload
        if types.contains(.tiff) || types.contains(.png) {
            if let image = NSImage(pasteboard: pb),
               let tiffData = pb.data(forType: .tiff) ?? pb.data(forType: .png) {
                let size = image.size
                let width = Int(size.width)
                let height = Int(size.height)
                let desc = "Picture (\(width) × \(height) px)"
                DispatchQueue.main.async {
                    AppState.shared.addItem(text: desc, dataType: .picture, rawData: tiffData)
                }
                return
            }
        }

        // 2. Check for File URL payload
        if types.contains(.fileURL) || types.contains(.init("NSFilenamesPboardType")) {
            if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
                let pathList = urls.map { $0.path }.joined(separator: "\n")
                if !pathList.isEmpty {
                    DispatchQueue.main.async {
                        AppState.shared.addItem(text: pathList, dataType: .file)
                    }
                    return
                }
            }
        }

        // 3. Check for text payloads (Rich, Markdown, Plain Text, or File paths)
        guard let text = pb.string(forType: .string), !text.isEmpty else { return }

        let hasRich = types.contains(.rtf) || types.contains(.rtfd) || types.contains(.html)
        let rtfData = pb.data(forType: .rtf) ?? pb.data(forType: .html)
        let detectedType = ClipItem.detectType(text: text, hasRichFormatting: hasRich)

        DispatchQueue.main.async {
            AppState.shared.addItem(text: text, dataType: detectedType, rawData: rtfData)
        }
    }
}
