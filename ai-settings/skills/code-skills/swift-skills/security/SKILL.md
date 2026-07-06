---
name: ios-security
description: Audits iOS / macOS apps for security — Keychain for credentials, App Transport Security, biometric authentication, entitlements, code signing, secure data storage, and SwiftData/CloudKit safety. Use when handling passwords/tokens, integrating auth, or hardening an app before release.
---

# iOS Security

## Credential storage

| Data type | Use |
|---|---|
| Passwords, tokens, OAuth refresh tokens | **Keychain** |
| Biometric-gated secrets | Keychain + `kSecAttrAccessControl` with `.biometryCurrentSet` |
| User preferences (non-sensitive) | `UserDefaults` / `@AppStorage` |
| App state, last opened item | `@AppStorage` / `@SceneStorage` |

- `@AppStorage` **must never** store usernames, passwords, tokens, API keys, or session identifiers.
- Even if you mark a property `@ObservationIgnored`, putting `@AppStorage` inside an `@Observable` class does **not** trigger updates — and is still wrong for secrets.

## Keychain wrapper

Use a small typed wrapper instead of scattering `SecItem*` calls:

```swift
struct KeychainStore {
    let service: String

    func set(_ value: String, for account: String) throws {
        let data = Data(value.utf8)
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.status(status) }
    }
}
```

- Default to `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` — secure and survives reboots into a locked state.
- Never use `kSecAttrAccessibleAlways` — it's deprecated and insecure.
- `ThisDeviceOnly` variants prevent iCloud Keychain sync.

## Biometrics (Face ID / Touch ID)

- Add `NSFaceIDUsageDescription` to `Info.plist`. The string is shown verbatim — make it meaningful.
- Use `LAContext` to evaluate `.deviceOwnerAuthenticationWithBiometrics`. Fall back to `.deviceOwnerAuthentication` for passcode fallback.
- Bind biometrics to a Keychain item with `SecAccessControlCreateWithFlags(... .biometryCurrentSet ...)` so changing fingerprints / faces invalidates the secret.

## App Transport Security (ATS)

- Keep default ATS settings. Never set `NSAllowsArbitraryLoads` to `true` in shipping builds.
- If you must allow HTTP for a specific domain (rare — usually a temporary dev workaround):

  ```xml
  <key>NSAppTransportSecurity</key>
  <dict>
      <key>NSExceptionDomains</key>
      <dict>
          <key>example.local</key>
          <dict>
              <key>NSExceptionAllowsInsecureHTTPLoads</key><true/>
          </dict>
      </dict>
  </dict>
  ```

- Flag any `NSAllowsArbitraryLoads = true` in a release-bound `Info.plist` as a critical issue.

## Networking

- Use `URLSession` with system trust by default — do **not** disable certificate validation.
- For certificate pinning, use `URLSessionDelegate.urlSession(_:didReceive:completionHandler:)` and validate `SecTrustEvaluateWithError`. Pin to the **public key**, not the cert (so cert rotation doesn't brick the app).
- Strip auth tokens from log output. Never log full request bodies in Release.

## Entitlements

- Only enable entitlements you actually use. Each unused entitlement is reviewer surface area.
- Pay extra attention to: **Keychain Sharing**, **App Groups**, **iCloud**, **Push Notifications**, **Sign in with Apple**, **Background Modes**.
- For App Groups: data placed in the shared container is readable by every app sharing the group — treat it as a less-trusted location.

## SwiftData / CloudKit data hygiene

- Treat data synced via CloudKit as **eventually consistent**. Don't assume a user's iCloud copy is current.
- For SwiftData + CloudKit, follow the constraints (see `data-flow` skill): no `@Attribute(.unique)`, optional or defaulted properties, optional relationships.
- For sensitive fields stored in SwiftData, encrypt the field value before persisting — SwiftData itself does not encrypt on-disk content.

## Logging

- Use `os.Logger` with explicit privacy specifiers:

  ```swift
  logger.info("Signed in user: \(userID, privacy: .private)")
  ```

- Anything that could be a name, email, token, ID, or content **must** be `.private`. Default to `.private` and downgrade to `.public` only for known-safe values.

## Code signing and provisioning

- Code-signing certificates and provisioning profiles do not belong in the repo.
- Rotate App Store Connect API keys at least yearly; revoke immediately if a build machine is decommissioned.
- For shared teams, use Fastlane Match with an **encrypted Git repo or S3 bucket** for storage.

## Pre-release checklist

- [ ] No `NSAllowsArbitraryLoads`.
- [ ] No secrets in `Info.plist`, `UserDefaults`, or asset catalogs.
- [ ] All Keychain items use a `ThisDeviceOnly` accessibility class unless you specifically need iCloud sync.
- [ ] All `os.Logger` user data is marked `.private`.
- [ ] Unused entitlements removed.
- [ ] App Privacy answers in App Store Connect match what the app actually collects.
