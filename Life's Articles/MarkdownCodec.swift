//
//  MarkdownCodec.swift
//  Life's Articles
//
//  Created by Bram Adams on 2/6/26.
//

import Foundation

struct MarkdownCodec {
    static let schema = "lifes-articles-template-v1"

    struct ParsedArticle {
        var title: String
        var summary: String
        var type: ArticleType
        var imageSource: String
        var imageAlt: String
        var imageCaption: String
        var imageIsPlaceholder: Bool
        var sections: [ArticleSection]
        var infoboxEntries: [InfoboxEntry]
        var links: [ArticleLink]
        var isTemplate: Bool
    }

    static func exportMarkdown(for article: Article) -> String {
        let mode = article.isTemplate ? "template" : "article"
        let safeTitle = escapeYaml(article.title)
        let safeAlt = escapeYaml(article.imageAlt)
        let safeCaption = escapeYaml(article.imageCaption)
        let imageSource = article.imageSource.isEmpty ? (article.imageIsPlaceholder ? "" : "asset://local/\(article.id.uuidString)") : article.imageSource

        var yaml: [String] = []
        yaml.append("---")
        yaml.append("schema: \(schema)")
        yaml.append("mode: \(mode)")
        yaml.append("title: \"\(safeTitle)\"")
        yaml.append("type: \(article.type.rawValue)")
        yaml.append("image:")
        yaml.append("  source: \"\(escapeYaml(imageSource))\"")
        yaml.append("  alt: \"\(safeAlt)\"")
        yaml.append("  caption: \"\(safeCaption)\"")
        yaml.append("  placeholder: \(article.imageIsPlaceholder ? "true" : "false")")

        if !article.infoboxEntries.isEmpty {
            yaml.append("infobox:")
            for entry in article.infoboxEntries.sorted(by: { $0.order < $1.order }) {
                yaml.append("  - key: \"\(escapeYaml(entry.key))\"")
                yaml.append("    value: \"\(escapeYaml(entry.value))\"")
            }
        }

        if !article.links.isEmpty {
            yaml.append("links:")
            for link in article.links.sorted(by: { $0.order < $1.order }) {
                yaml.append("  - title: \"\(escapeYaml(link.title))\"")
                yaml.append("    target: \"\(escapeYaml(link.target))\"")
            }
        }

        yaml.append("---")

        var body: [String] = []
        body.append("# \(article.title.isEmpty ? "Untitled" : article.title)")

        let imageLine: String
        if article.imageIsPlaceholder || (article.imageSource.isEmpty && article.imageData == nil) {
            imageLine = "![Image](placeholder://image)"
        } else {
            let source = article.imageSource.isEmpty ? "asset://local/\(article.id.uuidString)" : article.imageSource
            let alt = article.imageAlt.isEmpty ? article.title : article.imageAlt
            imageLine = "![\(alt)](\(source))"
        }
        body.append(imageLine)

        if !article.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            body.append("> \(article.summary)")
        }

        if !article.infoboxEntries.isEmpty {
            body.append("")
            body.append("```infobox")
            for entry in article.infoboxEntries.sorted(by: { $0.order < $1.order }) {
                body.append("\(entry.key): \(entry.value)")
            }
            body.append("```")
        }

        for section in article.sections.sorted(by: { $0.order < $1.order }) {
            body.append("")
            body.append("## \(section.title.isEmpty ? "Section" : section.title)")
            body.append(section.body)
        }

        if !article.links.isEmpty {
            body.append("")
            body.append("## Links")
            for link in article.links.sorted(by: { $0.order < $1.order }) {
                if link.isExternal {
                    let title = link.title.isEmpty ? link.target : link.title
                    body.append("- [\(title)](\(link.target))")
                } else {
                    body.append("- \(link.target)")
                }
            }
        }

        return (yaml + body).joined(separator: "\n")
    }

    static func parseMarkdown(_ markdown: String) -> ParsedArticle {
        let trimmed = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        let (frontMatter, body) = extractFrontMatter(from: trimmed)

        var title = ""
        var summary = ""
        var type: ArticleType = .other
        var imageSource = ""
        var imageAlt = ""
        var imageCaption = ""
        var imageIsPlaceholder = true
        var isTemplate = false

        if let frontMatter {
            let lines = frontMatter.components(separatedBy: "\n")
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                if trimmedLine.hasPrefix("title:") {
                    title = valueAfterColon(trimmedLine)
                } else if trimmedLine.hasPrefix("type:") {
                    let raw = valueAfterColon(trimmedLine)
                    type = ArticleType(rawValue: raw) ?? .other
                } else if trimmedLine.hasPrefix("mode:") {
                    let mode = valueAfterColon(trimmedLine)
                    isTemplate = mode == "template"
                } else if trimmedLine.hasPrefix("source:") {
                    imageSource = valueAfterColon(trimmedLine)
                } else if trimmedLine.hasPrefix("alt:") {
                    imageAlt = valueAfterColon(trimmedLine)
                } else if trimmedLine.hasPrefix("caption:") {
                    imageCaption = valueAfterColon(trimmedLine)
                } else if trimmedLine.hasPrefix("placeholder:") {
                    imageIsPlaceholder = valueAfterColon(trimmedLine).lowercased() == "true"
                }
            }
        }

        let bodyLines = body.components(separatedBy: "\n")
        if title.isEmpty, let firstTitle = bodyLines.first(where: { $0.hasPrefix("# ") }) {
            title = String(firstTitle.dropFirst(2))
        }

        if let match = firstMatch(pattern: "!\\[(.*?)\\]\\((.*?)\\)", in: body) {
            imageAlt = match[1]
            imageSource = match[2]
            imageIsPlaceholder = imageSource == "placeholder://image"
        }

        if let summaryLine = bodyLines.first(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("> ") }) {
            summary = summaryLine.replacingOccurrences(of: "> ", with: "")
        }

        var infoboxEntries: [InfoboxEntry] = []
        if let infoboxBlock = fencedBlock(named: "infobox", in: body) {
            let lines = infoboxBlock.components(separatedBy: "\n")
            var order = 0
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                guard !trimmedLine.isEmpty else { continue }
                let parts = trimmedLine.split(separator: ":", maxSplits: 1).map(String.init)
                let key = parts.first?.trimmingCharacters(in: .whitespaces) ?? ""
                let value = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : ""
                infoboxEntries.append(InfoboxEntry(key: key, value: value, order: order))
                order += 1
            }
        }

        let (sections, links) = parseSectionsAndLinks(from: body)

        return ParsedArticle(
            title: title,
            summary: summary,
            type: type,
            imageSource: imageSource,
            imageAlt: imageAlt,
            imageCaption: imageCaption,
            imageIsPlaceholder: imageIsPlaceholder,
            sections: sections,
            infoboxEntries: infoboxEntries,
            links: links,
            isTemplate: isTemplate
        )
    }

    private static func extractFrontMatter(from text: String) -> (String?, String) {
        guard text.hasPrefix("---") else { return (nil, text) }
        let parts = text.components(separatedBy: "\n")
        var frontMatterLines: [String] = []
        var bodyLines: [String] = []
        var isInFrontMatter = false
        var encounteredFirst = false

        for line in parts {
            if line.trimmingCharacters(in: .whitespacesAndNewlines) == "---" {
                if !encounteredFirst {
                    encounteredFirst = true
                    isInFrontMatter = true
                    continue
                } else if isInFrontMatter {
                    isInFrontMatter = false
                    continue
                }
            }

            if isInFrontMatter {
                frontMatterLines.append(line)
            } else {
                bodyLines.append(line)
            }
        }

        let frontMatter = frontMatterLines.isEmpty ? nil : frontMatterLines.joined(separator: "\n")
        return (frontMatter, bodyLines.joined(separator: "\n"))
    }

    private static func parseSectionsAndLinks(from body: String) -> ([ArticleSection], [ArticleLink]) {
        let lines = body.components(separatedBy: "\n")
        var sections: [ArticleSection] = []
        var links: [ArticleLink] = []

        var currentTitle: String? = nil
        var currentBody: [String] = []
        var order = 0
        var linkOrder = 0

        func flushSection() {
            guard let title = currentTitle else { return }
            let bodyText = currentBody.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if title.lowercased() == "links" {
                parseLinks(from: bodyText, into: &links, order: &linkOrder)
            } else {
                sections.append(ArticleSection(title: title, body: bodyText, order: order))
                order += 1
            }
            currentTitle = nil
            currentBody = []
        }

        for line in lines {
            if line.hasPrefix("## ") {
                flushSection()
                currentTitle = String(line.dropFirst(3))
                continue
            }

            if currentTitle != nil {
                currentBody.append(line)
            }
        }

        flushSection()
        return (sections, links)
    }

    private static func parseLinks(from body: String, into links: inout [ArticleLink], order: inout Int) {
        let lines = body.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("- ") else { continue }
            let item = trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces)

            if item.hasPrefix("[[") && item.hasSuffix("]]" ) {
                let target = String(item)
                let inner = target
                    .replacingOccurrences(of: "[[", with: "")
                    .replacingOccurrences(of: "]]", with: "")
                let title: String
                if inner.contains("|") {
                    let parts = inner.split(separator: "|", maxSplits: 1).map(String.init)
                    title = parts.count == 2 ? parts[1] : inner
                } else {
                    title = inner
                }
                links.append(ArticleLink(title: title, target: target, order: order))
                order += 1
                continue
            }

            if let match = firstMatch(pattern: "\\[(.*?)\\]\\((.*?)\\)", in: String(item)) {
                let title = match[1]
                let target = match[2]
                links.append(ArticleLink(title: title, target: target, order: order))
                order += 1
            }
        }
    }

    private static func fencedBlock(named name: String, in text: String) -> String? {
        let startToken = "```\(name)"
        guard let startRange = text.range(of: startToken) else { return nil }
        let afterStart = text[startRange.upperBound...]
        guard let endRange = afterStart.range(of: "```") else { return nil }
        let block = afterStart[..<endRange.lowerBound]
        return block.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func firstMatch(pattern: String, in text: String) -> [String]? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            guard let match = regex.firstMatch(in: text, options: [], range: range) else { return nil }
            var results: [String] = []
            for index in 0..<match.numberOfRanges {
                let range = match.range(at: index)
                if let swiftRange = Range(range, in: text) {
                    results.append(String(text[swiftRange]))
                }
            }
            return results
        } catch {
            return nil
        }
    }

    private static func valueAfterColon(_ line: String) -> String {
        guard let range = line.range(of: ":") else { return "" }
        let value = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
        return stripQuotes(String(value))
    }

    private static func stripQuotes(_ value: String) -> String {
        var result = value
        if result.hasPrefix("\"") && result.hasSuffix("\"") {
            result = String(result.dropFirst().dropLast())
        }
        return result
    }

    private static func escapeYaml(_ value: String) -> String {
        value.replacingOccurrences(of: "\"", with: "\\\"")
    }
}
