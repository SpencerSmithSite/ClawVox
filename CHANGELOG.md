# Changelog

## Unreleased

### Added
- `KeychainService`: full SecItem implementation for save/retrieve/delete of auth tokens
- `SettingsViewModel`: load and persist settings across launches (UserDefaults for non-sensitive fields, Keychain for auth token)
- `TTSService`: implemented `speak()` with `AVSpeechUtterance`; `isSpeaking` tracked via `AVSpeechSynthesizerDelegate`
- `ConversationViewModel`: wired to `OpenClawClient`; `sendMessage()` streams tokens via `streamChat()` and builds live assistant replies

## 0.1.0 — 2026-04-10

- Initial scaffold: menu bar app, MVVM skeleton, OpenClaw REST/SSE client, stub services
