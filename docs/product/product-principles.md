# Yoing Product Principles

This document is the durable product source of truth for Yoing. It should change only when the product direction changes.

Feature-level behavior belongs in `features.md`; this document controls product boundaries.

## Product Identity

Yoing is an open-source native macOS-only menubar speech-to-text app for developers and AI power users.

Yoing behaves like a keyboard:

1. Hold the dictation hotkey.
2. Speak.
3. Release the hotkey.
4. Yoing types the resulting text into the active app.

## Non-Negotiables

- Yoing is macOS-only.
- Yoing is menubar-first.
- Yoing inserts text directly into the active app.
- Yoing must not provide a clipboard feature or clipboard fallback.
- Yoing must never monitor, read, or store the macOS pasteboard.
- Yoing must not keep dictation history by default.
- Yoing may offer optional local-only dictation history for Yoing-generated text.
- Yoing must not require an account.
- Yoing must not include billing, teams, sync, or sharing.
- Yoing must keep API keys in user-controlled local storage.

## AI Provider Policy

Yoing should prefer Apple-native capabilities when they are available.

Apple-native mode is the preferred free path because it avoids external model installs, API keys, and provider usage cost. Its availability depends on macOS version, supported hardware, region and language support, and Apple Intelligence settings.

Yoing also supports bring-your-own-key xAI and OpenAI as remote AI providers for users who want cloud quality or do not have supported Apple-native features.

External local engines such as Whisper or WhisperKit are future optional fallbacks only. They should not become the default path unless Apple-native coverage is not good enough for important languages, older macOS versions, or accuracy.

Provider support exists to improve dictation quality, reliability, and availability, not to turn Yoing into a general AI workspace.

## UI Direction

Yoing's menubar status should be inspired by CodexBar: compact, dark, information-dense, and operational.

Yoing's settings UI should be inspired by Wispr Flow: native-feeling, calm, readable, and direct.

The Wispr Flow reference is for product ergonomics, not feature scope. Yoing should avoid unnecessary surfaces that do not support keyboard-like dictation.

## Privacy Direction

Yoing should keep dictated text in memory only as long as needed to transcribe it, optionally clean it up, and type it into the active app.

If dictation history is enabled, it must store only Yoing-generated dictations locally and must be easy to disable or clear.

The product should prefer explicit user-controlled configuration over hidden persistence.

## Contributor Guidance

When in doubt, choose the smaller feature that preserves the keyboard-like interaction.

Do not add broad workspace, document, team, sharing, clipboard, pasteboard, or transcript-management concepts unless this principles document is intentionally updated first.
