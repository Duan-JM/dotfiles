---
name: swift-documentation
description: Writes and publishes Swift / SwiftUI documentation using DocC — symbol comments, articles, tutorials, code samples, asset references, and docc preview/build. Use when documenting a Swift package, generating an API reference, or building a documentation site for a library.
---

# Swift Documentation (DocC)

## Symbol documentation

Use triple-slash comments on every public symbol. Keep them concise and behavioral:

```swift
/// Encodes a coordinate as a geohash string.
///
/// - Parameters:
///   - latitude: Latitude in degrees, in the range `-90...90`.
///   - longitude: Longitude in degrees, in the range `-180...180`.
///   - precision: Number of characters in the result. Defaults to `12`.
/// - Returns: The geohash representing the coordinate.
/// - Throws: ``GeohashError/outOfRange`` if either coordinate is outside its valid range.
public func encode(
    latitude: Double,
    longitude: Double,
    precision: Int = 12
) throws -> String
```

- First line is a single-sentence summary. **Period at the end.**
- Blank line, then the detailed discussion.
- Use `- Parameters:` / `- Parameter <name>:`, `- Returns:`, `- Throws:` in that order.
- Reference other symbols with **double backticks**: ``GeohashError``, ``encode(latitude:longitude:precision:)``.

## What to document

- **Always**: public types, methods, properties, protocols.
- **Usually**: complex internal helpers whose behavior isn't obvious.
- **Never**: trivial getters, `Equatable` boilerplate, things that just repeat the signature.

Bad:

```swift
/// Gets the name.
public var name: String
```

Good:

```swift
/// The display name shown in the user interface. Always non-empty.
public var name: String
```

## DocC catalogs

For a package, add a `.docc` catalog alongside sources:

```
Sources/MyLib/
├── MyLib.swift
└── MyLib.docc/
    ├── MyLib.md                      # Top-level landing article
    ├── Articles/
    │   ├── GettingStarted.md
    │   └── MigrationGuide.md
    ├── Tutorials/
    │   └── BuildYourFirstView.tutorial
    └── Resources/
        └── overview.png
```

Top-level landing (`MyLib.md`):

```markdown
# ``MyLib``

Fast, type-safe geohash encoding and decoding.

## Overview

MyLib turns coordinates into compact geohash strings and back, with
configurable precision and zero allocations on the hot path.

## Topics

### Essentials
- ``encode(latitude:longitude:precision:)``
- ``decode(_:)``

### Errors
- ``GeohashError``
```

## Articles

Articles are Markdown files under `Articles/` referenced from the `## Topics` section. Use them for:

- **Getting Started** — how to install and call the first API.
- **Migration guides** — when a major version changes behavior.
- **Conceptual overviews** — explain a model that a single symbol comment can't.

Don't duplicate API reference inside articles — link to symbols with double backticks.

## Tutorials

Use the `.tutorial` format only for genuinely step-by-step learning content. For a typical library, **one or two tutorials** is plenty. Skip tutorials entirely for utility libraries.

## Code samples in docs

Use fenced code blocks with the `swift` language tag:

````markdown
```swift
let hash = try encode(latitude: 37.7749, longitude: -122.4194)
print(hash)        // "9q8yyk8ytpxr"
```
````

- Show realistic input and the expected output as a comment.
- Examples should **compile** — keep them in a `Snippets/` folder if they grow non-trivial.

## Building and previewing

For a package:

```bash
swift package --disable-sandbox preview-documentation --target MyLib
# Open the URL printed in the terminal
```

To build static hosted docs:

```bash
swift package --allow-writing-to-directory ./docs \
    generate-documentation --target MyLib \
    --output-path ./docs \
    --transform-for-static-hosting \
    --hosting-base-path my-lib
```

For an Xcode project: Product → Build Documentation.

## Hosting

- **GitHub Pages** for OSS libraries: publish `./docs` from a `gh-pages` branch via a GitHub Actions workflow.
- **Swift Package Index** automatically builds and hosts DocC for public Swift packages — no extra config needed beyond a clean DocC catalog.

## Anti-patterns

- Documenting "what" instead of "why" / "when to use" — assume the reader can read the signature.
- Massive top-level overviews with no `## Topics` curation — DocC's auto-generated list becomes useless past ~10 symbols.
- Code samples that don't compile or that reference removed API.
