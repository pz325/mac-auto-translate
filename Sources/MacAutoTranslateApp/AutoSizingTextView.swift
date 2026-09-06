import AppKit
import SwiftUI

/// A native text view whose SwiftUI height follows AppKit's actual text layout.
struct AutoSizingTextView: NSViewRepresentable {
    @Binding var text: String
    var isEditable: Bool
    var font: NSFont
    var verticalInset: CGFloat = 4
    var onTranslate: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NativeTextView {
        let textView = NativeTextView(frame: .zero)
        textView.delegate = context.coordinator
        textView.onTranslate = onTranslate
        textView.isRichText = false
        textView.importsGraphics = false
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.textColor = .labelColor
        textView.insertionPointColor = .controlAccentColor
        textView.font = font
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 0, height: verticalInset)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.focusRingType = .none
        textView.string = text
        return textView
    }

    func updateNSView(_ textView: NativeTextView, context: Context) {
        if textView.string != text {
            textView.string = text
        }
        textView.font = font
        textView.isEditable = isEditable
        textView.textContainerInset = NSSize(width: 0, height: verticalInset)
        textView.onTranslate = onTranslate
        textView.invalidateIntrinsicContentSize()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView textView: NativeTextView, context: Context) -> CGSize? {
        guard let proposedWidth = proposal.width, proposedWidth > 0,
              let textContainer = textView.textContainer,
              let layoutManager = textView.layoutManager else {
            return nil
        }

        let layoutWidth = max(1, proposedWidth - textView.textContainerInset.width * 2)
        textContainer.containerSize = NSSize(width: layoutWidth, height: CGFloat.greatestFiniteMagnitude)
        layoutManager.ensureLayout(for: textContainer)
        let usedHeight = ceil(layoutManager.usedRect(for: textContainer).height)
        let height = max(font.pointSize + verticalInset * 2, usedHeight + verticalInset * 2)
        return CGSize(width: proposedWidth, height: height)
    }

    final class NativeTextView: NSTextView {
        var onTranslate: (() -> Void)?

        override func keyDown(with event: NSEvent) {
            let relevantModifiers = event.modifierFlags.intersection([.shift, .control, .option, .command])
            let isReturn = event.keyCode == 36 || event.keyCode == 76
            if isReturn, relevantModifiers == .shift {
                onTranslate?()
                return
            }
            super.keyDown(with: event)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding private var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
            textView.invalidateIntrinsicContentSize()
        }
    }
}
