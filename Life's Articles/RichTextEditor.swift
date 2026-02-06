//
//  RichTextEditor.swift
//  Life's Articles
//
//  Created by Bram Adams on 2/6/26.
//

import SwiftUI

struct RichTextEditor: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onRequestLink: (NSRange, String) -> Void

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.showsVerticalScrollIndicator = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.widthTracksTextView = true
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.delegate = context.coordinator
        textView.text = text.isEmpty ? placeholder : text
        textView.textColor = text.isEmpty ? .secondaryLabel : .label

        let interaction = UIEditMenuInteraction(delegate: context.coordinator)
        textView.addInteraction(interaction)
        context.coordinator.textView = textView

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text && !(uiView.isFirstResponder && uiView.markedTextRange != nil) {
            uiView.text = text
            uiView.textColor = text.isEmpty ? .secondaryLabel : .label
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITextViewDelegate, UIEditMenuInteractionDelegate {
        var parent: RichTextEditor
        weak var textView: UITextView?
        private var didTriggerLink = false

        init(parent: RichTextEditor) {
            self.parent = parent
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.textColor == .secondaryLabel {
                textView.text = ""
                textView.textColor = .label
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                textView.text = parent.placeholder
                textView.textColor = .secondaryLabel
            }
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.textColor == .secondaryLabel ? "" : textView.text
            triggerLinkIfNeeded(in: textView)
        }

        private func triggerLinkIfNeeded(in textView: UITextView) {
            guard !didTriggerLink else { return }
            let cursor = textView.selectedRange.location
            guard cursor >= 2 else { return }
            let nsText = textView.text as NSString
            let recentRange = NSRange(location: cursor - 2, length: 2)
            if nsText.substring(with: recentRange) == "[[" {
                didTriggerLink = true
                parent.onRequestLink(recentRange, "")
            }
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            if didTriggerLink, textView.selectedRange.length == 0 {
                didTriggerLink = false
            }
        }

        func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration, suggestedActions: [UIMenuElement]) -> UIMenu? {
            let linkAction = UIAction(title: "Link it") { [weak self] _ in
                guard let self, let textView = self.textView else { return }
                let range = textView.selectedRange
                guard range.length > 0 else { return }
                let selectedText = (textView.text as NSString).substring(with: range)
                self.didTriggerLink = true
                self.parent.onRequestLink(range, selectedText)
            }

            return UIMenu(children: suggestedActions + [linkAction])
        }
    }
}
