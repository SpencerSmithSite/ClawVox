# Changelog

## Unreleased

### Added
- **V-06** `OpenAITTSService`: calls `/v1/audio/speech` (tts-1 model), downloads full MP3 response, plays back via `AVAudioPlayer`; `isSpeaking` tracked via `AVAudioPlayerDelegate`
- `AppSettings`: replaced `whisperAPIKey` with shared `openAIAPIKey` (used by both Whisper STT and OpenAI TTS); added `openAITTSVoice` field; `SettingsViewModel` migrates legacy Keychain key on first launch
- `ConversationViewModel`: wired `OpenAITTSService`; TTS provider selection routes audio output to Apple TTS or OpenAI TTS at runtime; `openAITTSService.stop()` called on `clearConversation()`
- `SettingsView`: voice picker for OpenAI TTS (alloy/echo/fable/onyx/nova/shimmer); shared API key field shown for Whisper STT and OpenAI TTS providers

### Previous Unreleased
- **F-03** `WebSocketClient`: full `URLSessionWebSocketTask`-based implementation with auto-reconnect (exponential backoff, max 8 attempts), 30-second ping loop, `ConnectionState` publishing, and `PassthroughSubject<WSMessage>` for incoming events
- `WebSocketClientTests`: 3 unit tests covering URL scheme conversion (http→ws, https→wss) and disconnect state — all 6 tests pass

## Previous Unreleased

### Added
- `KeychainService`: full SecItem implementation for save/retrieve/delete of auth tokens
- `SettingsViewModel`: load and persist settings across launches (UserDefaults for non-sensitive fields, Keychain for auth token)
- `TTSService`: implemented `speak()` with `AVSpeechUtterance`; `isSpeaking` tracked via `AVSpeechSynthesizerDelegate`
- `ConversationViewModel`: wired to `OpenClawClient`; `sendMessage()` streams tokens via `streamChat()` and builds live assistant replies
- **F-07** `ClawVoxApp`: `SettingsViewModel` promoted to `@StateObject` and injected as `.environmentObject()` into all three scenes (MenuBar, MainWindow, Settings)
- **F-04** `SettingsView`: fully wired to `SettingsViewModel` via `@EnvironmentObject`; all fields bound (gateway URL, auth token, STT/TTS provider, orb color, hotkey); Save (⌘S) and Reset to Defaults buttons

## 0.1.0 — 2026-04-10

- Initial scaffold: menu bar app, MVVM skeleton, OpenClaw REST/SSE client, stub services
