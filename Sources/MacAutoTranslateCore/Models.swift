import Foundation

/// LLM wire protocols supported by MacAutoTranslate.
public enum LLMProvider: String, Codable, CaseIterable, Sendable {
    case openAI = "openai"
    case anthropic = "anthropic"

    public var displayName: String {
        switch self {
        case .openAI: "OpenAI"
        case .anthropic: "Anthropic / Kimi"
        }
    }
}

/// Non-secret settings shared by the app, HTTP service, and MCP server.
public struct LLMConfiguration: Codable, Equatable, Sendable {
    public var provider: LLMProvider
    public var baseURL: String
    public var model: String
    public var prompt: String
    public var timeoutMilliseconds: Int
    public var servicePort: UInt16

    public init(
        provider: LLMProvider = .anthropic,
        baseURL: String = "https://api.kimi.com/coding/",
        model: String = "kimi-for-coding-flash",
        prompt: String = Self.defaultPrompt,
        timeoutMilliseconds: Int = 600_000,
        servicePort: UInt16 = 8765
    ) {
        self.provider = provider
        self.baseURL = baseURL
        self.model = model
        self.prompt = prompt
        self.timeoutMilliseconds = timeoutMilliseconds
        self.servicePort = servicePort
    }

    public static let defaultPrompt = """
    You are a professional translator with expertise in over 50 languages. Your task is to translate the user's input text accurately while preserving its original tone, style, intent, and nuance.

    ## Core Rules
    1. **Auto-detect the source language** — do not assume English.
    2. If it is Chinese or Chinese-mixed, the default target language is English; if it is non-Chinese, the default target language is Chinese. Unless [Source] and [Target] are specified.
    3. **Preserve formatting** — maintain line breaks, bullet points, markdown, code blocks, and special characters exactly as they appear in the source.
    4. **Preserve untranslatables** — do not translate proper nouns, brand names, code variables, URLs, file paths, or technical identifiers unless explicitly asked.

    ## Tone & Style
    - Match the register: casual → casual, formal → formal, technical → technical, poetic → poetic.
    - Preserve idioms metaphorically where possible; if a direct equivalent doesn't exist, convey the intended meaning naturally.
    - Do not add explanations, summaries, or commentary unless the user explicitly requests them.

    ## Output Format
    Return **only the translated text**, with no preamble like "Here is the translation:". If the input contains multiple distinct sections, maintain their structure.

    ## Language Pair
    Always translate from [Source] to [Target]. If the input is already in [Target], translate it back to [Source].
    """
}

/// Secret values are intentionally persisted separately from ordinary configuration.
public struct Credentials: Codable, Equatable, Sendable {
    public var apiKey: String

    public init(apiKey: String = "") {
        self.apiKey = apiKey
    }
}

/// A provider-ready translation request.
public struct TranslationRequest: Codable, Equatable, Sendable {
    public var text: String
    public var sourceLanguage: String?
    public var targetLanguage: String?

    public init(text: String, sourceLanguage: String? = nil, targetLanguage: String? = nil) {
        self.text = text
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
    }
}

/// Result returned consistently by the library, HTTP API, and MCP server.
public struct TranslationResponse: Codable, Equatable, Sendable {
    public var translatedText: String
    public var sourceLanguage: String
    public var targetLanguage: String
    public var provider: LLMProvider
    public var model: String

    public init(
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String,
        provider: LLMProvider,
        model: String
    ) {
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.provider = provider
        self.model = model
    }
}

/// Persisted UI session used to restore the previous input and result.
public struct TranslationSession: Codable, Equatable, Sendable {
    public var input: String
    public var result: String
    public var sourceLanguage: String
    public var targetLanguage: String
    public var usesAutomaticDirection: Bool

    public init(
        input: String = "",
        result: String = "",
        sourceLanguage: String = "中文",
        targetLanguage: String = "英文",
        usesAutomaticDirection: Bool = true
    ) {
        self.input = input
        self.result = result
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.usesAutomaticDirection = usesAutomaticDirection
    }
}

/// Redacted configuration safe to expose over the localhost API.
public struct ConfigurationSummary: Codable, Equatable, Sendable {
    public var provider: LLMProvider
    public var baseURL: String
    public var model: String
    public var timeoutMilliseconds: Int
    public var servicePort: UInt16
    public var hasAPIKey: Bool
}

public enum MacAutoTranslateError: LocalizedError, Equatable {
    case emptyInput
    case missingAPIKey
    case invalidBaseURL(String)
    case invalidResponse
    case provider(statusCode: Int, message: String)
    case noTranslatedText
    case persistence(String)
    case service(String)

    public var errorDescription: String? {
        switch self {
        case .emptyInput: "请输入要翻译的文本。"
        case .missingAPIKey: "尚未配置 API Key。请点击菜单栏图标打开设置。"
        case let .invalidBaseURL(value): "Base URL 无效：\(value)"
        case .invalidResponse: "LLM 返回了无法解析的响应。"
        case let .provider(statusCode, message): "LLM 请求失败（HTTP \(statusCode)）：\(message)"
        case .noTranslatedText: "LLM 响应中没有可用的翻译文本。"
        case let .persistence(message): "配置保存失败：\(message)"
        case let .service(message): "本地服务错误：\(message)"
        }
    }
}
