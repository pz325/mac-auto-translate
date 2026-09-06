import AppKit
import Foundation
import MacAutoTranslateCore

@MainActor
final class AppState: ObservableObject {
    @Published var input: String
    @Published var result: String
    @Published var sourceLanguage: String
    @Published var targetLanguage: String
    @Published var usesAutomaticDirection: Bool
    @Published var isTranslating = false
    @Published var errorMessage: String?
    @Published var copyConfirmation = false
    @Published var serviceMessage: String?

    let store: ConfigurationStore
    private let client: LLMClient

    init(store: ConfigurationStore = ConfigurationStore(), client: LLMClient = LLMClient()) {
        self.store = store
        self.client = client
        let session = store.loadSession()
        input = session.input
        result = session.result
        sourceLanguage = session.sourceLanguage
        targetLanguage = session.targetLanguage
        usesAutomaticDirection = session.usesAutomaticDirection
    }

    func inputDidChange() {
        if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result = ""
            errorMessage = nil
            copyConfirmation = false
            isTranslating = false
        }
        if usesAutomaticDirection {
            if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                sourceLanguage = "中文"
                targetLanguage = "英文"
            } else {
                let direction = LanguageDetector.automaticDirection(for: input)
                sourceLanguage = direction.source
                targetLanguage = direction.target
            }
        }
        persistSession()
    }

    func setSourceLanguage(_ value: String) {
        sourceLanguage = value
        usesAutomaticDirection = false
        persistSession()
    }

    func setTargetLanguage(_ value: String) {
        targetLanguage = value
        usesAutomaticDirection = false
        persistSession()
    }

    func setAutomaticDirection(_ enabled: Bool) {
        usesAutomaticDirection = enabled
        if enabled { inputDidChange() }
        persistSession()
    }

    func translate() async {
        guard !isTranslating else { return }
        let submittedInput = input
        isTranslating = true
        errorMessage = nil
        defer {
            if input == submittedInput {
                isTranslating = false
            }
        }

        do {
            let response = try await client.translate(
                TranslationRequest(
                    text: submittedInput,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage
                ),
                configuration: store.loadConfiguration(),
                credentials: store.loadCredentials()
            )
            guard input == submittedInput,
                  !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
            }
            result = response.translatedText
            sourceLanguage = response.sourceLanguage
            targetLanguage = response.targetLanguage
            copyResult()
            persistSession()
        } catch {
            if input == submittedInput {
                errorMessage = error.localizedDescription
            }
        }
    }

    func copyResult() {
        guard !result.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result, forType: .string)
        copyConfirmation = true
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            copyConfirmation = false
        }
    }

    private func persistSession() {
        do {
            try store.save(session: TranslationSession(
                input: input,
                result: result,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                usesAutomaticDirection: usesAutomaticDirection
            ))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
