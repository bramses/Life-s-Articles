//
//  ArticleModels.swift
//  Life's Articles
//
//  Created by Bram Adams on 2/6/26.
//

import Foundation
import SwiftData

enum ArticleType: String, CaseIterable, Identifiable {
    case person
    case place
    case thing
    case other

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }
}

@Model
final class Article {
    @Attribute(.unique) var id: UUID
    var title: String
    var summary: String
    var typeRawValue: String

    var imageSource: String
    var imageAlt: String
    var imageCaption: String
    var imageIsPlaceholder: Bool
    var imageData: Data?

    var isTemplate: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade) var sections: [ArticleSection]
    @Relationship(deleteRule: .cascade) var infoboxEntries: [InfoboxEntry]
    @Relationship(deleteRule: .cascade) var links: [ArticleLink]

    init(
        id: UUID = UUID(),
        title: String = "",
        summary: String = "",
        type: ArticleType = .other,
        imageSource: String = "",
        imageAlt: String = "",
        imageCaption: String = "",
        imageIsPlaceholder: Bool = true,
        imageData: Data? = nil,
        isTemplate: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sections: [ArticleSection] = [],
        infoboxEntries: [InfoboxEntry] = [],
        links: [ArticleLink] = []
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.typeRawValue = type.rawValue
        self.imageSource = imageSource
        self.imageAlt = imageAlt
        self.imageCaption = imageCaption
        self.imageIsPlaceholder = imageIsPlaceholder
        self.imageData = imageData
        self.isTemplate = isTemplate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sections = sections
        self.infoboxEntries = infoboxEntries
        self.links = links
    }

    var type: ArticleType {
        get { ArticleType(rawValue: typeRawValue) ?? .other }
        set { typeRawValue = newValue.rawValue }
    }
}

@Model
final class ArticleSection {
    @Attribute(.unique) var id: UUID
    var title: String
    var body: String
    var order: Int

    init(id: UUID = UUID(), title: String = "", body: String = "", order: Int = 0) {
        self.id = id
        self.title = title
        self.body = body
        self.order = order
    }
}

@Model
final class InfoboxEntry {
    @Attribute(.unique) var id: UUID
    var key: String
    var value: String
    var order: Int

    init(id: UUID = UUID(), key: String = "", value: String = "", order: Int = 0) {
        self.id = id
        self.key = key
        self.value = value
        self.order = order
    }
}

@Model
final class ArticleLink {
    @Attribute(.unique) var id: UUID
    var title: String
    var target: String
    var order: Int

    init(id: UUID = UUID(), title: String = "", target: String = "", order: Int = 0) {
        self.id = id
        self.title = title
        self.target = target
        self.order = order
    }

    var isExternal: Bool {
        target.lowercased().hasPrefix("http://") || target.lowercased().hasPrefix("https://")
    }
}
