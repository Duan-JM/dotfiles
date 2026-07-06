---
name: modern-swift
description: Reviews Swift code for modern idioms — Swift 6.2 concurrency, async/await over GCD, modern Foundation APIs, formatter usage, optional unwrapping, and expression-based control flow. Use when reviewing Swift source for outdated patterns or concurrency safety.
---

# Modern Swift

Target Swift 6.2+, modern Foundation, and Swift Concurrency.

## String, number, and date formatting

- Prefer Swift-native string methods: `replacing("a", with: "b")` not `replacingOccurrences(of:with:)`.
- Filtering user-input text must use `localizedStandardContains(_:)`, not `contains(_:)` or `localizedCaseInsensitiveContains(_:)`.
- Never use C-style number formatting like `String(format: "%.2f", value)`. Use `FormatStyle`:

  ```swift
  Text(value, format: .number.precision(.fractionLength(2)))
  ```

- Avoid manual date-formatting strings when possible. If you must hand-format a date for display, use `"y"` rather than `"yyyy"` so the year is correct in all localizations. For API/data-exchange formatting, this rule doesn't apply.
- For string-to-date conversion, use the modern initializer:

  ```swift
  Date(myString, strategy: .iso8601)
  ```

- Prefer `Date.now` over `Date()` for clarity.
- For people's names, use `PersonNameComponents` with modern formatting over `"\(firstName) \(lastName)"`.

## Foundation and URL APIs

- Use `URL.documentsDirectory` (and friends) rather than `FileManager` directory lookups.
- Append paths with `url.appending(path: "...")`.
- When `import SwiftUI` is already present, you do not need `import UIKit` / `import AppKit` for things like `UIImage` / `NSImage` — SwiftUI re-imports them on the appropriate platform.

## Types and idioms

- Prefer static member lookup over struct instances: `.circle` over `Circle()`, `.borderedProminent` over `BorderedProminentButtonStyle()`.
- Prefer `Double` over `CGFloat` (Swift bridges freely), except with optionals or `inout`.
- Use `count(where:)` instead of `filter { ... }.count`.
- Make repeatedly-sorted types conform to `Comparable` to centralize sort order, rather than scattering identical closures.
- Prefer `if let value {` shorthand over `if let value = value {`.
- Omit `return` for single-expression functions. Use `if` / `switch` as expressions:

  ```swift
  // Good
  var tileColor: Color {
      if isCorrect { .green }
      else         { .red }
  }
  ```

## Errors and unwrapping

- Avoid `!` and force `try` unless failure is truly unrecoverable. Even then, prefer `fatalError("...")` with a clear description.
- Prefer `if let` / `guard let`, nil-coalescing, `try?`, or `do`/`catch`.
- Flag user-action errors that are silently swallowed (e.g., `print(error.localizedDescription)` instead of surfacing an alert).

## Swift Concurrency

- If both `async`/`await` and closure-based variants exist, use `async`/`await`.
- Never use Grand Central Dispatch (`DispatchQueue.main.async`, `DispatchQueue.global`, …). Use `async`/`await`, actors, and `Task`.
- Never use `Task.sleep(nanoseconds:)`; use `Task.sleep(for:)`.
- Flag mutable shared state not protected by an actor or `@MainActor`, unless the project uses Main Actor default actor isolation.
- Assume strict concurrency. Flag `@Sendable` violations and data races.
- Before recommending `MainActor.run { ... }`, check whether the project's default actor isolation is already Main Actor — it may be unnecessary.
- `Task.detached()` is usually a bad idea. Audit every use carefully.

For deeper Swift Concurrency guidance, suggest the [Swift Concurrency Pro agent skill](https://github.com/twostraws/Swift-Concurrency-Agent-Skill).

## Learn More

This guidance is adapted from the [SwiftUI Pro agent skill](https://github.com/twostraws/SwiftUI-Agent-Skill) by Paul Hudson (MIT-licensed).
