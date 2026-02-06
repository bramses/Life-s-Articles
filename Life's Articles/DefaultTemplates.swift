//
//  DefaultTemplates.swift
//  Life's Articles
//
//  Created by Bram Adams on 2/6/26.
//

import Foundation

struct DefaultTemplates {
    static func personTemplate() -> Article {
        let sections = [
            ArticleSection(title: "Early Life", body: "", order: 0),
            ArticleSection(title: "Career", body: "", order: 1),
            ArticleSection(title: "Personal Life", body: "", order: 2)
        ]

        let infobox = [
            InfoboxEntry(key: "Born", value: "", order: 0),
            InfoboxEntry(key: "Occupation", value: "", order: 1),
            InfoboxEntry(key: "Known for", value: "", order: 2)
        ]

        return Article(
            title: "Person",
            summary: "",
            type: .person,
            imageSource: "",
            imageAlt: "",
            imageCaption: "",
            imageIsPlaceholder: true,
            isTemplate: true,
            sections: sections,
            infoboxEntries: infobox,
            links: []
        )
    }

    static func placeTemplate() -> Article {
        let sections = [
            ArticleSection(title: "History", body: "", order: 0),
            ArticleSection(title: "Geography", body: "", order: 1),
            ArticleSection(title: "Culture", body: "", order: 2)
        ]

        let infobox = [
            InfoboxEntry(key: "Location", value: "", order: 0),
            InfoboxEntry(key: "Founded", value: "", order: 1)
        ]

        return Article(
            title: "Place",
            summary: "",
            type: .place,
            imageSource: "",
            imageAlt: "",
            imageCaption: "",
            imageIsPlaceholder: true,
            isTemplate: true,
            sections: sections,
            infoboxEntries: infobox,
            links: []
        )
    }

    static func thingTemplate() -> Article {
        let sections = [
            ArticleSection(title: "Overview", body: "", order: 0),
            ArticleSection(title: "Details", body: "", order: 1)
        ]

        let infobox = [
            InfoboxEntry(key: "Type", value: "", order: 0),
            InfoboxEntry(key: "Created", value: "", order: 1)
        ]

        return Article(
            title: "Thing",
            summary: "",
            type: .thing,
            imageSource: "",
            imageAlt: "",
            imageCaption: "",
            imageIsPlaceholder: true,
            isTemplate: true,
            sections: sections,
            infoboxEntries: infobox,
            links: []
        )
    }

    static func makeAll() -> [Article] {
        [personTemplate(), placeTemplate(), thingTemplate()]
    }
}
