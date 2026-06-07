# Yoing Feature Catalog

This document is the implementation-facing feature catalog for Yoing. It lists the product feature set, intended behavior, and acceptance notes without replacing `product-principles.md` or `roadmap.md`.

Status values track implementation progress:

- `Planned`: not implemented or not yet verified.
- `Implemented`: implemented and verified.

`product-principles.md` controls product boundaries. `roadmap.md` controls milestone timing. This file controls feature-level behavior.

## Feature Status

| Feature | Status |
| --- | --- |
| [Core Dictation Loop](#core-dictation-loop) | Planned |
| [macOS Permissions](#macos-permissions) | Planned |
| [Direct Text Insertion](#direct-text-insertion) | Planned |
| [Provider Setup](#provider-setup) | Planned |
| [Apple-Native Free Mode](#apple-native-free-mode) | Planned |
| [Menubar HUD](#menubar-hud) | Planned |
| [Menubar Stats And Graphs](#menubar-stats-and-graphs) | Planned |
| [Optional Dictation History](#optional-dictation-history) | Planned |
| [Cleanup And Formatting](#cleanup-and-formatting) | Planned |
| [Dictionary And Keyterms](#dictionary-and-keyterms) | Planned |
| [Settings App](#settings-app) | Planned |
| [Future Local Whisper Fallback](#future-local-whisper-fallback) | Planned |

## Core Dictation Loop

- Phase: MVP
- Purpose: Prove Yoing's keyboard-like speech-to-text loop.
- User behavior: The user holds a global hotkey, speaks, releases the hotkey, and Yoing types the result into the active app.
- UI surface: Menubar icon, compact recording state, and transient success or error feedback.
- Privacy and persistence: Audio and transcript text are kept only as long as needed to transcribe, clean up, and type the result unless opt-in dictation history is enabled.

Feature checklist:

- [ ] Support hold-to-dictate global hotkey.
- [ ] Record speech only while the hotkey is active.
- [ ] Send captured audio to the selected transcription provider.
- [ ] Type the final transcription into the active app.
- [ ] Never use clipboard or pasteboard behavior in the dictation loop.

Acceptance notes:

- Releasing the hotkey ends capture and starts finalization.
- If transcription fails, Yoing shows an error state without copying text anywhere.
- The feature is not complete if any path reads from or writes to the pasteboard.

## macOS Permissions

- Phase: MVP
- Purpose: Make required macOS permissions understandable and recoverable.
- User behavior: The user can see which permissions are missing and open the right system settings to fix them.
- UI surface: First-run setup, settings app, and menubar health state.
- Privacy and persistence: Permission state can be cached as app configuration, but no audio or transcript content is stored for permission checks.

Feature checklist:

- [ ] Request microphone permission.
- [ ] Request accessibility permission for keyboard-like text insertion.
- [ ] Show permission health state in setup and settings.
- [ ] Provide recovery instructions when permission is denied or revoked.

Acceptance notes:

- Yoing must not start dictation until microphone permission is available.
- Yoing must not claim typing is ready until accessibility insertion is available.
- Permission recovery should be possible without restarting the app when macOS allows it.

## Direct Text Insertion

- Phase: MVP
- Purpose: Make Yoing behave like a keyboard, not a clipboard manager.
- User behavior: After dictation finishes, text appears in the currently focused text target.
- UI surface: No persistent UI required; failures appear in the menubar HUD.
- Privacy and persistence: The insertion service must not use clipboard reads, clipboard writes, pasteboard reads, or pasteboard writes.

Feature checklist:

- [ ] Inject text through macOS keyboard-like or accessibility event behavior.
- [ ] Target the active app and focused text field at insertion time.
- [ ] Handle insertion failure without clipboard fallback.
- [ ] Offer retry or discard when insertion fails.

Acceptance notes:

- Successful insertion should not change the user's clipboard contents.
- Failure handling must not silently store dictated text.
- Direct insertion should be tested in common editors, browsers, chat apps, and terminal-like surfaces where allowed.

## Provider Setup

- Phase: MVP
- Purpose: Let users choose a speech-to-text provider without accounts or Yoing-hosted billing.
- User behavior: The user adds their own provider key, selects a provider/model, and can verify whether it works.
- UI surface: First-run setup, settings app, and menubar provider status.
- Privacy and persistence: API keys are stored locally in user-controlled secure storage. Provider settings can be stored locally.

Feature checklist:

- [ ] Support xAI bring-your-own-key setup.
- [ ] Support OpenAI bring-your-own-key setup.
- [ ] Store credentials locally in secure storage.
- [ ] Support provider and model selection.
- [ ] Show provider/key health without exposing secret values.

Acceptance notes:

- Yoing must not require a Yoing account to use provider keys.
- Invalid keys should produce actionable errors.
- Provider setup must not weaken the no-clipboard rule.

## Apple-Native Free Mode

- Phase: V2
- Purpose: Provide a free local path without external model downloads or bundled ML runtimes.
- User behavior: When supported, the user can choose Apple-native local dictation and Apple Intelligence cleanup instead of a cloud provider.
- UI surface: Provider/settings area, capability messaging, and menubar provider status.
- Privacy and persistence: Apple-native mode should keep processing local where Apple's APIs support it. Availability state may be stored locally.

Feature checklist:

- [ ] Detect Apple Speech local dictation capability.
- [ ] Detect Foundation Models cleanup capability.
- [ ] Check macOS version support before showing Apple-native features.
- [ ] Check whether Apple Intelligence is enabled before offering Foundation Models cleanup.
- [ ] Check whether selected speech locale is supported on device.
- [ ] Hide or disable unsupported Apple-native controls with clear explanation.
- [ ] Avoid external model downloads for Apple-native mode.

Acceptance notes:

- Apple-native mode is preferred before external local models.
- BYOK xAI/OpenAI must remain available when Apple-native features are unsupported.
- The product must not imply Apple-native mode is available on every Mac, region, language, or macOS version.

## Menubar HUD

- Phase: MVP
- Purpose: Give users a compact operational view of Yoing without opening the settings app.
- User behavior: The user can quickly tell whether Yoing is ready, recording, transcribing, successful, or blocked.
- UI surface: CodexBar-inspired dark menubar popover.
- Privacy and persistence: The HUD can show state and aggregate stats, but should not expose transcript content unless dictation history is explicitly enabled and the user opens that surface.

Feature checklist:

- [ ] Ready state.
- [ ] Recording state.
- [ ] Transcribing state.
- [ ] Success state.
- [ ] Error state.
- [ ] Provider/key status.
- [ ] Permission health status.

Acceptance notes:

- HUD state changes should be fast enough to make dictation feel responsive.
- Errors should be short and actionable.
- The HUD should not become a document editor or transcript feed.

## Menubar Stats And Graphs

- Phase: V2
- Purpose: Make usage feel visible, cute, and useful without requiring transcript storage.
- User behavior: The user can open the menubar popover and see lightweight dictation usage over time.
- UI surface: Menubar popover only.
- Privacy and persistence: Store aggregate counters locally. Do not require transcript text to produce graphs.

Feature checklist:

- [ ] Track words dictated.
- [ ] Track dictation sessions.
- [ ] Track minutes dictated.
- [ ] Estimate WPM.
- [ ] Track provider used.
- [ ] Estimate API spend where provider data makes it practical.
- [ ] Render compact menubar graphs from aggregate counters.
- [ ] Keep stats working when dictation history is off.

Acceptance notes:

- Stats must not depend on clipboard monitoring.
- Stats must not require transcript history.
- Spend estimates should be labeled as estimates when provider data is incomplete.

## Optional Dictation History

- Phase: V2
- Purpose: Let users review Yoing-generated dictations when they explicitly choose that tradeoff.
- User behavior: The user can turn history on, view prior Yoing dictations, and clear them.
- UI surface: Settings toggle and history surface inside the app or menubar, depending on later UI design.
- Privacy and persistence: Off by default. Local-only. Stores only Yoing-generated dictation text. Never stores clipboard history.

Feature checklist:

- [ ] Keep dictation history off by default.
- [ ] Store history locally only when enabled.
- [ ] Store only Yoing-generated text.
- [ ] Provide delete controls for individual entries.
- [ ] Provide clear-all control.
- [ ] Never monitor or import clipboard history.

Acceptance notes:

- Enabling history must be explicit.
- Disabling history should stop future storage.
- Clearing history should remove persisted dictation text while preserving aggregate stats where possible.

## Cleanup And Formatting

- Phase: V2
- Purpose: Improve dictated output before insertion while preserving the direct typing model.
- User behavior: The user can enable cleanup rules that make dictated text more usable in their current context.
- UI surface: Settings app and provider/model routing state.
- Privacy and persistence: Cleanup should run in memory unless history is enabled. Provider choice determines whether cleanup is local or remote.

Feature checklist:

- [ ] Punctuation cleanup.
- [ ] Casing cleanup.
- [ ] Concise rewrite.
- [ ] Developer-oriented cleanup.
- [ ] Route cleanup to Apple-native, xAI, or OpenAI based on availability and user settings.

Acceptance notes:

- Cleanup must happen before direct insertion.
- Cleanup must not turn Yoing into a general chat or document workspace.
- Remote cleanup must be clearly tied to the selected provider.

## Dictionary And Keyterms

- Phase: V2
- Purpose: Improve recognition of names, acronyms, project terms, and domain-specific words.
- User behavior: The user can add terms that Yoing should recognize or prefer during transcription.
- UI surface: Settings app.
- Privacy and persistence: Terms are stored locally. Provider prompt/keyterm integration may send relevant terms to the selected transcription provider during dictation.

Feature checklist:

- [ ] Support names.
- [ ] Support acronyms.
- [ ] Support project terms.
- [ ] Store keyterms locally.
- [ ] Integrate keyterms into provider prompts or provider-specific keyterm APIs where supported.

Acceptance notes:

- The user should understand that cloud providers may receive relevant keyterms when cloud dictation is selected.
- Keyterms should improve dictation without requiring transcript history.
- Dictionary behavior must respect provider capability differences.

## Settings App

- Phase: MVP
- Purpose: Provide a focused macOS settings surface for setup and control.
- User behavior: The user can configure Yoing without navigating a broad workspace UI.
- UI surface: Wispr Flow-inspired native settings app.
- Privacy and persistence: Settings are local. Secrets use secure storage. No account, sync, billing, team, or sharing settings.

Feature checklist:

- [ ] Providers settings.
- [ ] Hotkey settings.
- [ ] Microphone settings.
- [ ] Permissions settings.
- [ ] History toggle.
- [ ] Apple-native availability state.
- [ ] Privacy controls.

Acceptance notes:

- Settings should support the dictation product, not become a general workspace.
- Unsupported features should be explained without cluttering the MVP.
- Settings must preserve the no-account and no-clipboard product boundaries.

## Future Local Whisper Fallback

- Phase: Future
- Purpose: Provide an external local model fallback only if Apple-native coverage is insufficient.
- User behavior: The user may explicitly choose a local Whisper or WhisperKit path after seeing model, download, and resource requirements.
- UI surface: Future provider/settings area.
- Privacy and persistence: Local processing should remain local. Model files and related configuration are explicit user-controlled choices.

Feature checklist:

- [ ] Keep Whisper or WhisperKit out of MVP and V2 default scope.
- [ ] Evaluate only if Apple-native coverage is insufficient for key languages.
- [ ] Evaluate only if older macOS support needs it.
- [ ] Evaluate only if accuracy requires it.
- [ ] Show model size, download, and RAM expectations before activation.
- [ ] Require explicit user choice before any external model download.

Acceptance notes:

- This feature must not be used to justify external downloads in Apple-native free mode.
- This feature must remain optional and future-scoped until deliberately promoted.
- BYOK and Apple-native paths should remain simpler than this fallback.
