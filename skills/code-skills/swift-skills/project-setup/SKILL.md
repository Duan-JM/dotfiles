---
name: swift-project-setup
description: Bootstraps Swift / SwiftUI applications and packages — Xcode project structure, Swift Package Manager layout, target organization, build settings, and feature-based folder conventions. Use when starting a new app, adding a new module, or restructuring an existing project.
---

# Swift Project Setup

## Project type decision

| Goal | Use |
|---|---|
| iOS / macOS app | Xcode App project (`.xcodeproj` or `.xcworkspace`) |
| Reusable library | Swift Package (`Package.swift`) |
| App + extracted modules | Xcode app + local SPM packages referenced by path |
| CLI tool | Swift Package with executable target |

For non-trivial apps, **prefer Xcode app + local SPM packages** for each feature. It keeps modules buildable in isolation, makes tests fast, and avoids monolithic `.xcodeproj` merge conflicts.

## Folder layout (feature-based)

Organize folders by **feature**, not by type:

```
MyApp/
├── App/                     # @main, root view, dependency wiring
├── Features/
│   ├── Onboarding/
│   │   ├── OnboardingView.swift
│   │   ├── OnboardingModel.swift
│   │   └── OnboardingTests/
│   ├── Library/
│   └── Player/
├── Core/                    # cross-feature: networking, persistence, theming
├── Resources/               # Assets.xcassets, Localizable.xcstrings
└── Tests/
```

- **One type per file** (struct / class / enum). Flag files with multiple type definitions.
- Match folder names to feature names exactly.

## SwiftUI app entry

```swift
@main
struct MyApp: App {
    @State private var session = SessionStore()        // @Observable @MainActor

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
    }
}
```

- Put dependency wiring in the `App` struct (or a small composition-root type), not scattered in views.
- Inject shared state via `@Environment`, not via singletons.

## Swift Package layout

```
MyLib/
├── Package.swift
├── Sources/
│   └── MyLib/
│       └── …
└── Tests/
    └── MyLibTests/
        └── …
```

Minimal `Package.swift` (Swift 6.2, iOS 26):

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

- Set `swiftLanguageModes: [.v6]` to opt in to strict concurrency.
- Pin platforms explicitly — leaving them unset uses very old defaults.
- Use **path-based dependencies** for local feature packages:

  ```swift
  dependencies: [.package(path: "../FeatureLibrary")]
  ```

## Build settings worth setting once

- **Swift Language Version**: `6.0` (strict concurrency).
- **Strict Concurrency Checking**: `Complete`.
- **Deployment Target**: latest you can justify (iOS 26 by default for new apps).
- **Treat Warnings as Errors**: on for Release; on for CI; off in Debug if it slows iteration.
- **Build Active Architecture Only**: Yes for Debug, No for Release.

## Targets and schemes

- Keep **App** and **AppTests** + **AppUITests** as separate targets.
- Add a **Debug-only** target for ad-hoc previews / fixtures if needed.
- Schemes:
  - `MyApp` (default)
  - `MyApp (UI Tests)` — for slow UI test runs
  - One scheme per local SPM package for fast iteration.

## When to extract a local SPM package

Extract when one or more of these is true:

- Module compiles in **>15s** as part of the app target.
- Module has its own non-trivial test suite.
- Module will be reused across app / widget / watchOS extension.
- Module needs to be developed without rebuilding the whole app.
