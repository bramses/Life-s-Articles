//
//  LinkPickerView.swift
//  Life's Articles
//
//  Created by Bram Adams on 2/6/26.
//

import SwiftUI

struct LinkCandidate: Identifiable {
    let id = UUID()
    let title: String
    let target: String
}

struct LinkPickerView: View {
    let articles: [Article]
    let onSelect: (String) -> Void
    let initialDisplayText: String

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var externalURL = ""
    @State private var displayText: String

    init(articles: [Article], initialDisplayText: String = "", onSelect: @escaping (String) -> Void) {
        self.articles = articles
        self.initialDisplayText = initialDisplayText
        self.onSelect = onSelect
        self._displayText = State(initialValue: initialDisplayText)
    }

    private var candidates: [LinkCandidate] {
        var results: [LinkCandidate] = []
        for article in articles {
            let articleTarget = "\(article.title)"
            results.append(LinkCandidate(title: article.title, target: articleTarget))
            for section in article.sections.sorted(by: { $0.order < $1.order }) {
                let title = "\(article.title) - \(section.title)"
                let target = "\(article.title)#\(section.title)"
                results.append(LinkCandidate(title: title, target: target))
            }
        }

        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return results
        }

        return results.filter { candidate in
            candidate.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Display Text (optional)") {
                    TextField("Display text", text: $displayText)
                }

                Section("Internal Links") {
                    ForEach(candidates) { candidate in
                        Button {
                            onSelect(makeInternalLink(target: candidate.target))
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(candidate.title)
                                Text("[[\(candidate.target)]]")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section("External Link") {
                    TextField("https://example.com", text: $externalURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)

                    Button("Use External Link") {
                        onSelect(makeExternalLink(url: externalURL))
                        dismiss()
                    }
                    .disabled(!externalURL.lowercased().hasPrefix("http"))
                }
            }
            .navigationTitle("Link it")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func makeInternalLink(target: String) -> String {
        let display = displayText.trimmingCharacters(in: .whitespacesAndNewlines)
        if display.isEmpty {
            return "[[\(target)]]"
        }
        return "[[\(target)|\(display)]]"
    }

    private func makeExternalLink(url: String) -> String {
        let display = displayText.trimmingCharacters(in: .whitespacesAndNewlines)
        if display.isEmpty {
            return url
        }
        return "[\(display)](\(url))"
    }
}
