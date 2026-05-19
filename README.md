# Oasis

iOS native ambient mixer for sleep, focus, work, and rest. 35 hand-curated field recordings, immersive sound placement, and four binaural modes. One-time lifetime purchase via RevenueCat — **no subscription, ever**.

- Bundle ID `com.jonathanluquet.drift` — version **1.5.0** (build 6)
- iOS 16+, portrait, dark, offline (~310 MB audio bundle)
- Localised in 6 languages: en-US, fr-FR, de-DE, es-ES, it, pt-BR

## Documentation

The complete project knowledge — architecture, audio engine, paywall logic, ASO strategy, release process, and more — lives under [`docs/ai/`](docs/ai/) and is structured for AI agents (Claude, ChatGPT, Cursor, Codex, …).

**Start here:** [`AGENTS.md`](AGENTS.md) — universal entrypoint with a project snapshot, reading paths, and the memory-update protocol.

If you prefer asking an AI rather than reading files yourself: paste `AGENTS.md` into your assistant of choice, then ask. The memory is designed to be navigated that way.

## Build (CLI)

```bash
xcodebuild -scheme OasisNative -project "ios-native/OasisNative.xcodeproj" \
  -configuration Debug -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" \
  build CODE_SIGNING_ALLOWED=NO
```

For everything else (UI tests, fastlane lanes, screenshot rendering, release process), see [`docs/ai/codebase/build-and-test.md`](docs/ai/codebase/build-and-test.md) and [`docs/ai/operations/release-process.md`](docs/ai/operations/release-process.md).
