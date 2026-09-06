import Foundation

public enum PromptRenderer {
    public static func render(template: String, source: String, target: String) -> String {
        template
            .replacingOccurrences(of: "[Source]", with: source)
            .replacingOccurrences(of: "[Target]", with: target)
    }
}
