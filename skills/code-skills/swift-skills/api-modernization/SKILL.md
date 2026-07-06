---
name: modernizing-swiftui-api
description: Updates SwiftUI code from deprecated and legacy APIs to modern equivalents (iOS 17+ / iOS 26). Covers foregroundStyle, Tab API, onChange, GeometryReader alternatives, sensoryFeedback, @Entry macro, modern overlay/toolbar placements, and more. Use when modernizing existing SwiftUI codebases or reviewing for deprecated API usage.
---

# Modernizing SwiftUI API

Target Swift 6.2+ and iOS 26 as the default. Replace deprecated and legacy patterns with modern equivalents.

## High-frequency replacements

| Legacy | Modern |
|--------|--------|
| `foregroundColor(.red)` | `foregroundStyle(.red)` |
| `cornerRadius(8)` | `clipShape(.rect(cornerRadius: 8))` |
| `tabItem { Label(...) }` | `Tab("Home", systemImage: "house", value: .home) { ... }` |
| `.navigationBarLeading` / `.navigationBarTrailing` | `.topBarLeading` / `.topBarTrailing` |
| `.overlay(SomeView(), alignment: .top)` | `.overlay(alignment: .top) { SomeView() }` |
| `showsIndicators: false` in `ScrollView` init | `.scrollIndicators(.hidden)` |
| `UIImpactFeedbackGenerator` | `.sensoryFeedback(.impact, trigger: value)` |
| `Image("avatar")` | `Image(.avatar)` (generated symbol asset API) |
| `PreviewProvider` | `#Preview { ... }` |

## onChange

Never use the 1-parameter `onChange()` variant. Use either the zero- or two-parameter form:

```swift
// Good
.onChange(of: score) { oldValue, newValue in ... }
.onChange(of: score) { ... }
```

## Custom environment / focus / container values

Use the `@Entry` macro instead of manually conforming to `EnvironmentKey`:

```swift
extension EnvironmentValues {
    @Entry var theme: Theme = .light
}
```

## GeometryReader

Don't reach for `GeometryReader` first. Prefer:

- `containerRelativeFrame(...)` for sizing relative to a scroll container.
- `visualEffect { content, proxy in ... }` for visual transforms based on layout.
- The `Layout` protocol for custom layouts.

Flag `GeometryReader` and suggest the modern alternative.

## WebView

When targeting iOS 26+, SwiftUI has a native `WebView` that replaces almost all `WKWebView` wrappers in `UIViewRepresentable`. Add `import WebKit`.

## Shapes and strokes

Fill and stroke can both be chained directly — the `overlay`-for-stroke trick is no longer required since iOS 17:

```swift
Circle()
    .fill(.blue)
    .stroke(.white, lineWidth: 2)
```

## ForEach + enumerated

Don't convert to an array first:

```swift
ForEach(Array(items.enumerated()), id: \.element.id) { ... }    // Bad
ForEach(items.enumerated(), id: \.element.id) { offset, item in ... }    // Good
```

## Grammar agreement

For supported languages (English, French, German, Portuguese, Spanish, Italian), use automatic grammar agreement:

```swift
Text("^[\(people) person](inflect: true)")
```

## Text concatenation

Never use `+` to concatenate `Text`:

```swift
// Bad and deprecated
Text("Hello").foregroundStyle(.red)
+
Text("World").foregroundStyle(.blue)

// Good — interpolation
let red = Text("Hello").foregroundStyle(.red)
let blue = Text("World").foregroundStyle(.blue)
Text("\(red)\(blue)")
```

## ObservableObject

If you must use `ObservableObject` (e.g., for a Combine-based debouncer), add `import Combine` explicitly — SwiftUI no longer re-exports it.

## Learn More

This guidance is adapted from the [SwiftUI Pro agent skill](https://github.com/twostraws/SwiftUI-Agent-Skill) by Paul Hudson (MIT-licensed).
