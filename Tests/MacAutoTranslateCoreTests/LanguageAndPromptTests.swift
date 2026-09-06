import XCTest
@testable import MacAutoTranslateCore

final class LanguageAndPromptTests: XCTestCase {
    func testChineseAndMixedTextResolveToEnglish() {
        XCTAssertTrue(LanguageDetector.containsChinese("hello 世界"))
        XCTAssertEqual(
            LanguageDetector.automaticDirection(for: "hello 世界"),
            LanguageDirection(source: "中文", target: "英文")
        )
    }

    func testNonChineseTextResolvesToChinese() {
        XCTAssertFalse(LanguageDetector.containsChinese("こんにちは world"))
        XCTAssertEqual(
            LanguageDetector.automaticDirection(for: "bonjour"),
            LanguageDirection(source: "自动检测", target: "中文")
        )
    }

    func testPromptReplacesEveryLanguagePlaceholder() {
        let rendered = PromptRenderer.render(
            template: "[Source] -> [Target]; back [Target] -> [Source]",
            source: "日文",
            target: "法文"
        )
        XCTAssertEqual(rendered, "日文 -> 法文; back 法文 -> 日文")
    }
}
