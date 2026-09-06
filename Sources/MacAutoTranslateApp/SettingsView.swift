import MacAutoTranslateCore
import SwiftUI

@MainActor
final class SettingsModel: ObservableObject {
    @Published var provider: LLMProvider
    @Published var baseURL: String
    @Published var model: String
    @Published var apiKey: String
    @Published var prompt: String
    @Published var timeoutMilliseconds: Int
    @Published var servicePort: Int
    @Published var statusMessage: String?
    @Published var isTesting = false

    private let store: ConfigurationStore
    private let client = LLMClient()

    init(store: ConfigurationStore) {
        self.store = store
        let config = store.loadConfiguration()
        provider = config.provider
        baseURL = config.baseURL
        model = config.model
        prompt = config.prompt
        timeoutMilliseconds = config.timeoutMilliseconds
        servicePort = Int(config.servicePort)
        apiKey = store.loadCredentials().apiKey
    }

    func applyKimiPreset() {
        provider = .anthropic
        baseURL = "https://api.kimi.com/coding/"
        model = "kimi-for-coding-flash"
        timeoutMilliseconds = 600_000
        statusMessage = "已应用 Kimi Code Anthropic 兼容预设，请填写 API Key。"
    }

    func save() -> Bool {
        do {
            try store.save(configuration: configuration(), credentials: Credentials(apiKey: apiKey))
            statusMessage = "设置已保存。"
            return true
        } catch {
            statusMessage = error.localizedDescription
            return false
        }
    }

    func test() async {
        guard !isTesting else { return }
        isTesting = true
        statusMessage = nil
        defer { isTesting = false }

        guard save() else { return }
        do {
            let sample = try await client.testConnection(
                configuration: configuration(),
                credentials: Credentials(apiKey: apiKey)
            )
            statusMessage = "连接成功：\(sample)"
        } catch {
            statusMessage = "连接失败：\(error.localizedDescription)"
        }
    }

    private func configuration() -> LLMConfiguration {
        LLMConfiguration(
            provider: provider,
            baseURL: baseURL,
            model: model,
            prompt: prompt,
            timeoutMilliseconds: max(1_000, timeoutMilliseconds),
            servicePort: UInt16(clamping: servicePort)
        )
    }
}

struct SettingsView: View {
    @StateObject private var model: SettingsModel

    init(store: ConfigurationStore) {
        _model = StateObject(wrappedValue: SettingsModel(store: store))
    }

    var body: some View {
        Form {
            Section("LLM") {
                Picker("Provider", selection: $model.provider) {
                    ForEach(LLMProvider.allCases, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                TextField("Base URL", text: $model.baseURL)
                TextField("Model", text: $model.model)
                SecureField("API Key", text: $model.apiKey)
                    .privacySensitive()
                HStack {
                    Button("使用 Kimi Code 预设", action: model.applyKimiPreset)
                    Spacer()
                    Text("凭证保存在 app 私有文件（0600），不使用 Keychain。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("翻译 Prompt") {
                TextEditor(text: $model.prompt)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 220)
                Text("支持 [Source] 与 [Target] 占位符。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("服务") {
                LabeledContent("超时（毫秒）") {
                    TextField("600000", value: $model.timeoutMilliseconds, format: .number)
                        .frame(width: 110)
                }
                LabeledContent("localhost 端口") {
                    TextField("8765", value: $model.servicePort, format: .number)
                        .frame(width: 110)
                }
                Text("端口变更会在下次启动 App 或独立服务时生效。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                if let status = model.statusMessage {
                    Text(status)
                        .font(.callout)
                        .foregroundStyle(status.hasPrefix("连接失败") ? .red : .secondary)
                        .textSelection(.enabled)
                }
                Spacer()
                Button("保存", action: { _ = model.save() })
                Button {
                    Task { await model.test() }
                } label: {
                    if model.isTesting { ProgressView().controlSize(.small) }
                    else { Text("测试 LLM") }
                }
                .disabled(model.isTesting)
                .buttonStyle(.borderedProminent)
            }
        }
        .formStyle(.grouped)
        .padding(12)
        .frame(width: 680, height: 640)
    }
}
