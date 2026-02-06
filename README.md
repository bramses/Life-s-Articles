# Life's Articles

Life's Articles is an iOS app for creating a personal, Wikipedia-like archive of people, places, and things in your life. Each article supports sections, an infobox, images, internal links, and Markdown import/export.

<p>
  <img src="https://github.com/user-attachments/assets/eeec76d5-e9e1-44aa-a744-6586fcb1691c" width="200" />
  <img src="https://github.com/user-attachments/assets/13c376c3-48ed-4cc8-b205-de3e38b788ee" width="200" />
  <img src="https://github.com/user-attachments/assets/c7565430-bc37-4947-a34f-5c6718315f9d" width="200" />
  <img src="https://github.com/user-attachments/assets/e3add8b3-daac-4237-b96a-e1cc0d55a1f1" width="200" />
  <img src="https://github.com/user-attachments/assets/9abe7617-8429-472c-b9b6-6a99d1609534" width="200" />
  <img src="https://github.com/user-attachments/assets/e134a42a-eaf4-431a-b7bb-7decb2c860c9" width="200" />
  <img src="https://github.com/user-attachments/assets/96e4327a-d644-451a-a108-bb0b60067873" width="200" />
  <img src="https://github.com/user-attachments/assets/e56a794f-9a5b-4d6c-b12b-a9ec1ae87e8d" width="200" />
</p>

![Platform](https://img.shields.io/badge/platform-iOS%2017.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)



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
