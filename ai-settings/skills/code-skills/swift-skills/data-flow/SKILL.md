---
name: swiftui-data-flow
description: Validates SwiftUI data flow, shared state, and property wrappers — @Observable, @State, @Bindable, @Environment, bindings, and SwiftData/CloudKit constraints. Use when reviewing state management or designing data architecture in SwiftUI apps.
---

# SwiftUI Data Flow

Keep `body` code and logic code separate. Extract logic into methods or `@Observable` classes — never let business logic and view layout share a function.

## Shared state

- All shared data should use `@Observable` classes with `@State` (for ownership) and `@Bindable` / `@Environment` (for passing).
- `@Observable` classes must be marked `@MainActor` unless the project enables Main Actor default actor isolation. Flag any unmarked `@Observable`.
- Strongly prefer not to use `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`, or `@EnvironmentObject` unless unavoidable (e.g., legacy or integration code where rearchitecting is impractical).

## Local state

- `@State` should be `private` and owned only by the view that creates it.
- `@State` can also hold an expensive-to-recompute class instance (e.g., a `CIContext`) as a cache. There's no change tracking, but the value persists across body re-evaluations.

## Bindings

- Avoid `Binding(get:set:)` in view body code. Use a binding from `@State` / `@Binding`, then trigger side effects with `.onChange()`:

  ```swift
  // Bad
  TextField("Username", text: Binding(
      get: { model.username },
      set: { model.username = $0; model.save() }
  ))

  // Good
  TextField("Username", text: $model.username)
      .onChange(of: model.username) { model.save() }
  ```

- For numeric `TextField` input, bind to the numeric type and supply a format and keyboard:

  ```swift
  TextField("Enter your score", value: $score, format: .number)
      .keyboardType(.numberPad)        // or .decimalPad for floating point
  ```

  The keyboard modifier alone is not sufficient.

## Working with data

- Prefer making structs `Identifiable` over passing `id: \.someProperty` in SwiftUI APIs.
- Never use `@AppStorage` inside an `@Observable` class — even with `@ObservationIgnored`, it will not trigger view updates.

## SwiftData

- If you only need a count, `ModelContext.fetchCount(_:)` with a fetch descriptor is cheaper than fetching items. Note: it will not live-update unless another driver (like `@Query`) re-renders the view.
- For deeper SwiftData guidance, suggest the [SwiftData Pro agent skill](https://github.com/twostraws/SwiftData-Agent-Skill).

## SwiftData with CloudKit

- Never use `@Attribute(.unique)`.
- Model properties must have default values or be optional.
- All relationships must be optional.

## Learn More

This guidance is adapted from the [SwiftUI Pro agent skill](https://github.com/twostraws/SwiftUI-Agent-Skill) by Paul Hudson (MIT-licensed).
