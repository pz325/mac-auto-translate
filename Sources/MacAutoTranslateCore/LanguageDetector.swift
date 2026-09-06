import Foundation

public struct LanguageDirection: Equatable, Sendable {
    public var source: String
    public var target: String

    public init(source: String, target: String) {
        self.source = source
        self.target = target
    }
}

/// Resolves the product's Chinese/mixed-Chinese translation rule.
public enum LanguageDetector {
    public static func containsChinese(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x3400...0x4DBF,
                 0x4E00...0x9FFF,
                 0xF900...0xFAFF,
                 0x20000...0x2FA1F:
                true
            default:
                false
            }
        }
    }

    public static func automaticDirection(for text: String) -> LanguageDirection {
        if containsChinese(text) {
            LanguageDirection(source: "中文", target: "英文")
        } else {
            LanguageDirection(source: "自动检测", target: "中文")
        }
    }
}
