import SwiftUI

struct SpotlightView: View {
    @ObservedObject var state: AppState
    let onHeightChange: (CGFloat) -> Void
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            inputSection

            if state.isTranslating || !state.result.isEmpty || state.errorMessage != nil {
                Divider().opacity(0.45)
                resultSection
            }
        }
        .frame(width: 640)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.26), radius: 24, y: 12)
        .padding(28)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: PanelHeightKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(PanelHeightKey.self, perform: onHeightChange)
        .onExitCommand { NSApp.keyWindow?.orderOut(nil) }
        .onReceive(NotificationCenter.default.publisher(for: .focusTranslationInput)) { _ in
            inputFocused = true
        }
    }

    private var inputSection: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "globe.asia.australia.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 9)

                TextEditor(text: $state.input)
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .scrollContentBackground(.hidden)
                    .focused($inputFocused)
                    .frame(height: adaptiveHeight(for: state.input, minimum: 46, maximum: 190))
                    .accessibilityLabel("待翻译文本")
                    .onChange(of: state.input) { _ in state.inputDidChange() }

                Button {
                    Task { await state.translate() }
                } label: {
                    if state.isTranslating {
                        ProgressView().controlSize(.small).frame(width: 30, height: 30)
                    } else {
                        Image(systemName: "character.book.closed.fill").frame(width: 30, height: 30)
                    }
                }
                .buttonStyle(.borderless)
                .keyboardShortcut("t", modifiers: [.shift])
                .disabled(state.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || state.isTranslating)
                .help("翻译（⇧T）")
                .accessibilityLabel("翻译")
                .padding(.top, 7)
            }

            HStack(spacing: 8) {
                LanguageField(title: "源", text: Binding(
                    get: { state.sourceLanguage },
                    set: { state.setSourceLanguage($0) }
                ))
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                LanguageField(title: "目标", text: Binding(
                    get: { state.targetLanguage },
                    set: { state.setTargetLanguage($0) }
                ))
                Spacer()
                Toggle("自动", isOn: Binding(
                    get: { state.usesAutomaticDirection },
                    set: { state.setAutomaticDirection($0) }
                ))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .help("按输入内容自动设置翻译方向")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if state.isTranslating {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("正在翻译…").foregroundStyle(.secondary)
                }
            } else if let error = state.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            } else {
                HStack(alignment: .top, spacing: 12) {
                    Text(state.result)
                        .font(.system(size: 17))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: adaptiveHeight(for: state.result, minimum: 42, maximum: 280), alignment: .topLeading)

                    Button(action: state.copyResult) {
                        Image(systemName: state.copyConfirmation ? "checkmark" : "doc.on.doc")
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.borderless)
                    .help("拷贝翻译结果")
                    .accessibilityLabel("拷贝翻译结果")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func adaptiveHeight(for text: String, minimum: CGFloat, maximum: CGFloat) -> CGFloat {
        let explicitLines = max(1, text.components(separatedBy: .newlines).count)
        let wrappedLines = max(explicitLines, Int(ceil(Double(max(text.count, 1)) / 55.0)))
        return min(maximum, max(minimum, CGFloat(wrappedLines) * 24 + 14))
    }
}

private struct LanguageField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 5) {
            Text(title).foregroundStyle(.tertiary)
            TextField(title, text: $text)
                .textFieldStyle(.plain)
                .frame(width: 76)
        }
        .font(.caption)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.quaternary.opacity(0.65), in: Capsule())
    }
}

private struct PanelHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 210
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
