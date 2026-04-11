# OpenClaw Buddy

A native macOS companion app (think Iron Man's Jarvis) that connects to a locally-running
[OpenClaw](https://github.com/openclaw) agent via REST and WebSocket, adding a persistent
menu bar presence, voice I/O, and a conversational chat window.

## Tech Stack

| Concern | Technology |
|---|---|
| UI framework | SwiftUI (declarative, macOS 13+) |
| State management | Combine (`@Published`, `ObservableObject`) |
| Networking | `URLSession` (REST) + `URLSessionWebSocketTask` (streaming) |
| Speech-to-text | Apple Speech framework (`SFSpeechRecognizer`) — on-device |
| Text-to-speech | `AVSpeechSynthesizer` — on-device by default |
| Secrets | macOS Keychain via `Security.framework` |
| Project generation | [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`project.yml`) |

## Minimum Deployment Target

**macOS 13 Ventura** — required for `MenuBarExtra` SwiftUI scene.

## Architecture: MVVM

```
Views/          ← SwiftUI views; read from ViewModels, send user intents
ViewModels/     ← @MainActor ObservableObjects; orchestrate services & models
Models/         ← Plain value types (structs/enums); Codable where needed
Networking/     ← URLSession-based REST + WebSocket clients
Services/       ← Platform integrations (Keychain, Speech, TTS)
Utilities/      ← Constants, SwiftUI/Swift extensions
```

- Views own **no** business logic — they bind to ViewModels only.
- ViewModels own **no** UI framework imports beyond `Combine` / `Foundation`.
- No third-party Swift packages by default; all networking uses Apple frameworks.

## Security Rules

- **Auth tokens and API keys always go through `KeychainService`**, never hardcoded
  in source or stored in `UserDefaults`.
- App Sandbox is enabled; entitlements are the minimum required:
  `network.client`, `device.microphone`, `speech-recognition`.
- Hardened Runtime is on for all build configurations (required for notarization).

## Regenerating the Xcode Project

If you add new files or change build settings, regenerate with:

```bash
xcodegen generate
```

Run from the repo root (where `project.yml` lives). Commit both `project.yml` and
the regenerated `*.xcodeproj/project.pbxproj`.

## Building

```bash
xcodebuild -scheme "OpenClaw Buddy" -destination 'platform=macOS' build
```
