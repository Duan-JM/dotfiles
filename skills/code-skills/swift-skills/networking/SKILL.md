---
name: swift-networking
description: Designs networking for Swift / SwiftUI apps — URLSession async/await, request modeling, JSON coding, error handling, retries, caching, certificate pinning, and integration with SwiftUI views. Use when adding network code, building an API client, or auditing existing networking for safety and modernity.
---

# Swift Networking

## URLSession with async/await

Use `URLSession`'s async API by default. Never use the closure-based variants for new code:

```swift
let (data, response) = try await URLSession.shared.data(from: url)
```

- Reject non-2xx responses explicitly:

  ```swift
  guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
      throw APIError.badStatus(code: (response as? HTTPURLResponse)?.statusCode ?? -1)
  }
  ```

## A small typed client

```swift
struct APIClient: Sendable {
    var baseURL: URL
    var session: URLSession = .shared
    var decoder: JSONDecoder = .init()
    var encoder: JSONEncoder = .init()

    func get<T: Decodable & Sendable>(_ path: String) async throws -> T {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "GET"
        return try await send(request)
    }

    func post<Body: Encodable & Sendable, T: Decodable & Sendable>(
        _ path: String, body: Body
    ) async throws -> T {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        return try await send(request)
    }

    private func send<T: Decodable & Sendable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        try validate(response)
        return try decoder.decode(T.self, from: data)
    }
}
```

- Make the client a `struct: Sendable` — easy to pass across actors.
- Keep one client per API. Don't share encoders / decoders across unrelated APIs.

## Errors

Define a typed error:

```swift
enum APIError: Error, Sendable {
    case badStatus(code: Int)
    case decoding(any Error)
    case transport(any Error)
    case cancelled
}
```

- Map low-level errors at the boundary; views should see `APIError`, not `URLError`.
- Treat `URLError(.cancelled)` specially — it's expected when a `task()` is cancelled.

## SwiftUI integration

Prefer `task()` over `onAppear()` — it auto-cancels when the view disappears:

```swift
struct ProfileView: View {
    let userID: UUID
    @State private var state: LoadState<User> = .idle

    var body: some View {
        Group {
            switch state {
            case .idle, .loading: ProgressView()
            case .loaded(let user): UserCard(user: user)
            case .failed(let error): ErrorView(error: error)
            }
        }
        .task(id: userID) {
            state = .loading
            do {
                state = .loaded(try await api.get("users/\(userID)"))
            } catch is CancellationError {
                // user navigated away; ignore
            } catch {
                state = .failed(error)
            }
        }
    }
}
```

- Always re-run on identity change with `.task(id:)`.
- Surface user-action errors in the UI — never swallow with `print(error.localizedDescription)`.

## Cancellation

- `URLSession.data(...)` honors `Task.cancel()` — no explicit handling needed.
- For long-running iterations, sprinkle `try Task.checkCancellation()` at safe points.
- Never use `Task.detached` to "escape" cancellation; that's almost always a bug.

## Retries and timeouts

- Default `URLSession` timeout (60s for the resource) is fine for most APIs. Tune `URLSessionConfiguration.timeoutIntervalForRequest` per client when the server has known latency.
- Retry only **idempotent** requests (GET, PUT, DELETE — not POST unless you know it's safe).
- Use exponential backoff with jitter:

  ```swift
  for attempt in 0..<3 {
      do { return try await operation() }
      catch is CancellationError { throw CancellationError() }
      catch {
          if attempt == 2 { throw error }
          let delay = pow(2.0, Double(attempt)) + .random(in: 0...0.5)
          try await Task.sleep(for: .seconds(delay))
      }
  }
  ```

- Use `Task.sleep(for: .seconds(_:))`, never `Task.sleep(nanoseconds:)`.

## JSON coding

- Configure once, on the client:

  ```swift
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  decoder.dateDecodingStrategy = .iso8601
  ```

- For union types / polymorphic payloads, write a custom `init(from decoder:)`. Don't reach for third-party libs unless asked.
- Avoid `[String: Any]`. Define a struct; if the field really is heterogeneous, model it as an enum with associated values.

## Caching

- `URLSession`'s built-in `URLCache` covers most HTTP-cache needs. Default size (in-memory + disk) is reasonable; raise it for image-heavy apps.
- For image loading, use SwiftUI's `AsyncImage` for simple cases, or a small custom loader backed by `URLCache` and `Task` deduplication for hot paths.

## Certificate pinning

For sensitive APIs, pin the server's **public key**, not the certificate:

```swift
final class PinningDelegate: NSObject, URLSessionDelegate {
    let pinnedKeys: Set<Data>

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let trust = challenge.protectionSpace.serverTrust,
              SecTrustEvaluateWithError(trust, nil),
              let cert = SecTrustGetCertificateAtIndex(trust, 0),
              let key = SecCertificateCopyKey(cert),
              let keyData = SecKeyCopyExternalRepresentation(key, nil) as Data?,
              pinnedKeys.contains(keyData)
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}
```

Pinning to the public key (not the cert) survives normal certificate rotation.

## WebSocket / streaming

- For server-to-client streams, use `URLSession.webSocketTask` wrapped in an `AsyncThrowingStream`.
- For Server-Sent Events, use `URLSession.bytes(for:)` and iterate lines asynchronously.

## Logging

- Log via `os.Logger`. Mark anything user-derived as `.private`:

  ```swift
  logger.debug("GET /users/\(userID, privacy: .private)")
  ```

- Never log full request bodies, headers (Authorization!), or response bodies in Release builds.

## Anti-patterns

- `DispatchQueue.main.async { ... }` to update UI after a network call → use `@MainActor` or `await MainActor.run` only when truly needed (often the calling context already is).
- Long-lived `Task { ... }` started in a view body but never cancelled — leak. Use `.task()`.
- Returning `Result<T, Error>` from async functions — Swift already has typed throws via `throws(SomeError)`. Use that or plain `throws`.
- `URLSession.shared` for sensitive requests — use a configured session with appropriate timeouts and (if needed) pinning.
- Decoding into `[String: Any]` and parsing by hand.
