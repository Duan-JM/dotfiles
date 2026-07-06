---
name: ios-release-management
description: Manages iOS / macOS app releases — semantic versioning, build numbers, archive, code signing, TestFlight, App Store Connect submission, and changelog workflow. Use when preparing a release, automating distribution, or troubleshooting signing / provisioning issues.
---

# iOS Release Management

## Versioning

Use **Semantic Versioning** for the marketing version, monotonically increasing integers for the build number:

| Field | Xcode key | Format | Example |
|---|---|---|---|
| Marketing | `MARKETING_VERSION` / `CFBundleShortVersionString` | `MAJOR.MINOR.PATCH` | `1.4.2` |
| Build | `CURRENT_PROJECT_VERSION` / `CFBundleVersion` | Integer, strictly increasing | `342` |

- Bump **MAJOR** for breaking UX / data migrations.
- Bump **MINOR** for new features.
- Bump **PATCH** for bug-fix-only releases.
- **Build number must increase** on every upload to App Store Connect (even for the same marketing version).

Common pattern: drive build number from CI run ID or commit count:

```bash
agvtool new-version -all "$(git rev-list --count HEAD)"
agvtool new-marketing-version 1.4.2
```

## Release branch workflow

```
main ──●──●──●──●──●──●──●──  (always shippable)
              \
               release/1.4 ──●──●──  (only fixes; tagged)
```

1. Cut `release/1.4` from `main` once feature work is done.
2. Only bug fixes flow into the release branch.
3. Tag releases on the release branch: `git tag v1.4.2 && git push --tags`.
4. Cherry-pick fixes back to `main`.

## Pre-flight checklist

Before every store submission, verify:

- [ ] Build number incremented vs. previous upload.
- [ ] Marketing version matches release notes.
- [ ] `Info.plist` privacy strings (`NSCameraUsageDescription` etc.) match actual usage.
- [ ] App Transport Security (`NSAppTransportSecurity`) has no leftover `NSAllowsArbitraryLoads`.
- [ ] Debug-only code paths (`#if DEBUG`) compile in Release.
- [ ] No `print(...)` in user-action error paths — surface errors via UI instead.
- [ ] No leftover `TODO` / `FIXME` on critical paths.
- [ ] Localizations exported and reviewed for new keys.
- [ ] Tests green on the release branch in CI.
- [ ] Crash symbols (dSYMs) will be uploaded (Xcode Organizer or Fastlane).

## Code signing

Prefer **Automatic Signing** for solo / small teams. For larger teams or CI, use **Manual Signing** with profiles managed by Fastlane Match:

```bash
fastlane match appstore --readonly       # CI / build machine
fastlane match appstore                  # team lead, rotates certs
```

- Never commit `.p12`, `.cer`, `.mobileprovision`, or App Store API keys to the repo.
- Store API key and Match Git password in CI secrets only.
- App Store Connect API key (`.p8`) goes in `~/.appstoreconnect/private_keys/` locally.

## Archive and upload

Locally with Xcode: Product → Archive → Distribute App → App Store Connect.

CI (Fastlane):

```ruby
lane :beta do
  match(type: "appstore", readonly: true)
  build_app(scheme: "MyApp", export_method: "app-store")
  upload_to_testflight(skip_waiting_for_build_processing: true)
end
```

CI (xcodebuild + altool):

```bash
xcodebuild -scheme MyApp -archivePath build/MyApp.xcarchive archive
xcodebuild -exportArchive -archivePath build/MyApp.xcarchive \
    -exportPath build/Export -exportOptionsPlist ExportOptions.plist
xcrun altool --upload-app -f build/Export/MyApp.ipa \
    --type ios --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
```

## TestFlight

- Internal testers (up to 100 App Store Connect users) → no review, available in minutes.
- External testers (up to 10,000) → require a beta review on the first build of each marketing version. Subsequent builds of the same marketing version skip review unless they trigger sensitive entitlements changes.
- Always test crash-report symbolication on a TestFlight build, not just Debug.

## Release notes

Maintain a `CHANGELOG.md` using Keep a Changelog format. On release:

```markdown
## [1.4.2] - 2026-05-21

### Added
- Library sort by date added.

### Fixed
- Crash when opening empty album.
```

App Store "What's New" should be a **user-facing summary** of `Added` + `Fixed`, not the raw changelog.

## Phased release and rollback

- Use **phased release** in App Store Connect for non-critical updates — exposes to 1% → 100% over 7 days.
- For critical fixes, skip phased release and ship to 100%.
- "Rollback" on iOS is a re-submission of the prior version with a higher build number — there is no instant rollback. Treat the first 24h post-release as critical monitoring window.
