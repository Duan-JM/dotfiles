---
name: swift-package-manager
description: Builds, structures, and publishes Swift Package Manager packages — Package.swift, targets, dependencies, platform constraints, resources, binary frameworks, and versioning. Use when creating a Swift package, splitting an app into local packages, or publishing a library.
---

# Swift Package Manager

## Minimal package

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyLib",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [
        .library(name: "MyLib", targets: ["MyLib"])
    ],
    targets: [
        .target(name: "MyLib"),
        .testTarget(name: "MyLibTests", dependencies: ["MyLib"])
    ],
    swiftLanguageModes: [.v6]
)
```

- The first line **must** be `// swift-tools-version: X.Y` — it determines parser version and is not a normal comment.
- Always set `platforms:`. Without it, SPM uses very old defaults (iOS 8, macOS 10.10).
- Set `swiftLanguageModes: [.v6]` to opt into strict concurrency on the package.

## Targets

Common target kinds:

| Kind | Use |
|---|---|
| `.target` | A library / framework |
| `.executableTarget` | A command-line tool |
| `.testTarget` | Tests (depends on the target under test) |
| `.binaryTarget` | A pre-built `.xcframework` |
| `.plugin` | Build-time or command plugins |

Folder convention:

```
Sources/<TargetName>/...
Tests/<TargetName>Tests/...
```

Override only when necessary, with `path:` / `sources:`.

## Dependencies

```swift
dependencies: [
    .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
    .package(path: "../FeaturePackage")              // local
],
targets: [
    .target(
        name: "MyLib",
        dependencies: [
            .product(name: "OrderedCollections", package: "swift-collections"),
            "FeaturePackage"
        ]
    )
]
```

- Use `from: "X.Y.Z"` for SemVer-compatible dependency ranges.
- Pin with `.exact("X.Y.Z")` only when necessary (e.g., a known-bad newer version).
- For internal multi-package layouts, prefer **path-based dependencies** during development.

## Resources

Bundle non-code assets:

```swift
.target(
    name: "MyLib",
    resources: [
        .process("Resources/sample.json"),
        .copy("Resources/MLModel.mlmodelc")
    ]
)
```

- `.process` runs SPM's resource processing (e.g., compiles `.xcassets`, `.storyboard`, asset catalogs).
- `.copy` preserves the file/directory as-is — use it for already-compiled artefacts (`.mlmodelc`, prebuilt `.bundle`).
- Access at runtime via `Bundle.module`:

  ```swift
  let url = Bundle.module.url(forResource: "sample", withExtension: "json")!
  ```

## Binary frameworks

For pre-built closed-source SDKs, use a binary target:

```swift
.binaryTarget(
    name: "SomeSDK",
    url: "https://example.com/SomeSDK-1.2.0.xcframework.zip",
    checksum: "<sha256>"
)
```

- Compute the checksum with `swift package compute-checksum SomeSDK.xcframework.zip`.
- Host the artifact on stable storage. A 404 silently breaks every consumer.

## Conditional dependencies

```swift
.target(
    name: "MyLib",
    dependencies: [
        .product(name: "Logging", package: "swift-log",
                 condition: .when(platforms: [.iOS, .macOS]))
    ]
)
```

Use `condition: .when(platforms:)` instead of `#if os(...)` import guards when possible.

## Versioning your own package

- Tag releases with **SemVer**: `git tag 1.4.2 && git push --tags`.
- A breaking change to any **public** API must bump MAJOR.
- Add new symbols as MINOR. Bug fixes as PATCH.
- Treat **default argument changes** that change behavior as breaking.

## Publishing

For OSS libraries:

1. Push to a public Git host with proper tags.
2. Add a `README.md` with install instructions:

   ```swift
   .package(url: "https://github.com/you/MyLib.git", from: "1.0.0")
   ```

3. Submit to the [Swift Package Index](https://swiftpackageindex.com) — it auto-tracks new tags, builds docs, and publishes compatibility matrices for free.

For an `.xcframework` binary distribution, host the zip on GitHub Releases and reference it from `.binaryTarget` with a checksum.

## Common pitfalls

- **Missing `platforms:`** → cryptic build errors on consumers using modern APIs.
- **Resource without `Bundle.module` access** → file works in tests but is `nil` in app.
- **Path-based dep committed for a release tag** → consumers can't resolve `../FeaturePackage`. Convert to URL-based before tagging a public release.
- **Swift tools version mismatch** → bumping `swift-tools-version` forces all consumers to upgrade their toolchain. Bump conservatively.
- **Including test fixtures via `.process`** → SPM may compile them. Use `.copy` for raw fixtures.
