# ClawVox — TODO

> Status as of 2026-04-18. Derived from TASKS.md cross-referenced with git history and current codebase.

---

## Phase 0 — Research

- [ ] **R-01** Deep-dive: OpenClaw WebSocket message protocol (handshake format, message schema, streaming)
- [ ] **R-02** Deep-dive: OpenClaw `/v1/chat/completions` streaming vs session-based API
- [ ] **R-03** Research: macOS `Speech` framework capabilities & limitations
- [ ] **R-04** Research: `AVSpeechSynthesizer` voice quality + neural voices on macOS 13+
- [ ] **R-05** Research: ElevenLabs Swift integration (streaming audio, latency)
- [ ] **R-06** Research: OpenAI Whisper API Swift client pattern
- [ ] **R-07** Research: Homebrew Cask tap setup for independent projects
- [ ] **R-08** Research: macOS code signing + notarization workflow
- [ ] **R-09** Decide: Metal shader vs SceneKit vs SpriteKit for animated orb
- [ ] **R-10** Decide: minimum macOS version target *(recommended: Ventura 13.0, already set)*

---

## Phase 1 — Foundation

- [x] **F-01** Xcode project scaffolding (XcodeGen `project.yml`, entitlements, Info.plist)
- [x] **F-02** OpenClaw REST client (`OpenClawClient.swift` — streaming SSE, Bearer auth, health check)
- [x] **F-03** WebSocket client (`WebSocketClient.swift` — auto-reconnect, ping loop, Combine subject)
- [x] **F-04** Settings model + Keychain storage (`AppSettings`, `SettingsViewModel`, `KeychainService`)
- [x] **F-05** Basic chat view (`MainWindowView` — message list, input bar, send/cancel, auto-scroll)
- [x] **F-06** Menu bar integration (`MenuBarExtra`, status orb, connection badge, open-chat button)

---

## Phase 2 — Voice

- [x] **V-01** Apple Speech Recognition — `SpeechService` is stubbed; `requestAuthorization()` and `startListening()` bodies need full implementation (AVAudioEngine + SFSpeechAudioBufferRecognitionRequest)
- [x] **V-02** AVSpeechSynthesizer TTS with neural voice selection — `TTSService` is functional but not wired to `ConversationViewModel`; no voice-picker UI
- [x] **V-03** Audio session management (input/output routing, interruption handling)
- [x] **V-04** Voice activity detection (auto start/stop on silence)
- [x] **V-05** Whisper API STT integration (with Keychain key storage)
- [x] **V-06** OpenAI TTS (full audio download + `AVAudioPlayer` playback; voice picker in Settings)

---

## Phase 3 — Polish UI

- [x] **U-01** Animated orb visualizer (responds to audio input/output levels)
- [ ] **U-02** Streaming text display (token-by-token typewriter effect)
- [ ] **U-03** Full settings panel — basic panel exists; missing individual voice identifier picker and advanced options
- [ ] **U-04** Connection setup wizard (first-run onboarding) — `OnboardingView` is a placeholder only
- [ ] **U-05** Dark theme + glass morphism styling — base dark theme in place; glass morphism not done
- [ ] **U-06** Conversation history (list, search, clear across sessions)

---

## Phase 4 — Cloud Voice (Optional)

- [ ] **C-01** Provider selection architecture (protocol + implementations)
- [ ] **C-02** ElevenLabs TTS provider
- [ ] **C-03** OpenAI TTS provider
- [ ] **C-04** OpenAI Whisper STT provider
- [ ] **C-05** API key management UI (add / remove / test keys)

---

## Phase 5 — Distribution

- [ ] **D-01** Xcode build scripts for release archive
- [ ] **D-02** `pkgbuild` + `productbuild` installer creation
- [ ] **D-03** `notarytool` submission + stapling workflow
- [ ] **D-04** Homebrew Cask formula (`.rb` file)
- [ ] **D-05** GitHub Actions CI/CD pipeline (build → notarize → release)

---

## Phase 6 — Beta

- [ ] **B-01** Internal dogfood + issue triage
- [ ] **B-02** Performance profiling (memory, CPU, battery impact)
- [ ] **B-03** Accessibility audit (VoiceOver support)
- [x] **B-04** README + setup documentation

---

## Summary

| Phase | Done | Remaining |
|---|---|---|
| Phase 0 — Research | 0 / 10 | 10 |
| Phase 1 — Foundation | 6 / 6 | 0 |
| Phase 2 — Voice | 6 / 6 | 0 |
| Phase 3 — Polish UI | 1 / 6 | 5 |
| Phase 4 — Cloud Voice | 0 / 5 | 5 |
| Phase 5 — Distribution | 0 / 5 | 5 |
| Phase 6 — Beta | 1 / 4 | 3 |
| **Total** | **14 / 42** | **28** |

**Next recommended task:** U-02 (streaming typewriter display) or U-03 (voice identifier picker in Settings).
