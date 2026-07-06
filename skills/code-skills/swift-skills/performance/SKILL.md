---
name: swiftui-performance
description: Optimizes SwiftUI performance — structural identity, AnyView avoidance, view extraction, lazy stacks, task vs onAppear, inline transforms, and ViewBuilder usage. Use when investigating SwiftUI performance issues or reviewing hot view code.
---

# SwiftUI Performance

## Structural identity

Toggling a modifier value via `if`/`else` creates `_ConditionalContent` and may rebuild platform views. Prefer ternary expressions to preserve structural identity:

```swift
// Bad
if isActive {
    Text("Hello").foregroundStyle(.blue)
} else {
    Text("Hello").foregroundStyle(.gray)
}

// Good
Text("Hello").foregroundStyle(isActive ? .blue : .gray)
```

## Avoid AnyView

Use `@ViewBuilder`, `Group`, or generics instead of `AnyView`. `AnyView` erases type information and defeats SwiftUI's diffing.

## Extract real views, not computed properties

It is more efficient to extract a sub-view into its own `View` struct than to return `some View` from a computed property or method, even with `@ViewBuilder`. Each computed-property re-evaluation re-runs the builder.

```swift
// Less efficient
@ViewBuilder
private var header: some View { ... }

// Preferred
struct ProfileHeader: View { var body: some View { ... } }
```

## Avoid escaping ViewBuilder closures

Storing an escaping `@ViewBuilder` closure on a view is worse than storing the built view value — let the synthesized init call the builder for you:

```swift
// Anti-pattern: stored escaping closure
struct CardView<Content: View>: View {
    let content: () -> Content
    var body: some View {
        VStack(alignment: .leading) { content() }
            .padding()
    }
}

// Preferred: stored built value
struct CardView<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading) { content }
            .padding()
    }
}
```

## Body and initializers

- Assume `body` runs frequently. Move sorting, filtering, or other non-trivial work out of `body` when easy.
- Keep view initializers small and fast. Move work into `.task()` so it runs when the view appears and is cancelled automatically when it disappears.
- Prefer `.task()` over `.onAppear()` for async work — `.task()` cancels on disappear.

## Lists and lazy stacks

- For large data sets inside `ScrollView`, use `LazyVStack` / `LazyHStack`. Flag eager stacks with many children.
- Avoid expensive inline transforms in `List` / `ForEach` initializers (e.g., `items.filter { ... }`) when they run on every body call.
- Derive transformed data via `let` from the source of truth, or cache in `@State` — but only cache derived collections if you also own explicit invalidation, otherwise the UI goes stale.

## Formatting and scroll backgrounds

- Don't create stored `DateFormatter` properties when `Text` with a format works:

  ```swift
  Text(Date.now, format: .dateTime.day().month().year())
  Text(100, format: .currency(code: "USD"))
  ```

- For a `ScrollView` with an opaque, static, solid background, use `.scrollContentBackground(.visible)` for more efficient scroll-edge rendering.

## Learn More

This guidance is adapted from the [SwiftUI Pro agent skill](https://github.com/twostraws/SwiftUI-Agent-Skill) by Paul Hudson (MIT-licensed).
