---
name: swift-testing-strategy
description: Designs test suites for Swift apps and packages using Swift Testing (@Test, #expect) and XCTest where required. Covers test layout, parameterization, async tests, mocks, snapshot/UI tests, and CI integration. Use when adding tests, improving coverage, or migrating from XCTest to Swift Testing.
---

# Swift Testing Strategy

## Default framework: Swift Testing

Use **Swift Testing** (`@Test`, `#expect`, `#require`) for new tests. Keep XCTest only where you genuinely need it:

| Use Swift Testing for | Keep XCTest for |
|---|---|
| Unit tests | UI tests (`XCUIApplication`) |
| Integration tests | Performance tests (`measure { ... }`) |
| Parameterized cases | Legacy suites you haven't migrated yet |

For deeper guidance, suggest the [Swift Testing Pro agent skill](https://github.com/twostraws/Swift-Testing-Agent-Skill).

## Basic test

```swift
import Testing
@testable import MyApp

@Test func userCanLogIn() async throws {
    let store = SessionStore()
    try await store.logIn(email: "a@b.com", password: "secret")
    #expect(store.isAuthenticated)
}
```

- `#expect` for soft assertions (test continues on failure).
- `#require` for must-hold preconditions (test halts on failure).
- Tests are functions, not methods — no `XCTestCase` boilerplate.

## Parameterization

```swift
@Test(arguments: [
    ("a@b.com",      true),
    ("not-an-email", false),
    ("",             false),
])
func emailValidation(input: String, expected: Bool) {
    #expect(EmailValidator.isValid(input) == expected)
}
```

One `@Test` produces one row per argument tuple in the report.

## Suites and tags

```swift
@Suite("Login flow", .tags(.integration))
struct LoginTests {
    @Test func successPath() async throws { ... }
    @Test func wrongPassword() async throws { ... }
}

extension Tag {
    @Tag static var integration: Self
    @Tag static var slow: Self
}
```

Run by tag: `swift test --filter "integration"`.

## Async, time, and confirmations

```swift
@Test func dataLoadsWithin500ms() async throws {
    try await confirmation(expectedCount: 1) { confirm in
        let loader = Loader()
        loader.onComplete = { confirm() }
        try await loader.start()
    }
}
```

- Use `await confirmation` for callback-based code (replaces `XCTestExpectation`).
- Use `withKnownIssue { ... }` to record a failing test that's tracked but shouldn't fail CI.

## Test layout

```
Sources/MyLib/...
Tests/
└── MyLibTests/
    ├── Models/
    │   └── UserTests.swift
    ├── Services/
    │   └── LoginServiceTests.swift
    └── Fixtures/
        └── sample-user.json
```

- Mirror `Sources/` structure under `Tests/`.
- Group fixtures in a `Fixtures/` folder; load with `Bundle.module`.

## Mocking and test doubles

- Prefer **protocol-based** seams over mocking frameworks. Define a protocol, inject it.
- For network, use a `URLProtocol` subclass to intercept `URLSession` requests — no third-party mock needed.
- Never mock value types — just construct them with test data.

```swift
protocol UserAPI: Sendable {
    func fetchUser(id: UUID) async throws -> User
}

struct StubUserAPI: UserAPI {
    var result: Result<User, Error>
    func fetchUser(id: UUID) async throws -> User { try result.get() }
}
```

## UI tests (XCTest)

UI tests are slow and flaky. Use them only when unit tests cannot verify the behaviour:

```swift
final class CheckoutUITests: XCTestCase {
    func testHappyPath() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestMode", "1"]
        app.launch()
        app.buttons["Buy Now"].tap()
        XCTAssert(app.staticTexts["Thanks!"].waitForExistence(timeout: 2))
    }
}
```

- Pass `launchArguments` to put the app into a deterministic mode.
- Use `accessibilityIdentifier` for stable selectors — not visible label text.

## Snapshot tests

Consider snapshot tests for visual regression on key views:

- Render with `ImageRenderer` (SwiftUI native) — do not pull in third-party deps unless asked.
- Store baselines under `Tests/__Snapshots__/` and commit them.
- Re-record only with an explicit env flag (`RECORD_SNAPSHOTS=1`), never automatically.

## Coverage and CI

- Enable code coverage in the test scheme (Test action → Options → Code Coverage).
- Target: **>80% on logic modules** (models, services). Don't chase coverage on view code.
- In CI: `xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 16'`.
- Fail the build on **any new test failure** — never allow "known failing" without a tracked issue.
