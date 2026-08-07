# dandelion-ios

A native iOS app for **OpenCode Zen** (pay-as-you-go) and **OpenCode Go** (subscription) - live balance/usage plus the full model catalog, no browser or CLI required. iOS counterpart to the [macOS menu-bar app](https://github.com/Yyukan/dandelion).

![platform](https://img.shields.io/badge/platform-iOS%2017%2B-lightgrey)
![swift](https://img.shields.io/badge/swift-6.0%2B-orange)

## What it shows

- Zen balance, auto-reload threshold, monthly limit
- Go 5h/weekly/monthly usage windows and reset countdowns
- Zen/Go model catalog: pricing and context/output limits

## Requirements

- iOS 17+, Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- An Apple ID in Xcode to sign the app for your device (free personal team is enough)

## Running locally

```bash
xcodegen generate
open DandelionIOS.xcodeproj
```

Select the **DandelionIOS** scheme, pick your iPhone (or a Simulator), press **Run** (⌘R). First run on a device: pick your team under Signing & Capabilities.

## License

See [LICENSE](LICENSE).
