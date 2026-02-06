# Life's Articles

Life's Articles is an iOS app for creating a personal, Wikipedia-like archive of people, places, and things in your life. Each article supports sections, an infobox, images, internal links, and Markdown import/export.

## Features
- Wikipedia-style read view with sections and infobox
- Edit mode with section text editing and link creation
- Internal links with `[[Article#Section|Display Text]]`
- Global search across all articles
- Gallery view of article covers
- Markdown template import and export

## App Structure
- `Life's Articles/` SwiftUI app source
- `Life's Articles/Models/ArticleModels.swift` SwiftData models
- `Life's Articles/ArticleEditorView.swift` Read/edit article view
- `Life's Articles/MarkdownCodec.swift` Markdown import/export
- `Life's Articles/GlobalSearchView.swift` Cross-article search
- `Life's Articles/Assets.xcassets/` App assets and icon
- `MarkdownTemplateSpec.md` Template format specification

## Build & Run
Open `Life's Articles.xcodeproj` in Xcode and run the `Life's Articles` target on an iOS simulator or device.

## Markdown Templates
See `MarkdownTemplateSpec.md` for the template format and examples.

## Notes
- Templates are only shown when creating a new article.
- App icon lives in `Life's Articles/Assets.xcassets/AppIcon.appiconset/`.
