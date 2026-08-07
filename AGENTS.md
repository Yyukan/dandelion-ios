# AGENTS.md

Instructions for AI coding agents working in this repo. Humans should read `README.md` instead.

## Project

Dandelion (iOS) is a native iPhone app (SwiftUI, Swift 6, iOS 17+) for OpenCode Zen/Go balance and usage: live balance/usage plus the full model catalog.

## Build & run

The `.xcodeproj` is generated from `project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen) and is not checked in.

```bash
xcodegen generate
xcodebuild -project DandelionIOS.xcodeproj -scheme DandelionIOS -sdk iphonesimulator build
```

To run on a physical iPhone over USB: open `DandelionIOS.xcodeproj` in Xcode, select your iPhone as the run destination, pick your personal team under **Signing & Capabilities** (signing is `Automatic`), and press **Run** (⌘R).

Note: the project/target/scheme are named `DandelionIOS`, but the app itself still displays as "Dandelion" on the home screen (`CFBundleDisplayName` in `project.yml`).

## Conventions

- No local API key/auth.json discovery and no cross-app browser cookie discovery exist here - both are impossible inside the iOS sandbox. See `DandelionIOS/Services/SessionAuthService.swift` for the replacement: a one-time sign-in through an in-app `WKWebView` (`DandelionIOS/UI/SignInWebView.swift`) backed by the app's own `WKWebsiteDataStore.default()`, which auto-detects the resulting cookie via a `WKHTTPCookieStoreObserver`. (An `ASWebAuthenticationSession`-based approach was tried first, but its non-ephemeral cookie jar is shared with Safari, not with the host app's own `WKWebsiteDataStore` - so the captured cookie was never actually observable here.)
- The model catalog (`ModelCatalogService`) needs no credential at all - `models.dev`'s catalog is public - so it always loads.
- Ring/circle gauges (`RingGaugeView`) size via `TerminalTheme.Metrics.primaryRingSize`/`secondaryRingSize`, not per-call-site magic numbers - keep new call sites consistent with that.
- Every live-data widget (Zen balance, Go usage) must degrade gracefully to an `unavailable`/`sessionExpired` fallback state (with a Sign In button) instead of crashing when no session cookie exists yet or the private endpoint fails - never assume the endpoint succeeds.
- Follow the existing SwiftUI file layout: header doc comment block, then `import SwiftUI`, main view struct, private helper views, `#Preview` at the bottom.

## Git / commits

- Stage changes (`git add`) but do not commit or push unless explicitly asked to.
- Do not push unless explicitly asked.

## Style

- Be short and on point; don't add extra explanations or code examples unless asked.
- When explaining code, reference file name and line numbers.
