---
name: swiftui-navigation
description: Reviews SwiftUI navigation and presentation — NavigationStack, NavigationSplitView, navigationDestination, alerts, confirmation dialogs, and sheets. Use when designing navigation flows, migrating from NavigationView, or auditing presentation patterns.
---

# SwiftUI Navigation and Presentation

## Navigation stacks

- Use `NavigationStack` or `NavigationSplitView` as appropriate. Flag all use of the deprecated `NavigationView`.
- Strongly prefer `navigationDestination(for:)` for destinations. Flag the old `NavigationLink(destination:)` pattern where it should be replaced:

  ```swift
  // Modern
  NavigationStack(path: $path) {
      List(items) { item in
          NavigationLink(value: item) { Text(item.name) }
      }
      .navigationDestination(for: Item.self) { item in
          DetailView(item: item)
      }
  }
  ```

- Never mix `navigationDestination(for:)` and `NavigationLink(destination:)` in the same navigation hierarchy — it causes significant problems.
- `navigationDestination(for:)` must be registered exactly once per data type. Flag duplicates.

## Alerts

- If an alert has only a single "OK" button that just dismisses, the action button can be omitted:

  ```swift
  .alert("Dismiss Me", isPresented: $isShowingAlert) { }
  ```

## Confirmation dialogs

- Always attach `confirmationDialog()` to the UI element that triggers it. This lets Liquid Glass animations originate from the correct source.

## Sheets

- For optional data, prefer `sheet(item:)` over `sheet(isPresented:)` — the optional is safely unwrapped:

  ```swift
  .sheet(item: $selectedItem, content: DetailView.init)
  ```

- When the destination view takes the item as its only initializer parameter, pass the initializer directly:

  ```swift
  // Preferred
  .sheet(item: $selectedItem, content: DetailView.init)

  // Avoid the longer closure form
  .sheet(item: $selectedItem) { item in DetailView(item: item) }
  ```

## Learn More

This guidance is adapted from the [SwiftUI Pro agent skill](https://github.com/twostraws/SwiftUI-Agent-Skill) by Paul Hudson (MIT-licensed).
