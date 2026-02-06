//
//  ContentView.swift
//  Life's Articles
//
//  Created by Bram Adams on 2/6/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Article.updatedAt, order: .reverse) private var articles: [Article]

    @State private var showingCreator = false
    @State private var showingImporter = false
    @State private var importError: String?
    @State private var searchSelection: SearchSelection?

    var body: some View {
        TabView {
            NavigationStack {
                GalleryView(articles: articles.filter { !$0.isTemplate })
                    .navigationTitle("Gallery")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingCreator = true
                            } label: {
                                Label("New Article", systemImage: "plus")
                            }
                        }

                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                showingImporter = true
                            } label: {
                                Label("Import", systemImage: "square.and.arrow.down")
                            }
                        }
                    }
                    .sheet(isPresented: $showingCreator) {
                        NewArticleSheet(templates: articles.filter { $0.isTemplate }, onCreate: { newArticle in
                            modelContext.insert(newArticle)
                        })
                    }
                    .fileImporter(
                        isPresented: $showingImporter,
                        allowedContentTypes: [UTType(filenameExtension: "md") ?? .plainText, .plainText],
                        allowsMultipleSelection: false
                    ) { result in
                        handleImport(result)
                    }
                    .alert("Import failed", isPresented: Binding(get: { importError != nil }, set: { _ in importError = nil })) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text(importError ?? "Unknown error")
                    }
                    .onAppear {
                        seedTemplatesIfNeeded()
                    }
            }
            .tabItem {
                Label("Gallery", systemImage: "square.grid.2x2")
            }

            NavigationStack {
                GlobalSearchView(articles: articles.filter { !$0.isTemplate }) { result in
                    searchSelection = SearchSelection(article: result.article, scrollTarget: result.scrollTarget, highlightQuery: result.query)
                }
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
        }
        .sheet(item: $searchSelection) { selection in
            NavigationStack {
                ArticleEditorView(article: selection.article, highlightQuery: selection.highlightQuery, scrollTarget: selection.scrollTarget)
            }
        }
    }

    private func seedTemplatesIfNeeded() {
        guard articles.filter({ $0.isTemplate }).isEmpty else { return }
        DefaultTemplates.makeAll().forEach { modelContext.insert($0) }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        do {
            let url = try result.get().first
            guard let url else { return }
            let data = try Data(contentsOf: url)
            guard let text = String(data: data, encoding: .utf8) else {
                importError = "Unsupported file encoding."
                return
            }

            let parsed = MarkdownCodec.parseMarkdown(text)
            let article = Article(
                title: parsed.title,
                summary: parsed.summary,
                type: parsed.type,
                imageSource: parsed.imageSource,
                imageAlt: parsed.imageAlt,
                imageCaption: parsed.imageCaption,
                imageIsPlaceholder: parsed.imageIsPlaceholder,
                isTemplate: parsed.isTemplate,
                sections: parsed.sections,
                infoboxEntries: parsed.infoboxEntries,
                links: parsed.links
            )
            modelContext.insert(article)
        } catch {
            importError = error.localizedDescription
        }
    }
}

struct GalleryView: View {
    let articles: [Article]
    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(articles) { article in
                    NavigationLink {
                        ArticleEditorView(article: article)
                    } label: {
                        GalleryCard(article: article)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Gallery")
    }
}

struct GalleryCard: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 120)

                if let data = article.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                }
            }

            Text(article.title.isEmpty ? "Untitled" : article.title)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
}

struct NewArticleSheet: View {
    let templates: [Article]
    let onCreate: (Article) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Start from Scratch") {
                    Button("Blank Article") {
                        onCreate(blankArticle())
                        dismiss()
                    }
                }

                if !templates.isEmpty {
                    Section("Templates") {
                        ForEach(templates) { template in
                            Button(templateTitle(template)) {
                                onCreate(clone(template: template))
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Article")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func clone(template: Article) -> Article {
        let sections = template.sections
            .sorted(by: { $0.order < $1.order })
            .enumerated()
            .map { index, section in
                ArticleSection(title: section.title, body: section.body, order: index)
            }

        let infobox = template.infoboxEntries
            .sorted(by: { $0.order < $1.order })
            .enumerated()
            .map { index, entry in
                InfoboxEntry(key: entry.key, value: entry.value, order: index)
            }

        let links = template.links
            .sorted(by: { $0.order < $1.order })
            .enumerated()
            .map { index, link in
                ArticleLink(title: link.title, target: link.target, order: index)
            }

        return Article(
            title: "",
            summary: "",
            type: template.type,
            imageSource: template.imageSource,
            imageAlt: template.imageAlt,
            imageCaption: template.imageCaption,
            imageIsPlaceholder: template.imageIsPlaceholder,
            isTemplate: false,
            sections: sections,
            infoboxEntries: infobox,
            links: links
        )
    }

    private func templateTitle(_ template: Article) -> String {
        if !template.title.isEmpty {
            return template.title
        }
        return template.type.label
    }

    private func blankArticle() -> Article {
        Article(
            title: "",
            summary: "",
            type: .other,
            isTemplate: false,
            sections: [ArticleSection(title: "Overview", body: "", order: 0)]
        )
    }
}

#Preview {
    let schema = Schema([
        Article.self,
        ArticleSection.self,
        InfoboxEntry.self,
        ArticleLink.self
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    return ContentView()
        .modelContainer(container)
}
