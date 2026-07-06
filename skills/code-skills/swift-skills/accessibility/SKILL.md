---
name: swiftui-accessibility
description: Audits SwiftUI code for accessibility compliance — Dynamic Type, VoiceOver, Voice Control, Reduce Motion, and color-independent UI. Use when reviewing SwiftUI views for a11y issues or adding accessibility support to existing code.
---

# SwiftUI Accessibility

Respect the user's accessibility settings for fonts, colors, animations, and motion. Flag only genuine problems — do not nitpick.

## Dynamic Type

- Do not force specific font sizes. Prefer Dynamic Type (`.font(.body)`, `.font(.headline)`, etc.).
- If a custom font size is required:
  - Targeting iOS 18 and earlier → use `@ScaledMetric`.
  - Targeting iOS 26 and later → `.font(.body.scaled(by:))` is also available.

## VoiceOver

- Icon-only buttons are bad for VoiceOver. Always include text, even if visually hidden:

  ```swift
  // Bad
  Button(action: addUser) {
      Image(systemName: "plus")
  }

  // Good
  Button("Add User", systemImage: "plus", action: addUser)
  ```

- SwiftUI usually picks the right label style for context (e.g., toolbar buttons become icon-only). If you must keep an icon-only visual while preserving the text for VoiceOver, apply `.labelStyle(.iconOnly)`.
- The same rule applies to `Menu`: `Menu("Options", systemImage: "ellipsis.circle") { }` is much better than icon-only.
- Decorative images should use `Image(decorative:)` or `accessibilityHidden(true)`. Meaningful images need `accessibilityLabel()`.
- Flag asset names that produce unhelpful VoiceOver readings (e.g., `Image(.newBanner2026)`).

## Voice Control

- For buttons with complex or live-updating labels (e.g., a stock ticker reading `"AAPL $271.68"`), add `accessibilityInputLabels(["Apple"])` to give Voice Control a stable hook.

## Reduce Motion

- If the user enables Reduce Motion, replace large motion-based animations with opacity transitions instead.

## Color Independence

- If color is a key differentiator, also vary icons, patterns, or strokes so users with `.accessibilityDifferentiateWithoutColor` enabled aren't lost.

## Tap Targets and Gestures

- Never use `onTapGesture()` unless you specifically need tap location or count. Use `Button` for everything else.
- If `onTapGesture()` is unavoidable, add `.accessibilityAddTraits(.isButton)` (or similar) so VoiceOver reads it correctly.
- Minimum tap target on iOS is 44×44 pt. Enforce strictly.

## Learn More

This guidance is adapted from the [SwiftUI Pro agent skill](https://github.com/twostraws/SwiftUI-Agent-Skill) by Paul Hudson (MIT-licensed).
