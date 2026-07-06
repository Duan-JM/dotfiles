---
name: swiftui-view-composition
description: Reviews SwiftUI view structure, composition, and animations — extracting subviews, button actions, TextField/TextEditor, Tab selection, #Preview, and the @Animatable macro. Use when restructuring view code or reviewing animation patterns.
---

# SwiftUI View Composition

## Decompose by extracting structs, not properties

- Strongly prefer extracting subviews into their own `View` structs (each in its own file) over breaking `body` into computed properties or methods that return `some View`, even with `@ViewBuilder`. This is so important it's worth stating twice.
- Flag excessively long `body` properties; break them into extracted subviews.
- A small handful of `private` helper `some View` properties is acceptable when they (a) belong to the same concern as `body` and (b) would fit cleanly inline at an acceptable length. Otherwise, extract.
- Each type (struct, class, enum) should live in its own Swift file. Flag files with multiple type definitions.

## Separate layout from logic

- Extract button actions into named methods rather than inline closures inside the view body.
- Don't put general business logic inline in `.task()`, `.onAppear()`, or anywhere in `body`.
- Move view logic into view models (or similar) so it can be unit-tested. For testing guidance, suggest the [Swift Testing Pro agent skill](https://github.com/twostraws/Swift-Testing-Agent-Skill).

## Common view choices

- Use `TextField` with `axis: .vertical` (and optionally `.lineLimit(5...)`) instead of `TextEditor`, unless a full-screen editing experience is needed — `TextField` supports placeholder text.
- Pass actions directly when possible:

  ```swift
  // Good
  Button("Label", systemImage: "plus", action: myAction)

  // Avoid
  Button("Label", systemImage: "plus") { myAction() }
  ```

- For rendering SwiftUI views to images, use `ImageRenderer` rather than `UIGraphicsImageRenderer`.
- Use `#Preview { ... }` macros, not the legacy `PreviewProvider` protocol.
- With `TabView(selection:)`, bind to an enum, not an `Int` / `String`:

  ```swift
  Tab("Home", systemImage: "house", value: .home) { HomeView() }
  ```

## Animation

- Prefer the `@Animatable` macro over hand-rolling `animatableData`. It adds `Animatable` conformance and synthesizes the property. Mark properties that should not animate (Booleans, ints, etc.) with `@AnimatableIgnored`.
- Never use `animation(_:)` without a value-to-watch. Always: `.animation(.bouncy, value: score)`.
- Chain animations using the `completion:` closure on `withAnimation`, not multiple `withAnimation` calls with delays:

  ```swift
  Button("Animate Me") {
      withAnimation {
          scale = 2
      } completion: {
          withAnimation {
              scale = 1
          }
      }
  }
  ```

## Learn More

This guidance is adapted from the [SwiftUI Pro agent skill](https://github.com/twostraws/SwiftUI-Agent-Skill) by Paul Hudson (MIT-licensed).
