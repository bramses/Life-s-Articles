//
//  TableOfContentsView.swift
//  Life's Articles
//
//  Created by Bram Adams on 2/6/26.
//

import SwiftUI

struct TableOfContentsView: View {
    let sections: [ArticleSection]
    let showSummary: Bool
    let showInfobox: Bool
    let onSelect: (ScrollTarget) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if showSummary {
                    Button("Summary") {
                        onSelect(.summary)
                        dismiss()
                    }
                }

                if showInfobox {
                    Button("Info Box") {
                        onSelect(.infobox)
                        dismiss()
                    }
                }

                Section("Sections") {
                    ForEach(sections) { section in
                        Button(section.title.isEmpty ? "Section" : section.title) {
                            onSelect(.section(section.id))
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Contents")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
