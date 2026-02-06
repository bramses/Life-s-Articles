//
//  ArticleEditorView.swift
//  Life's Articles
//
//  Created by Bram Adams on 2/6/26.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import SwiftData
import UIKit

struct ArticleEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var article: Article
    let highlightQuery: String
    let scrollTarget: ScrollTarget?

    @State private var linkRequest: LinkRequest?
    @State private var showLinkPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showExporter = false
    @State private var isEditing = false
    @State private var didScrollToTarget = false
    @State private var requestedScrollTarget: ScrollTarget?
    @State private var linkedNavigation: LinkedNavigation?
    @State private var showTOC = false
    @State private var highlightTarget: ScrollTarget?
    @State private var showImageViewer = false

    init(article: Article, highlightQuery: String = "", scrollTarget: ScrollTarget? = nil) {
        self._article = Bindable(wrappedValue: article)
        self.highlightQuery = highlightQuery
        self.scrollTarget = scrollTarget
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if isEditing {
                        editHeader
                    } else {
                        readHeader
                    }

                    if isEditing {
                        editSummary
                            .id("summary")
                        editInfobox
                            .id("infobox")
                        editSections
                        editLinks
                    } else {
                        readSummary
                            .id("summary")
                        readInfobox
                            .id("infobox")
                        readSections
                        readLinks
                    }
                }
                .padding()
            }
            .navigationTitle(article.title.isEmpty ? "Untitled" : article.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !isEditing {
                        Button {
                            showTOC = true
                        } label: {
                            Label("Contents", systemImage: "list.bullet.rectangle")
                        }
                    }

                    Button {
                        showExporter = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }

                    Button(isEditing ? "Done" : "Edit") {
                        isEditing.toggle()
                    }
                }
            }
            .sheet(isPresented: $showLinkPicker) {
                LinkPickerView(
                    articles: allArticles().filter { !$0.isTemplate },
                    initialDisplayText: linkRequest?.selectedText ?? ""
                ) { target in
                    applyLink(target: target)
                }
            }
            .sheet(isPresented: $showImageViewer) {
                if let data = article.imageData, let uiImage = UIImage(data: data) {
                    ImageViewerView(image: uiImage)
                }
            }
            .sheet(isPresented: $showTOC) {
                TableOfContentsView(
                    sections: article.sections.sorted(by: { $0.order < $1.order }),
                    showSummary: !article.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    showInfobox: !article.infoboxEntries.isEmpty
                ) { target in
                    requestedScrollTarget = target
                    showTOC = false
                }
            }
            .sheet(item: $linkedNavigation) { navigation in
                NavigationStack {
                    ArticleEditorView(article: navigation.article, highlightQuery: "", scrollTarget: navigation.scrollTarget)
                }
            }
            .fileExporter(
                isPresented: $showExporter,
                document: MarkdownDocument(text: MarkdownCodec.exportMarkdown(for: article)),
                contentType: UTType(filenameExtension: "md") ?? .plainText,
                defaultFilename: article.title.isEmpty ? "article" : article.title
            ) { _ in }
            .environment(\.openURL, OpenURLAction { url in
                handleOpenURL(url)
            })
            .onDisappear {
                article.updatedAt = Date()
            }
            .onAppear {
                scrollToTargetIfNeeded(proxy: proxy)
            }
            .onChange(of: requestedScrollTarget) { _, newValue in
                guard let newValue else { return }
                DispatchQueue.main.async {
                    withAnimation {
                        scroll(to: newValue, proxy: proxy)
                    }
                    requestedScrollTarget = nil
                }
            }
        }
    }

    private var readHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let data = article.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .cornerRadius(14)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showImageViewer = true
                    }
            }

            Text(article.title.isEmpty ? "Untitled" : article.title)
                .font(.system(size: 34, weight: .bold))

            Text(article.type.label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var editHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Title", text: $article.title)
                .font(.system(size: 32, weight: .bold))

            Picker("Type", selection: Binding(
                get: { article.type },
                set: { article.type = $0 }
            )) {
                ForEach(ArticleType.allCases) { type in
                    Text(type.label).tag(type)
                }
            }
            .pickerStyle(.segmented)

            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 120, height: 120)

                    if let data = article.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipped()
                            .cornerRadius(12)
                    } else {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    PhotosPicker("Choose Image", selection: $selectedPhoto, matching: .images)
                        .onChange(of: selectedPhoto) { _, newValue in
                            loadImage(from: newValue)
                        }

                    Button("Remove Image") {
                        article.imageData = nil
                        article.imageSource = ""
                        article.imageIsPlaceholder = true
                    }
                    .foregroundColor(.secondary)

                    TextField("Image alt text", text: $article.imageAlt)
                    TextField("Image caption", text: $article.imageCaption)
                }
            }
        }
    }

    private var readSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
        if !article.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            LinkStyledText(text: article.summary, query: highlightQuery, font: .body, isItalic: true)
        }
    }
    .sectionHighlight(isActive: highlightTarget == .summary)
    }

    private var editSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.headline)
            RichTextEditor(
                text: $article.summary,
                placeholder: "Write a short summary...",
                onRequestLink: { range, selectedText in
                    linkRequest = LinkRequest(location: .summary, range: range, selectedText: selectedText)
                    showLinkPicker = true
                }
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 140)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
        }
    }

    private var readInfobox: some View {
        let entries = article.infoboxEntries
            .filter { !$0.key.trimmingCharacters(in: .whitespaces).isEmpty || !$0.value.trimmingCharacters(in: .whitespaces).isEmpty }
            .sorted(by: { $0.order < $1.order })

        return Group {
            if !entries.isEmpty {
                InfoBoxView(entries: entries, query: highlightQuery)
            }
        }
        .sectionHighlight(isActive: highlightTarget == .infobox)
    }

    private var editInfobox: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Info Box")
                    .font(.headline)
                Spacer()
                Button("Add") {
                    addInfoboxEntry()
                }
            }

            ForEach(article.infoboxEntries.sorted(by: { $0.order < $1.order })) { entry in
                HStack {
                    TextField("Key", text: Binding(
                        get: { entry.key },
                        set: { entry.key = $0 }
                    ))
                    TextField("Value", text: Binding(
                        get: { entry.value },
                        set: { entry.value = $0 }
                    ))
                    Button {
                        removeInfoboxEntry(entry)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var readSections: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(article.sections.sorted(by: { $0.order < $1.order })) { section in
                VStack(alignment: .leading, spacing: 8) {
                    Text(section.title.isEmpty ? "Section" : section.title)
                        .font(.title3.bold())
                    if section.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("No content yet.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    } else {
                        LinkStyledText(text: section.body, query: highlightQuery, font: .body, isItalic: false)
                    }
                }
                .id(section.id)
                .sectionHighlight(isActive: highlightTarget == .section(section.id))
            }
        }
    }

    private var editSections: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sections")
                    .font(.headline)
                Spacer()
                Button("Add Section") {
                    addSection()
                }
            }

            ForEach(article.sections.sorted(by: { $0.order < $1.order })) { section in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("Section title", text: Binding(
                            get: { section.title },
                            set: { section.title = $0 }
                        ))
                        Button {
                            removeSection(section)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.secondary)
                        }
                    }

                    RichTextEditor(
                        text: Binding(
                            get: { section.body },
                            set: { section.body = $0 }
                        ),
                        placeholder: "Write here...",
                        onRequestLink: { range, selectedText in
                            linkRequest = LinkRequest(location: .section(section.id), range: range, selectedText: selectedText)
                            showLinkPicker = true
                        }
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 220)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                }
                .id(section.id)
            }
        }
    }

    private var readLinks: some View {
        let links = article.links.sorted(by: { $0.order < $1.order })

        return Group {
            if !links.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Links")
                        .font(.headline)
                    ForEach(links) { link in
                        if link.isExternal, let url = URL(string: link.target) {
                            Link(link.title.isEmpty ? link.target : link.title, destination: url)
                                .foregroundColor(.blue)
                        } else {
                            Button {
                                openInternalLink(internalTarget(link.target))
                            } label: {
                                Text(internalLinkLabel(link.target))
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var editLinks: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Links")
                    .font(.headline)
                Spacer()
                Button("Add Link") {
                    addLink()
                }
            }

            ForEach(article.links.sorted(by: { $0.order < $1.order })) { link in
                VStack(alignment: .leading, spacing: 6) {
                    TextField("Title", text: Binding(
                        get: { link.title },
                        set: { link.title = $0 }
                    ))
                    TextField("Target", text: Binding(
                        get: { link.target },
                        set: { link.target = $0 }
                    ))
                    HStack {
                        Spacer()
                        Button("Remove") {
                            removeLink(link)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
            }
        }
    }

    private func internalLinkLabel(_ target: String) -> String {
        var label = target
        if label.hasPrefix("[[") && label.hasSuffix("]]" ) {
            label = label.replacingOccurrences(of: "[[", with: "")
                .replacingOccurrences(of: "]]", with: "")
        }
        if label.contains("|") {
            let parts = label.split(separator: "|", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                let display = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                return display.isEmpty ? parts[0] : display
            }
        }
        if label.contains("#") {
            let parts = label.split(separator: "#", maxSplits: 1).map(String.init)
            return "\(parts[0]) - \(parts[1])"
        }
        return label
    }

    private func internalTarget(_ target: String) -> String {
        var value = target
        if value.hasPrefix("[[") && value.hasSuffix("]]" ) {
            value = value.replacingOccurrences(of: "[[", with: "")
                .replacingOccurrences(of: "]]", with: "")
        }
        if value.contains("|") {
            let parts = value.split(separator: "|", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                return parts[0]
            }
        }
        return value
    }

    private func addInfoboxEntry() {
        let nextOrder = (article.infoboxEntries.map { $0.order }.max() ?? -1) + 1
        article.infoboxEntries.append(InfoboxEntry(key: "", value: "", order: nextOrder))
    }

    private func removeInfoboxEntry(_ entry: InfoboxEntry) {
        article.infoboxEntries.removeAll { $0.id == entry.id }
    }

    private func addSection() {
        let nextOrder = (article.sections.map { $0.order }.max() ?? -1) + 1
        article.sections.append(ArticleSection(title: "Section", body: "", order: nextOrder))
    }

    private func removeSection(_ section: ArticleSection) {
        article.sections.removeAll { $0.id == section.id }
    }

    private func addLink() {
        let nextOrder = (article.links.map { $0.order }.max() ?? -1) + 1
        article.links.append(ArticleLink(title: "", target: "", order: nextOrder))
    }

    private func removeLink(_ link: ArticleLink) {
        article.links.removeAll { $0.id == link.id }
    }

    private func applyLink(target: String) {
        guard let linkRequest else { return }
        let replacement: String
        if target.lowercased().hasPrefix("http") {
            if linkRequest.selectedText.isEmpty {
                replacement = target
            } else {
                replacement = "[\(linkRequest.selectedText)](\(target))"
            }
        } else {
            replacement = target
        }

        switch linkRequest.location {
        case .summary:
            replaceText(in: &article.summary, range: linkRequest.range, replacement: replacement)
        case .section(let sectionID):
            guard let index = article.sections.firstIndex(where: { $0.id == sectionID }) else { return }
            replaceText(in: &article.sections[index].body, range: linkRequest.range, replacement: replacement)
        }

        self.linkRequest = nil
    }

    private func scrollToTargetIfNeeded(proxy: ScrollViewProxy) {
        guard let scrollTarget, !didScrollToTarget else { return }
        didScrollToTarget = true
        DispatchQueue.main.async {
            withAnimation {
                scroll(to: scrollTarget, proxy: proxy)
            }
        }
    }

    private func scroll(to target: ScrollTarget, proxy: ScrollViewProxy) {
        switch target {
        case .summary:
            proxy.scrollTo("summary", anchor: .top)
        case .infobox:
            proxy.scrollTo("infobox", anchor: .top)
        case .section(let sectionID):
            proxy.scrollTo(sectionID, anchor: .top)
        }
        animateHighlight(target)
    }

    private func animateHighlight(_ target: ScrollTarget) {
        highlightTarget = target
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if highlightTarget == target {
                highlightTarget = nil
            }
        }
    }

    private func handleOpenURL(_ url: URL) -> OpenURLAction.Result {
        guard url.scheme == "lifes" else {
            return .systemAction
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return .handled
        }

        let target = components.queryItems?.first(where: { $0.name == "target" })?.value ?? ""
        let decodedTarget = target.removingPercentEncoding ?? target
        openInternalLink(decodedTarget)
        return .handled
    }

    private func openInternalLink(_ target: String) {
        let trimmed = target.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let (articleTitle, sectionTitle) = splitInternalTarget(trimmed)

        if articleTitle.isEmpty || articleTitle.caseInsensitiveCompare(article.title) == .orderedSame {
            if let sectionTitle {
                if let sectionID = sectionIDForTitle(sectionTitle, in: article) {
                    requestedScrollTarget = .section(sectionID)
                } else {
                    requestedScrollTarget = .summary
                }
            } else {
                requestedScrollTarget = .summary
            }
            return
        }

        let all = allArticles().filter { !$0.isTemplate }
        guard let destination = all.first(where: { $0.title.caseInsensitiveCompare(articleTitle) == .orderedSame }) else { return }
        let targetSectionID = sectionTitle.flatMap { sectionIDForTitle($0, in: destination) }
        let destinationTarget = targetSectionID.map { ScrollTarget.section($0) } ?? .summary
        linkedNavigation = LinkedNavigation(article: destination, scrollTarget: destinationTarget)
    }

    private func splitInternalTarget(_ target: String) -> (String, String?) {
        if target.hasPrefix("#") {
            let section = String(target.dropFirst())
            let trimmedSection = section.trimmingCharacters(in: .whitespacesAndNewlines)
            return ("", trimmedSection.isEmpty ? nil : trimmedSection)
        }

        let parts = target.split(separator: "#", maxSplits: 1).map(String.init)
        if parts.count == 2 {
            let articleTitle = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let sectionTitle = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            return (articleTitle, sectionTitle.isEmpty ? nil : sectionTitle)
        }
        return (target.trimmingCharacters(in: .whitespacesAndNewlines), nil)
    }

    private func sectionIDForTitle(_ title: String, in article: Article) -> UUID? {
        article.sections.first(where: { $0.title.caseInsensitiveCompare(title) == .orderedSame })?.id
    }

    private func replaceText(in text: inout String, range: NSRange, replacement: String) {
        let nsText = text as NSString
        guard range.location + range.length <= nsText.length else { return }
        text = nsText.replacingCharacters(in: range, with: replacement)
    }

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    article.imageData = data
                    article.imageIsPlaceholder = false
                }
            }
        }
    }

    private func allArticles() -> [Article] {
        let fetch = FetchDescriptor<Article>()
        return (try? modelContext.fetch(fetch)) ?? []
    }
}

struct InfoBoxView: View {
    let entries: [InfoboxEntry]
    let query: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Info Box")
                .font(.headline)
            ForEach(entries) { entry in
                HStack(alignment: .top, spacing: 8) {
                    Text(entry.key)
                        .font(.callout.bold())
                        .frame(width: 110, alignment: .leading)
                    LinkStyledText(text: entry.value, query: query, font: .callout, isItalic: false)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.12)))
    }
}

struct LinkStyledText: View {
    let text: String
    let query: String
    let font: Font
    let isItalic: Bool

    var body: some View {
        Group {
            if isItalic {
                Text(attributedText)
                    .font(font)
                    .italic()
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(attributedText)
                    .font(font)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var attributedText: AttributedString {
        let styled = buildAttributedString(text)
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return AttributedString(styled)
        }
        return AttributedString(applyHighlight(to: styled, query: query))
    }

    private func buildAttributedString(_ text: String) -> NSMutableAttributedString {
        let tokens = tokenizeLinks(text)
        let output = NSMutableAttributedString()

        for token in tokens {
            switch token {
            case .text(let value):
                output.append(NSAttributedString(string: value, attributes: [.foregroundColor: UIColor.label]))
            case .external(title: let title, url: let url):
                let attributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.systemBlue,
                    .link: url
                ]
                output.append(NSAttributedString(string: title, attributes: attributes))
            case .internalLink(label: let label, target: let target):
                var attributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.systemBlue,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ]
                if let url = internalURL(for: target) {
                    attributes[.link] = url
                }
                output.append(NSAttributedString(string: label, attributes: attributes))
            }
        }

        return output
    }

    private func applyHighlight(to text: NSMutableAttributedString, query: String) -> NSMutableAttributedString {
        let nsText = text.string as NSString
        var searchRange = NSRange(location: 0, length: nsText.length)
        while searchRange.location < nsText.length {
            let foundRange = nsText.range(of: query, options: .caseInsensitive, range: searchRange)
            if foundRange.location == NSNotFound { break }
            text.addAttribute(.backgroundColor, value: UIColor.systemYellow.withAlphaComponent(0.35), range: foundRange)
            searchRange = NSRange(location: foundRange.location + foundRange.length, length: nsText.length - (foundRange.location + foundRange.length))
        }
        return text
    }

    private enum LinkToken {
        case text(String)
        case external(title: String, url: String)
        case internalLink(label: String, target: String)
    }

    private func tokenizeLinks(_ text: String) -> [LinkToken] {
        let nsText = text as NSString
        let externalPattern = "\\[(.*?)\\]\\((https?://[^\\s\\)]+)\\)"
        let internalPattern = "\\[\\[(.*?)\\]\\]"

        let externalRegex = try? NSRegularExpression(pattern: externalPattern, options: [])
        let internalRegex = try? NSRegularExpression(pattern: internalPattern, options: [])

        var tokens: [LinkToken] = []
        var index = 0

        while index < nsText.length {
            let remainingRange = NSRange(location: index, length: nsText.length - index)
            let externalMatch = externalRegex?.firstMatch(in: text, options: [], range: remainingRange)
            let internalMatch = internalRegex?.firstMatch(in: text, options: [], range: remainingRange)

            let nextMatch = earliestMatch(externalMatch, internalMatch)
            guard let (match, isExternal) = nextMatch else {
                let tail = nsText.substring(with: remainingRange)
                tokens.append(.text(tail))
                break
            }

            if match.range.location > index {
                let prefixRange = NSRange(location: index, length: match.range.location - index)
                tokens.append(.text(nsText.substring(with: prefixRange)))
            }

            if isExternal, match.numberOfRanges >= 3 {
                let titleRange = match.range(at: 1)
                let urlRange = match.range(at: 2)
                let title = nsText.substring(with: titleRange)
                let url = nsText.substring(with: urlRange)
                tokens.append(.external(title: title, url: url))
            } else if match.numberOfRanges >= 2 {
                let labelRange = match.range(at: 1)
                let label = nsText.substring(with: labelRange)
                let (target, display) = parseInternalLabel(label)
                tokens.append(.internalLink(label: display, target: target))
            }

            index = match.range.location + match.range.length
        }

        return tokens
    }

    private func earliestMatch(_ external: NSTextCheckingResult?, _ internalMatch: NSTextCheckingResult?) -> (NSTextCheckingResult, Bool)? {
        switch (external, internalMatch) {
        case (nil, nil):
            return nil
        case (let match?, nil):
            return (match, true)
        case (nil, let match?):
            return (match, false)
        case (let externalMatch?, let internalMatch?):
            return externalMatch.range.location <= internalMatch.range.location
                ? (externalMatch, true)
                : (internalMatch, false)
        }
    }

    private func parseInternalLabel(_ label: String) -> (String, String) {
        var target = label.trimmingCharacters(in: .whitespacesAndNewlines)
        var display = label.trimmingCharacters(in: .whitespacesAndNewlines)

        if label.contains("|") {
            let parts = label.split(separator: "|", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                target = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                display = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        if display.isEmpty {
            display = target
        }

        if display.contains("#") {
            let parts = display.split(separator: "#", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                display = "\(parts[0]) - \(parts[1])"
            }
        }

        return (target, display)
    }

    private func internalURL(for target: String) -> URL? {
        var components = URLComponents()
        components.scheme = "lifes"
        components.host = "internal"
        components.queryItems = [URLQueryItem(name: "target", value: target)]
        return components.url
    }
}

struct LinkRequest {
    enum Location {
        case summary
        case section(UUID)
    }

    let location: Location
    let range: NSRange
    let selectedText: String
}

enum ScrollTarget: Hashable {
    case summary
    case infobox
    case section(UUID)
}

struct LinkedNavigation: Identifiable {
    let id = UUID()
    let article: Article
    let scrollTarget: ScrollTarget?
}

struct MarkdownDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [UTType(filenameExtension: "md") ?? .plainText, .plainText]
    }

    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        } else {
            text = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return .init(regularFileWithContents: data)
    }
}

struct SectionHighlightModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.yellow.opacity(isActive ? 0.25 : 0))
            )
            .animation(.easeInOut(duration: 0.35), value: isActive)
    }
}

extension View {
    func sectionHighlight(isActive: Bool) -> some View {
        modifier(SectionHighlightModifier(isActive: isActive))
    }
}
