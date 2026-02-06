# Life's Articles Template Markdown Specification

## Overview
This document defines the standard Markdown format for Life's Articles templates and exported articles. The goals are:
- Let users import a template from Markdown.
- Let users create or edit a template in Markdown and export it back.
- Ensure the app can round-trip content without losing structure.

The format uses plain Markdown with optional YAML front matter, plus a few structured conventions for infoboxes, links, and internal link targets.

## File Format
- Encoding: UTF-8.
- Line endings: LF preferred, CRLF accepted.
- Optional YAML front matter between `---` lines.
- Body in GitHub-flavored Markdown (GFM).

## Front Matter (Optional but Recommended)
If present, front matter MUST be valid YAML. The app should treat `schema` and `mode` as authoritative.

### Required for templates
- `schema`: `lifes-articles-template-v1`
- `mode`: `template`

### Required for exported articles
- `schema`: `lifes-articles-template-v1`
- `mode`: `article`

### Common fields
- `title`: string
- `type`: `person` | `place` | `thing` | `other`
- `image`: object
  - `source`: string (URL, asset id, or empty for placeholder)
  - `alt`: string
  - `caption`: string
  - `placeholder`: boolean
- `infobox`: array of objects
  - `key`: string
  - `value`: string
- `links`: array of objects
  - `title`: string
  - `target`: string
    - Internal: `[[Article Title]]`, `[[Article Title#Section]]`, or `[[#Section]]`
    - External: URL (https://...)
- `tags`: array of strings
- `id`: string (stable identifier, optional)
- `created`: ISO-8601 date-time string (optional)
- `updated`: ISO-8601 date-time string (optional)

## Body Structure (Canonical Order)
The body SHOULD follow this order for best round-tripping. The app should parse regardless of order where possible.

1. `# Title` (H1)
2. Image block (Markdown image)
3. Summary (blockquote)
4. Infobox block (fenced block)
5. Sections (H2 and below)
6. Link box section (H2 titled `Links`)

### Title
- The H1 should match front matter `title` when both exist.

### Image Block
Use standard Markdown image syntax:

```
![Alt text](source)
```

#### Placeholder image
If the template needs a placeholder image, use:

```
![Image](placeholder://image)
```

The app should treat `placeholder://image` as an empty image slot.

### Summary
A single-paragraph blockquote is used as the summary/lead:

```
> Short summary text.
```

If there is no summary, the blockquote may be omitted.

### Infobox Block
Use a fenced block with the info box key/value pairs:

```
```infobox
Key: Value
Key 2: Value
```
```

- Keys and values are separated by the first `:` on each line.
- Empty values are allowed for templates.

### Sections
- Main sections must be H2 (`##`).
- Subsections may use H3/H4.

### Link Box
Add a `## Links` section with a list of links. Example:

```
## Links
- [[Article Title]]
- [[Article Title#Early life]]
- [External Site](https://example.com)
```

The app should treat this section as the "link box".

## Internal Links
Use double-bracket links for internal navigation:
- `[[Article Title]]` links to another article.
- `[[Article Title#Section]]` links to a specific section.
- `[[#Section]]` links to a section within the current article.
- `[[Article Title#Section|Display Text]]` links to a section with custom display text.

Section matching should be case-insensitive and ignore extra whitespace. The app should export exact section headings to keep links stable.

## Import Rules
- If front matter exists and `schema` matches, parse it first.
- If front matter is missing, infer structure from the body.
- If both front matter and body provide `title`, `image`, `infobox`, or `links`, prefer the body, but keep front matter values if the body is missing that element.

## Export Rules
- Always include front matter with `schema` and `mode`.
- Export a canonical body with H1 title, image, summary, infobox block, sections, and `## Links`.
- Internal links should be exported using the `[[...]]` syntax.

## Examples

### Template Example
```
---
schema: lifes-articles-template-v1
mode: template
title: "Person"
type: person
image:
  source: ""
  alt: ""
  caption: ""
  placeholder: true
infobox:
  - key: "Born"
    value: ""
  - key: "Occupation"
    value: ""
---
# Person
![Image](placeholder://image)
> 

```infobox
Born:
Occupation:
```

## Early Life
Write about early life.

## Career
Write about career.

## Links
- [[Related Article]]
- [Official Site](https://example.com)
```

### Article Export Example
```
---
schema: lifes-articles-template-v1
mode: article
title: "Ada Lovelace"
type: person
image:
  source: "asset://images/ada-lovelace.jpg"
  alt: "Ada Lovelace"
  caption: "Portrait of Ada Lovelace"
  placeholder: false
infobox:
  - key: "Born"
    value: "December 10, 1815"
  - key: "Known for"
    value: "Analytical Engine notes"
links:
  - title: "Charles Babbage"
    target: "[[Charles Babbage]]"
  - title: "Biography"
    target: "https://example.com/ada"
---
# Ada Lovelace
![Ada Lovelace](asset://images/ada-lovelace.jpg)
> English mathematician and writer, chiefly known for her work on the Analytical Engine.

```infobox
Born: December 10, 1815
Known for: Analytical Engine notes
```

## Early Life
Text...

## Work
Text...

## Links
- [[Charles Babbage]]
- [Biography](https://example.com/ada)
```
