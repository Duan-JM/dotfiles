---
name: swiftui-design
description: Reviews SwiftUI designs against Apple's Human Interface Guidelines — fonts, colors, spacing, tap targets, system styling (ContentUnavailableView, Label, LabeledContent), and flexible layouts. Use when designing or reviewing SwiftUI UI for HIG compliance and cross-device consistency.
---

# SwiftUI Design (HIG)

Design SwiftUI views to be uniform, flexible, and HIG-compliant across devices and accessibility settings.

## Uniform design

Centralize fonts, colors, sizes, padding, corner radii, and animation timings in a shared enum of constants so the entire app stays consistent and can be retuned in one place.

```swift
enum AppStyle {
    static let cardCornerRadius: CGFloat = 12
    static let pagePadding: CGFloat = 20
    static let snappy: Animation = .snappy(duration: 0.25)
}
```

## Flexible, accessible layout

- Never use `UIScreen.main.bounds` to read available space. Prefer `containerRelativeFrame()`, `visualEffect()`, or — only when truly required — `GeometryReader`.
- Avoid fixed frames unless content fits neatly. Fixed frames break across device sizes and Dynamic Type settings.
- Apple's minimum tap target on iOS is **44×44 pt**. Enforce strictly.

## System styling first

- Use `ContentUnavailableView` for empty / missing data — don't build a custom empty state.
- With `searchable()`, use `ContentUnavailableView.search` directly; the search term is included automatically (no `text:` argument needed).
- For an icon next to text, use `Label` instead of `HStack { Image(...); Text(...) }`.
- Prefer hierarchical styles (`.secondary`, `.tertiary`) over manual opacity — the system adapts them to context.
- Inside `Form`, wrap controls like `Slider` in `LabeledContent` for correct title/control layout. `LabeledContent` is also useful outside `Form` — define a custom `LabeledContentStyle` if you need consistent layout across views.
- `RoundedRectangle` defaults to `.continuous`; no need to specify it explicitly.

## Typography and color

- Use `.bold()` instead of `.fontWeight(.bold)` so the system picks the right weight for context.
- Only use `.fontWeight()` for non-bold weights when there's a real reason. Scattering `.medium` / `.semibold` is counterproductive.
- Avoid hard-coded padding and stack spacing unless explicitly requested.
- Avoid `UIColor` in SwiftUI code; use SwiftUI `Color` or asset-catalog colors.
- `.caption2` is extremely small — generally avoid it. `.caption` is also small; use it carefully.

## Learn More

This guidance is adapted from the [SwiftUI Pro agent skill](https://github.com/twostraws/SwiftUI-Agent-Skill) by Paul Hudson (MIT-licensed).
