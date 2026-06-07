# Yoing Release Process

This document describes how Yoing should be versioned, released, and eventually distributed to users.

It is intentionally a process document, not release automation. Do not add signing, notarization, Sparkle, or Homebrew automation until the app has a usable release path.

## Versioning

Yoing uses `v0.x.y` tags while the product is unstable.

- Patch releases fix bugs: `v0.1.1`, `v0.1.2`.
- Minor releases add features: `v0.2.0`, `v0.3.0`.
- `v1.0.0` should wait until the dictation loop, updater, and public distribution process are stable.

Release tags should use this format:

```text
v0.1.0
```

## Distribution Phases

### Phase 1: Source And Development Preview

Use GitHub as the canonical repository for source, issues, pull requests, and early development.

Users can clone the repository and build locally once app code exists. This phase does not promise a public binary download.

### Phase 2: GitHub Releases

GitHub Releases are the first public binary distribution channel.

For public macOS downloads:

- Build the app from a release tag.
- Sign the app with a Developer ID Application certificate.
- Notarize the app with Apple.
- Package the app as a `.dmg` or `.zip`.
- Attach the artifact to the GitHub Release.
- Include release notes and a SHA-256 checksum.

Do not call a release a public binary release unless it is signed and notarized.

### Phase 3: Sparkle Auto-Update

Sparkle should be added after at least one usable public release exists.

Sparkle will provide in-app update checks, release notes, and update installation for direct-distributed macOS builds.

Planned requirements:

- Add Sparkle 2 through Swift Package Manager.
- Configure a stable appcast URL.
- Host the appcast through GitHub Pages or another stable HTTPS endpoint.
- Sign update archives with Sparkle's signing flow.
- Keep GitHub Releases as the source for release artifacts.

Do not add Sparkle before the app has a usable public release to update from.

### Phase 4: Homebrew Cask

Homebrew should be added after GitHub Releases are stable.

Start with a personal tap if official Homebrew Cask maintenance is too much early on. The cask should point to the signed and notarized GitHub release artifact and include a checksum.

Homebrew is useful for developer users, but it is not the primary distribution path for a beginner-friendly menubar app.

## Developer ID Signing And Notarization

Developer ID signing proves the app came from the developer and was not modified after signing.

Notarization submits the signed app to Apple so Gatekeeper can verify that Apple checked the software for known malicious content.

Users may still see the normal "downloaded from the internet" first-launch prompt. Signing and notarization are meant to avoid the more severe Gatekeeper warnings that make a public app feel unsafe or broken.

This requires an Apple Developer Program membership and should be handled only for real public binary releases.

## Release Checklist

Before publishing a public binary release:

- [ ] Confirm the release commit is on `main`.
- [ ] Confirm product docs are current.
- [ ] Confirm no API keys, secrets, local config, or build outputs are committed.
- [ ] Confirm no clipboard or pasteboard behavior was introduced.
- [ ] Create a version tag.
- [ ] Build the app from that tag.
- [ ] Sign the app with Developer ID.
- [ ] Notarize the app.
- [ ] Package the app as `.dmg` or `.zip`.
- [ ] Compute SHA-256 checksum.
- [ ] Create GitHub Release with notes and artifact.
- [ ] Update Sparkle appcast when Sparkle exists.
- [ ] Update Homebrew Cask or tap when Homebrew exists.

## Current Status

Yoing does not have public binary downloads yet.

Sparkle auto-update is planned but not implemented.

Homebrew distribution is planned but not implemented.
