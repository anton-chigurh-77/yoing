# Yoing Roadmap

This document is the changeable product roadmap for Yoing. It can evolve as implementation reality changes, but it must not override `product-principles.md`.

Feature-level behavior and implementation checklists live in `features.md`.

## MVP

The MVP proves Yoing's core keyboard-like dictation loop.

- Native macOS menubar app.
- First-run setup for microphone permission.
- First-run setup for accessibility permission.
- Bring-your-own-key setup for xAI.
- Optional bring-your-own-key setup for OpenAI.
- Hold-to-dictate global hotkey.
- Speech-to-text transcription through the selected provider.
- Direct text insertion into the active app.
- Compact menubar status for ready, recording, transcribing, success, and error states.
- No clipboard behavior.
- No default dictation history.
- No account.

## Version 2

Version 2 improves dictation quality, free local availability, and lightweight observability without changing the core product model.

- Apple-native free mode using Apple Speech framework capabilities for local dictation where supported.
- Apple Intelligence cleanup using Foundation Models where available.
- Capability detection before showing Apple-native features:
  - macOS version supports the needed APIs.
  - Apple Intelligence is enabled for Foundation Models.
  - Speech recognition supports the selected locale on device.
- Bring-your-own-key xAI and OpenAI remain the reliable cloud path when Apple-native features are unavailable.
- Optional local-only dictation history for Yoing-generated text.
- Compact menubar graphs for words dictated, sessions, minutes, WPM estimate, provider used, and estimated API spend.
- Dictionary and keyterm support for names, jargon, acronyms, and project terms.
- Basic punctuation and capitalization cleanup.
- Provider and model settings.
- Provider health checks.
- Clear handling for invalid keys, provider errors, timeouts, and rate limits.

## Version 3

Version 3 adds lightweight power-user customization while keeping Yoing focused on typed output.

- Per-app style presets.
- Developer dictation modes for comments, commit messages, issue replies, chat messages, and documentation.
- Minimal custom style rules.
- Import and export for local settings.
- Richer provider routing across Apple-native, xAI, and OpenAI.
- Aggregate privacy-safe usage insights without requiring dictation history.

## Future Scope

Future work can expand reliability and advanced configuration after the core product is stable.

- External local Whisper or WhisperKit support, only if Apple-native coverage is not good enough for key languages, older macOS versions, or accuracy.
- More language controls.
- Better accessibility coverage across complex macOS apps.
- Open-source contributor tooling and diagnostics.

## Explicitly Out Of Scope

- Clipboard feature or clipboard fallback.
- Clipboard monitoring, pasteboard reads, or pasteboard writes.
- Default dictation history.
- Account system.
- Billing.
- Team features.
- Sync.
- Sharing.
- Hosted workspace features.
- General AI chat or document workspace.
