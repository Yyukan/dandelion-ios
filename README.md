# dandelion-ios

A native iOS app for **OpenCode Zen** (pay-as-you-go) and **OpenCode Go** (subscription) - live balance/usage plus the full model catalog. iOS counterpart to the [macOS menu-bar app](https://github.com/Yyukan/dandelion).

![platform](https://img.shields.io/badge/platform-iOS%2017%2B-lightgrey)
![swift](https://img.shields.io/badge/swift-6.0%2B-orange)

## What it shows

- Zen balance, auto-reload threshold, monthly limit
- Go 5h/weekly/monthly usage windows and reset countdowns
- Zen/Go model catalog: pricing and context/output limits

<p align="center">
  <img src="assets/demo.png" alt="Dandelion demo" width="480">
</p>

## Widgets

- **Lock Screen** — one complication per metric: Balance, 5h, Weekly, Monthly
- **Home Screen** — a single dashboard with all four at a glance

## Requirements

- iOS 17+, Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- An Apple ID in Xcode to sign the app for your device (free personal team is enough)

## Credentials

- **Zen balance** — sign in to the [OpenCode console](https://opencode.ai/console/) once, from the app's in-app browser (Settings → Sign In). Use **GitHub**: Google blocks OAuth inside embedded web views.
- **Go usage** — create an API key at [opencode.ai/docs/go](https://opencode.ai/docs/go) and paste it into Settings. Both credentials are stored in the iOS Keychain only.

## Running locally

```bash
xcodegen generate
open DandelionIOS.xcodeproj
```

Select the **DandelionIOS** scheme, pick your iPhone (or a Simulator), press **Run** (⌘R). First run on a device: pick your team under Signing & Capabilities. The Lock Screen + Home Screen widgets become available in the widget gallery once the host app has been installed.

## License

See [LICENSE](LICENSE).
