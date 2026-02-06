//
//  GlobalSearchView.swift
//  Life's Articles
//
//  Created by Bram Adams on 2/6/26.
//

import SwiftUI

struct GlobalSearchView: View {
    let articles: [Article]
    let onSelect: (SearchResult) -> Void
    @State private var query = ""

    var body: some View {
        List {
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section("Type to search") {
                    Text("Search across titles, summaries, infoboxes, and sections.")
                        .foregroundColor(.secondary)
                }
            } else if results.isEmpty {
                Section("No results") {
                    Text("No matches found.")
                        .foregroundColor(.secondary)
                }
            } else {
                Section("Results") {
                    ForEach(results) { result in
                        Button {
                            onSelect(result)
                        } label: {
                            SearchResultRow(result: result)
                        }
                    }
                }
            }
        }
        .navigationTitle("Search")
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
    }

    private var results: [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var output: [SearchResult] = []
        for article in articles {
            output.append(contentsOf: search(in: article, query: trimmed))
        }
        return output
    }

    private func search(in article: Article, query: String) -> [SearchResult] {
        var matches: [SearchResult] = []

        if let snippet = snippetIfMatch(text: article.title, query: query) {
            matches.append(SearchResult(article: article, location: .title, snippet: snippet, query: query))
        }

        if let snippet = snippetIfMatch(text: article.summary, query: query) {
            matches.append(SearchResult(article: article, location: .summary, snippet: snippet, query: query))
        }

        for entry in article.infoboxEntries.sorted(by: { $0.order < $1.order }) {
            let combined = "\(entry.key): \(entry.value)"
            if let snippet = snippetIfMatch(text: combined, query: query) {
                matches.append(SearchResult(article: article, location: .infobox, snippet: snippet, query: query))
                break
            }
        }

        for section in article.sections.sorted(by: { $0.order < $1.order }) {
            let bodyText = "\(section.title)\n\(section.body)"
            if let snippet = snippetIfMatch(text: bodyText, query: query) {
                matches.append(SearchResult(article: article, location: .section(sectionID: section.id, title: section.title), snippet: snippet, query: query))
            }
        }

        return matches
    }

    private func snippetIfMatch(text: String, query: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let range = trimmed.range(of: query, options: .caseInsensitive) else { return nil }

        let start = trimmed.index(range.lowerBound, offsetBy: -30, limitedBy: trimmed.startIndex) ?? trimmed.startIndex
        let end = trimmed.index(range.upperBound, offsetBy: 30, limitedBy: trimmed.endIndex) ?? trimmed.endIndex
        let snippet = String(trimmed[start..<end])
        return snippet.replacingOccurrences(of: "\n", with: " ")
    }
}

struct SearchResultRow: View {
    let result: SearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(result.article.title.isEmpty ? "Untitled" : result.article.title)
                .font(.headline)

            Text(result.location.label)
                .font(.caption)
                .foregroundColor(.secondary)

            HighlightedText(text: result.snippet, query: result.query)
                .font(.subheadline)
        }
    }
}

struct HighlightedText: View {
    let text: String
    let query: String

    var body: some View {
        Text(attributedString)
    }

    private var attributedString: AttributedString {
        var attributed = AttributedString(text)
        if let range = attributed.range(of: query, options: .caseInsensitive) {
            attributed[range].backgroundColor = .yellow.opacity(0.35)
        }
        return attributed
    }
}

struct SearchResult: Identifiable {
    let id = UUID()
    let article: Article
    let location: SearchLocation
    let snippet: String
    let query: String

    var scrollTarget: ScrollTarget {
        switch location {
        case .title:
            return .summary
        case .summary:
            return .summary
        case .infobox:
            return .infobox
        case .section(let sectionID, _):
            return .section(sectionID)
        }
    }
}

enum SearchLocation: Hashable {
    case title
    case summary
    case infobox
    case section(sectionID: UUID, title: String)

    var label: String {
        switch self {
        case .title:
            return "Title"
        case .summary:
            return "Summary"
        case .infobox:
            return "Info Box"
        case .section(_, let title):
            return title.isEmpty ? "Section" : title
        }
    }
}

struct SearchSelection: Identifiable {
    let id = UUID()
    let article: Article
    let scrollTarget: ScrollTarget
    let highlightQuery: String
}
