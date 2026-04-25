# Changelog

## Unreleased

### Added
- **D-01** Release archive build scripts: `Makefile` with `build`, `test`, `archive`, `export`, and `clean` targets; `scripts/ExportOptions.plist` template for Developer ID distribution (developer-id method, automatic signing); `make archive TEAM_ID=XXXXXXXXXX` creates a signed `.xcarchive` under `build/`, `make export` calls `xcodebuild -exportArchive` with the plist; CI targets keep `CODE_SIGNING_ALLOWED=NO` for compatibility with unsigned runners
- **C-03/C-04** Marked OpenAI TTS (`OpenAITTSService`) and Whisper STT (`WhisperSTTService`) providers as complete — both were already implemented and conform to `TTSServiceProtocol` / `STTServiceProtocol` respectively; TODO.md updated to reflect actual state
- **C-05** API key test UI: "Test" button and inline status badge (✓/✗/spinner) added next to every API key field in `SettingsView`; `SettingsViewModel` gains `testOpenAIKey()` (hits `GET /v1/models`) and `testElevenLabsKey()` (hits `GET /v1/user`); test state resets automatically when the key text changes; `APIKeyTestState` enum (`.idle`, `.testing`, `.valid`, `.invalid(String)`) defined in `SettingsViewModel.swift`
- **C-02** ElevenLabs TTS provider: `ElevenLabsTTSService` calls `/v1/text-to-speech/{voice_id}` (`eleven_multilingual_v2` model), downloads MP3 and plays via `AVAudioPlayer`, conforms to `TTSServiceProtocol`; `AppSettings` gains `elevenlabsAPIKey` (Keychain) and `elevenlabsVoiceID` (UserDefaults) with a curated `elevenlabsVoices` list (Rachel, Domi, Bella, Antoni, Elli, Josh, Arnold, Adam, Sam); `SettingsView` shows API key field and voice picker when ElevenLabs is selected; `ConversationViewModel.activeTTSService` now dispatches to the real ElevenLabs backend for `.elevenlabs` provider
- **C-01** Provider protocol architecture: `TTSServiceProtocol` (`speak(_:)`, `stop()`, `isSpeaking`, `isSpeakingPublisher`) and `STTServiceProtocol` (`startListening()`, `stopListening()`, `isListening`, `audioLevel`, `finalTranscript`, publisher accessors) defined in `Services/`; `TTSService`, `OpenAITTSService`, `SpeechService`, and `WhisperSTTService` all conform; `ConversationViewModel` dispatches through `activeTTSService: any TTSServiceProtocol` in `sendMessage()` and stops all backends via `allTTSServices` on `clearConversation()`/`loadConversation(_:)`; Combine subscriptions updated to use protocol publishers (`isSpeakingPublisher`, `isListeningPublisher`, `audioLevelPublisher`)
- **D-05** GitHub Actions CI/CD pipeline: `.github/workflows/ci.yml` triggers on push and PR to `main`; runs `xcodebuild build` and `xcodebuild test` on `macos-14` with code-signing disabled for CI
- **U-07** Connection error surfacing: retry button (↺ `arrow.clockwise`) appears next to the connection badge in both `MainWindowView` header and `MenuBarView` when `connectionState == .error`; `MenuBarView` now shows the full error message from the `ConnectionState.error(String)` associated value instead of a generic label; `ConversationViewModel.checkConnection()` delegates to `client.checkConnection()` to re-test the gateway on demand
- **U-06** Conversation history: `Conversation` model (Codable, auto-title from first user message); `ConversationStore` persists JSON files to `~/Library/Application Support/ClawVox/conversations/`; `ConversationViewModel` auto-saves on `clearConversation()` and exposes `savedConversations`, `loadConversation(_:)`, `deleteConversation(_:)`, `deleteAllConversations()`; `HistoryView` sheet (list, full-text search, swipe-to-delete, clear-all alert, tap-to-load); clock icon in `MainWindowView` header
- **U-05** Glass morphism styling: `View.glassCard(cornerRadius:)` modifier (ultraThinMaterial blur + 0.5 px white hairline border); assistant chat bubbles use glass card; input text field uses glass card; header and input bars use `.ultraThinMaterial` with a hairline separator overlay; user bubbles gain a cyan accent drop shadow (`#00CFFF` at 35% opacity, 12 pt blur)
- **U-04** First-run onboarding wizard: 4-step flow (Welcome → Connect → Voice → Done) shown in `MainWindowView` until `hasCompletedOnboarding` is set; Connect step includes async `/health` test with success/failure feedback; Voice step surfaces STT/TTS provider pickers and OpenAI key field; `SettingsViewModel` gains `hasCompletedOnboarding` (UserDefaults) and `completeOnboarding()` which saves settings and flips the flag
- **U-03** `SettingsView`: Apple TTS voice picker — lists voices filtered to the user's locale, labelled with quality indicators (★ enhanced, ★★ premium); bound to `AppSettings.selectedVoiceIdentifier` which is already wired through `ConversationViewModel.applySettings()` → `TTSService.configure()`

### Previous Unreleased

### Added
- **U-02** `ChatBubbleView`: blinking block-cursor (`▊`) appended to the last assistant message while `isLoading` is true; driven by `TimelineView(.periodic(from:by:))` at 0.6 s per blink; `MainWindowView` identifies the streaming message by matching `messages.last?.id` under `isLoading`
- **U-01** `OrbView`: breathing animation via `TimelineView(.animation)` when `isSpeaking` is true (sine-wave, ~2.4 s period); `color` parameter uses the user's `orbColor` setting instead of a hardcoded value; `MainWindowView` passes `isSpeaking` and `orbColor` to both header and empty-state orbs

### Previous Unreleased

#### Added
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
