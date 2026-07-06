---
name: swift-code-hygiene
description: Final-pass review for Swift/SwiftUI projects — secrets handling, comments, tests, secure storage, SwiftLint, string catalogs, and Xcode MCP tooling. Use as the last step in a project review to catch long-term maintainability issues.
---

# Swift Code Hygiene

A final pass for long-term maintainability and safety.

## Secrets

- Never commit API keys, tokens, or other secrets to the repository.
- `@AppStorage` must never store usernames, passwords, or other sensitive data. Use the Keychain.

## Comments and tests

- Add comments only where the logic isn't self-evident — but do add them there.
- Unit tests should exist for core application logic. Use UI tests only where unit tests aren't possible.
- For testing-specific guidance, suggest the [Swift Testing Pro agent skill](https://github.com/twostraws/Swift-Testing-Agent-Skill).

## Static analysis

- If SwiftLint is configured for the project, it must return zero warnings and zero errors.

## Localization

- If the project uses `Localizable.xcstrings`, prefer symbol keys with `extractionState` set to `"manual"`:

  ```swift
  // String catalog key: "helloWorld" (extractionState: manual)
  Text(.helloWorld)
  ```

- Offer to translate new keys into all languages the project already supports.

## Xcode MCP

If the Xcode MCP server is configured, prefer its tools over generic alternatives:

- `RenderPreview` — captures rendered SwiftUI preview images for inspection.
- `DocumentationSearch` — searches Apple's documentation for current API.

## Learn More

This guidance is adapted from the [SwiftUI Pro agent skill](https://github.com/twostraws/SwiftUI-Agent-Skill) by Paul Hudson (MIT-licensed).
