# ClawVox — macOS Companion App
### Project Overview & Architecture

---

## Vision

A native macOS "Jarvis" companion that lets you talk — by voice or text — to your OpenClaw agent, hear it talk back, and watch it act on your behalf. Visually striking, privately hosted, beautifully simple.

> Design aesthetic: glowing particle-orb on a dark background. Alive when listening, animated when thinking, calm when idle.

---

## What It Is (and Isn't)

**Is:** A beautiful, voice-first frontend for interacting with any running OpenClaw instance.  
**Is not:** An OpenClaw management dashboard (OpenClaw already ships one).

---

## Core Feature Set

### 1. Connection
- Connect to OpenClaw Gateway running locally (`localhost:18789` default)
- Connect over local network (IP/hostname)
- Connect over Tailscale (automatic peer discovery or manual address)
- Bearer token authentication
- Connection health indicator + auto-reconnect

### 2. Voice In (Speech-to-Text)
- **Local (default):** Apple Speech Recognition framework — fully on-device, no data leaves the machine
- **Optional cloud:** OpenAI Whisper API or similar — higher accuracy, user opt-in
- Push-to-talk (keyboard shortcut / button) or always-on wake-word mode

### 3. Voice Out (Text-to-Speech)
- **Local (default):** Apple AVSpeechSynthesizer — zero latency, no network
- **Optional cloud:** ElevenLabs, OpenAI TTS — premium voice quality, user opt-in
- Voice selection, speed, pitch controls

### 4. Conversation UI
- Floating chat window (main surface)
- Animated orb / audio visualizer — the "face" of the assistant
- Streaming response display (tokens as they arrive)
- Conversation history (session-scoped)

### 5. Menu Bar Integration
- Persistent menu bar icon
- Quick-access popover for fast queries
- Mute/unmute, connection status, settings shortcut

### 6. Settings
- OpenClaw connection (URL, port, auth token)
- STT provider selection + API key storage (Keychain)
- TTS provider + voice selection
- Hotkey configuration
- Appearance (theme/orb color)
- Privacy controls (clear history, disable logging)

---

## Technical Architecture

```
┌─────────────────────────────────────────────────────┐
│                    ClawVox App                        │
│                                                       │
│  ┌────────────┐   ┌──────────────┐   ┌────────────┐  │
│  │  SwiftUI   │   │  Voice Layer │   │  Settings  │  │
│  │    Views   │   │ STT + TTS    │   │  (SwiftUI) │  │
│  └─────┬──────┘   └──────┬───────┘   └─────┬──────┘  │
│        │                 │                 │          │
│        └─────────────────▼─────────────────┘          │
│                   ┌──────────────┐                    │
│                   │  ViewModel / │                    │
│                   │  State Layer │                    │
│                   │  (Combine)   │                    │
│                   └──────┬───────┘                    │
│                          │                           │
│              ┌───────────▼───────────┐               │
│              │   OpenClaw Client     │               │
│              │  REST + WebSocket     │               │
│              │  Bearer Auth          │               │
│              └───────────┬───────────┘               │
└──────────────────────────┼────────────────────────────┘
                           │
              ┌────────────▼────────────┐
              │   OpenClaw Gateway      │
              │  localhost:18789        │
              │  or LAN / Tailscale     │
              └─────────────────────────┘
```

### Tech Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| UI Framework | SwiftUI | Native macOS, best system integration |
| State Management | Combine + ObservableObject | Apple-native reactive |
| Networking | URLSession + URLSessionWebSocketTask | Built-in, no dependencies |
| STT (local) | Apple Speech framework | On-device, private |
| STT (cloud) | OpenAI Whisper (optional) | Higher accuracy |
| TTS (local) | AVSpeechSynthesizer | Zero latency, private |
| TTS (cloud) | ElevenLabs / OpenAI TTS (optional) | Premium voice |
| Credential storage | Keychain | Secure, native |
| Distribution | .pkg + Homebrew Cask | Both install paths |

---

## OpenClaw API Integration Points

| Endpoint | Purpose |
|----------|---------|
| `POST /v1/chat/completions` | Send messages (OpenAI-compatible, streaming) |
| `POST /api/sessions/{id}/messages` | Session-based messaging |
| `WS ws://host:18789/` | Real-time WebSocket control plane |
| `GET /api/sessions` | List sessions / history |
| Bearer token header | Auth on all requests |

---

## Distribution Plan

### Option A — Direct Download (.pkg)
- Signed + notarized with Apple Developer certificate
- PKG installer drops app into /Applications
- Hosted on project website

### Option B — Homebrew Cask
- `brew install --cask clawvox` (or similar name)
- Cask formula hosted in a custom tap or submitted to homebrew-cask
- Auto-update via `brew upgrade`

---

## Privacy Principles

1. **Local by default** — all AI inference, STT, and TTS run on-device unless user opts out
2. **Zero telemetry** — no analytics, no crash reporting without explicit consent
3. **Credential security** — API keys stored only in macOS Keychain, never in plaintext
4. **Open source** — auditable codebase

---

## Project Phases

| Phase | Name | Description |
|-------|------|-------------|
| 0 | Research | Finalize API contract, voice framework choices, distribution tooling |
| 1 | Foundation | Xcode project setup, OpenClaw client (REST + WS), basic chat UI |
| 2 | Voice | STT integration (Apple Speech), TTS integration (AVSpeechSynthesizer) |
| 3 | Polish UI | Animated orb, dark theme, streaming text, full settings panel |
| 4 | Cloud Voice | Optional ElevenLabs/OpenAI TTS + Whisper STT with Keychain storage |
| 5 | Distribution | Code signing, notarization, .pkg build, Homebrew Cask formula |
| 6 | Beta | Dogfooding, bug fixes, UX polish |

---

## Open Questions (Research Phase)

- [ ] Does OpenClaw WS protocol require a specific handshake/message format beyond standard Bearer auth?
- [ ] Can we use the `/v1/chat/completions` streaming endpoint for all chat, or do we need session-specific endpoints for history?
- [ ] What is the recommended Homebrew Cask tap strategy for a new independent project?
- [ ] Should the orb be a Metal shader, SceneKit, or SpriteKit animation?
- [ ] SwiftUI or AppKit for the menu bar popover? (SwiftUI `MenuBarExtra` available since macOS 13)
- [ ] Minimum macOS version target? (Recommend macOS 13 Ventura for `MenuBarExtra` + latest Speech APIs)
