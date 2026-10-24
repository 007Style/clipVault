import XCTest
@testable import ClipVault

// MARK: - ClipItemTests

final class ClipItemTests: XCTestCase {

    // MARK: Basic creation

    func testClipItemStoresText() {
        let item = ClipItem(text: "Hello, world!")
        XCTAssertEqual(item.text, "Hello, world!")
        XCTAssertFalse(item.isTruncated)
    }

    func testCharCount() {
        let text = "Swift"
        let item = ClipItem(text: text)
        XCTAssertEqual(item.charCount, text.count)
    }

    func testWordCount() {
        let item = ClipItem(text: "one two three")
        XCTAssertEqual(item.wordCount, 3)
    }

    func testWordCountIgnoresExtraWhitespace() {
        let item = ClipItem(text: "  hello   world  ")
        XCTAssertEqual(item.wordCount, 2)
    }

    // MARK: 10,000-character cap

    func testTextExactlyAtCapNotTruncated() {
        let text = String(repeating: "a", count: ClipItem.maxCharacters)
        let item = ClipItem(text: text)
        XCTAssertEqual(item.text.count, ClipItem.maxCharacters)
        XCTAssertFalse(item.isTruncated)
    }

    func testTextOverCapIsTruncated() {
        let text = String(repeating: "b", count: ClipItem.maxCharacters + 500)
        let item = ClipItem(text: text)
        XCTAssertEqual(item.text.count, ClipItem.maxCharacters)
        XCTAssertTrue(item.isTruncated)
    }

    func testCharCountReflectsCappedLength() {
        let text = String(repeating: "c", count: ClipItem.maxCharacters + 1)
        let item = ClipItem(text: text)
        XCTAssertEqual(item.charCount, ClipItem.maxCharacters)
    }

    // MARK: Preview

    func testPreviewTruncatesLongSingleLine() {
        let text = String(repeating: "x", count: 200)
        let item = ClipItem(text: text)
        XCTAssertTrue(item.preview.hasSuffix("…"))
        XCTAssertLessThanOrEqual(item.preview.count, ClipItem.previewLength + 1)
    }

    func testPreviewCollapsesNewlines() {
        let item = ClipItem(text: "line one\nline two")
        XCTAssertFalse(item.preview.contains("\n"))
    }

    func testShortTextPreviewHasNoEllipsis() {
        let item = ClipItem(text: "short")
        XCTAssertFalse(item.preview.hasSuffix("…"))
        XCTAssertEqual(item.preview, "short")
    }

    // MARK: Equality / identity

    func testTwoItemsWithSameIDAreEqual() {
        let id = UUID()
        let a = ClipItem(id: id, text: "hello")
        let b = ClipItem(id: id, text: "world")
        XCTAssertEqual(a, b)
    }

    func testTwoItemsWithDifferentIDsAreNotEqual() {
        let a = ClipItem(text: "hello")
        let b = ClipItem(text: "hello")
        XCTAssertNotEqual(a, b)
    }
}

// MARK: - DataTypeDetectionTests

final class DataTypeDetectionTests: XCTestCase {

    // MARK: Text Detection

    func testPlainTextDetection() {
        let text = "Just a simple sentence without formatting."
        let type = ClipItem.detectType(text: text)
        XCTAssertEqual(type, .text)
    }

    func testURLStringIsPlainText() {
        let url = "https://developer.apple.com/documentation/appkit"
        let type = ClipItem.detectType(text: url)
        XCTAssertEqual(type, .text)
    }

    // MARK: File Detection

    func testFileURLPrefixDetection() {
        let fileUrl = "file:///Users/daneyand/Documents/file.pdf"
        let type = ClipItem.detectType(text: fileUrl)
        XCTAssertEqual(type, .file)
    }

    func testAbsoluteUnixPathDetection() {
        let path = "/Users/daneyand/Documents/project/README.md"
        let type = ClipItem.detectType(text: path)
        XCTAssertEqual(type, .file)
    }

    func testTildePathDetection() {
        let path = "~/Desktop/screenshot.png"
        let type = ClipItem.detectType(text: path)
        XCTAssertEqual(type, .file)
    }

    func testIsFileFlagOverrides() {
        let text = "Custom file reference"
        let type = ClipItem.detectType(text: text, isFile: true)
        XCTAssertEqual(type, .file)
    }

    // MARK: Picture Detection

    func testDataURIPictureDetection() {
        let uri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
        let type = ClipItem.detectType(text: uri)
        XCTAssertEqual(type, .picture)
    }

    func testIsImageFlagPictureDetection() {
        let desc = "Picture (1920 × 1080 px)"
        let type = ClipItem.detectType(text: desc, isImage: true)
        XCTAssertEqual(type, .picture)
    }

    // MARK: Markdown Detection

    func testMarkdownCodeBlockDetection() {
        let code = "```swift\nlet x = 10\nprint(x)\n```"
        let type = ClipItem.detectType(text: code)
        XCTAssertEqual(type, .markdown)
    }

    func testMarkdownHeadingDetection() {
        let md = "# Project Title\nThis is a header."
        let type = ClipItem.detectType(text: md)
        XCTAssertEqual(type, .markdown)
    }

    func testMarkdownSubHeadingDetection() {
        let md = "## Installation Guide\nRun brew install."
        let type = ClipItem.detectType(text: md)
        XCTAssertEqual(type, .markdown)
    }

    func testMarkdownBoldDetection() {
        let md = "Please make sure this is **very important** before submitting."
        let type = ClipItem.detectType(text: md)
        XCTAssertEqual(type, .markdown)
    }

    func testMarkdownLinkDetection() {
        let md = "Check out [Apple Developer](https://developer.apple.com) for details."
        let type = ClipItem.detectType(text: md)
        XCTAssertEqual(type, .markdown)
    }

    func testMarkdownTaskChecklistDetection() {
        let md = "- [ ] Task 1\n- [x] Task 2 completed"
        let type = ClipItem.detectType(text: md)
        XCTAssertEqual(type, .markdown)
    }

    func testMarkdownBlockquoteDetection() {
        let md = "> Simplicity is prerequisite for reliability.\n— Edsger Dijkstra"
        let type = ClipItem.detectType(text: md)
        XCTAssertEqual(type, .markdown)
    }

    func testMarkdownTableDetection() {
        let md = "| Name | Status |\n|---|---|\n| Alpha | Done |"
        let type = ClipItem.detectType(text: md)
        XCTAssertEqual(type, .markdown)
    }

    // MARK: Formatted Text Detection

    func testHTMLTagsDetection() {
        let html = "<p>This is a <strong>bold</strong> paragraph.</p>"
        let type = ClipItem.detectType(text: html)
        XCTAssertEqual(type, .formatted)
    }

    func testHTMLDocumentDetection() {
        let html = "<!DOCTYPE html><html><body><h1>Header</h1></body></html>"
        let type = ClipItem.detectType(text: html)
        XCTAssertEqual(type, .formatted)
    }

    func testRichFormattingFlagDetection() {
        let rich = "Rich styled text from clipboard"
        let type = ClipItem.detectType(text: rich, hasRichFormatting: true)
        XCTAssertEqual(type, .formatted)
    }

    // MARK: Badges and Symbols

    func testDataTypeDisplayNamesAndIcons() {
        XCTAssertEqual(ClipDataType.text.displayName, "Text")
        XCTAssertEqual(ClipDataType.file.displayName, "File")
        XCTAssertEqual(ClipDataType.picture.displayName, "Picture")
        XCTAssertEqual(ClipDataType.markdown.displayName, "Markdown")
        XCTAssertEqual(ClipDataType.formatted.displayName, "Formatted")

        XCTAssertFalse(ClipDataType.text.iconName.isEmpty)
        XCTAssertFalse(ClipDataType.file.iconName.isEmpty)
        XCTAssertFalse(ClipDataType.picture.iconName.isEmpty)
        XCTAssertFalse(ClipDataType.markdown.iconName.isEmpty)
        XCTAssertFalse(ClipDataType.formatted.iconName.isEmpty)
    }
}

// MARK: - AppStateTests

final class AppStateTests: XCTestCase {

    var state: AppState!

    override func setUp() {
        super.setUp()
        state = AppState()
    }

    override func tearDown() {
        state = nil
        super.tearDown()
    }

    // MARK: addItem

    func testAddItemAppearsAtHead() {
        state.addItem(text: "first")
        state.addItem(text: "second")
        XCTAssertEqual(state.items.first?.text, "second")
    }

    func testAddItemWithExplicitDataType() {
        state.addItem(text: "Some description", dataType: .picture)
        XCTAssertEqual(state.items.first?.dataType, .picture)
    }

    func testAddItemAutoDetectsMarkdown() {
        state.addItem(text: "```bash\necho hello\n```")
        XCTAssertEqual(state.items.first?.dataType, .markdown)
    }

    func testAddItemAutoDetectsFile() {
        state.addItem(text: "/Library/Fonts/Arial.ttf")
        XCTAssertEqual(state.items.first?.dataType, .file)
    }

    func testAddItemIncreasesTotalCount() {
        state.addItem(text: "alpha")
        XCTAssertEqual(state.totalCount, 1)
        state.addItem(text: "beta")
        XCTAssertEqual(state.totalCount, 2)
    }

    func testAddEmptyStringIsIgnored() {
        state.addItem(text: "")
        XCTAssertEqual(state.totalCount, 0)
    }

    func testAddWhitespaceOnlyIsIgnored() {
        state.addItem(text: "   \n\t  ")
        XCTAssertEqual(state.totalCount, 0)
    }

    // MARK: 200-item ceiling

    func testVaultCapAt200() {
        for i in 0..<250 {
            state.addItem(text: "item \(i)")
        }
        XCTAssertEqual(state.totalCount, AppState.maxItems)
    }

    func testNewestItemsKeptWhenCapExceeded() {
        for i in 0..<250 {
            state.addItem(text: "item \(i)")
        }
        XCTAssertEqual(state.items.first?.text, "item 249")
        XCTAssertEqual(state.items.last?.text, "item 50")
    }

    // MARK: Deduplication

    func testDuplicateTextPromotesExistingItem() {
        state.addItem(text: "alpha")
        state.addItem(text: "beta")
        state.addItem(text: "alpha")
        XCTAssertEqual(state.items.first?.text, "alpha")
        XCTAssertEqual(state.totalCount, 2)
    }

    func testDuplicateDoesNotExceedCount() {
        state.addItem(text: "x")
        state.addItem(text: "y")
        state.addItem(text: "x")
        XCTAssertEqual(state.totalCount, 2)
    }

    // MARK: promoteItem

    func testPromoteItemMovesToHead() {
        state.addItem(text: "first")
        state.addItem(text: "second")
        state.addItem(text: "third")
        let targetID = state.items[2].id
        state.promoteItem(id: targetID)
        XCTAssertEqual(state.items.first?.id, targetID)
    }

    func testPromoteItemRefreshesTimestamp() throws {
        state.addItem(text: "old")
        let id = try XCTUnwrap(state.items.first?.id)
        let before = Date()
        Thread.sleep(forTimeInterval: 0.01)
        state.promoteItem(id: id)
        let promoted = try XCTUnwrap(state.items.first)
        XCTAssertGreaterThanOrEqual(promoted.timestamp, before)
    }

    func testPromoteNonExistentIDReturnsNil() {
        state.addItem(text: "something")
        let result = state.promoteItem(id: UUID())
        XCTAssertNil(result)
    }

    func testPromoteItemCountUnchanged() {
        state.addItem(text: "a")
        state.addItem(text: "b")
        state.addItem(text: "c")
        let id = state.items[1].id
        state.promoteItem(id: id)
        XCTAssertEqual(state.totalCount, 3)
    }

    // MARK: clearVault

    func testClearVaultEmptiesItems() {
        state.addItem(text: "one")
        state.addItem(text: "two")
        state.clearVault()
        XCTAssertTrue(state.items.isEmpty)
    }

    func testClearVaultSetsCountToZero() {
        state.addItem(text: "x")
        state.clearVault()
        XCTAssertEqual(state.totalCount, 0)
    }

    // MARK: Search filtering

    func testFilteredItemsReturnsAllWhenQueryEmpty() {
        state.addItem(text: "apple")
        state.addItem(text: "banana")
        state.searchQuery = ""
        XCTAssertEqual(state.filteredItems.count, 2)
    }

    func testFilteredItemsMatchesCaseInsensitive() {
        state.addItem(text: "Hello World")
        state.addItem(text: "goodbye")
        state.searchQuery = "hello"
        XCTAssertEqual(state.filteredItems.count, 1)
        XCTAssertEqual(state.filteredItems.first?.text, "Hello World")
    }

    func testFilteredItemsMatchesDataTypeName() {
        state.addItem(text: "Simple note") // Text
        state.addItem(text: "/var/log/system.log") // File
        state.addItem(text: "```python\nprint(1)\n```") // Markdown

        state.searchQuery = "Markdown"
        XCTAssertEqual(state.filteredItems.count, 1)
        XCTAssertEqual(state.filteredItems.first?.dataType, .markdown)

        state.searchQuery = "File"
        XCTAssertEqual(state.filteredItems.count, 1)
        XCTAssertEqual(state.filteredItems.first?.dataType, .file)
    }

    func testFilteredItemsReturnsEmptyWhenNoMatch() {
        state.addItem(text: "swift")
        state.searchQuery = "python"
        XCTAssertTrue(state.filteredItems.isEmpty)
    }

    func testFilteredItemsMatchesPartialSubstring() {
        state.addItem(text: "clipboard monitor")
        state.searchQuery = "board"
        XCTAssertEqual(state.filteredItems.count, 1)
    }

    func testFilteredItemsIgnoresLeadingTrailingSpacesInQuery() {
        state.addItem(text: "hello")
        state.searchQuery = "  hello  "
        XCTAssertEqual(state.filteredItems.count, 1)
    }
}
