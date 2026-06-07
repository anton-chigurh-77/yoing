# Yoing

Yoing is an open-source native macOS-only menubar speech-to-text app for developers and AI power users.

The product goal is simple: hold a hotkey, speak, release, and Yoing types the transcribed text into the active app like a keyboard.

## Current Status

Yoing has an MVP SwiftPM macOS app scaffold with a local development-preview app bundle. There is no public binary download yet.

See the roadmap for planned sequencing and the feature catalog for implementation status.

## Development Preview

Build, stage, and open the local app bundle:

```sh
./script/build_and_run.sh
```

The script creates:

```text
dist/Yoing.app
```

Run verification:

```sh
swift build
swift test
./script/build_and_run.sh --verify
```

To try the MVP loop, open Yoing from the menu bar, grant microphone and accessibility permissions, save an xAI API key in Settings, then hold Option Space to dictate.

## Product Docs

- [Product Principles](docs/product/product-principles.md)
- [Roadmap](docs/product/roadmap.md)
- [Feature Catalog](docs/product/features.md)
- [Release Process](docs/project/release-process.md)

## Distribution Status

Public binary downloads are not available yet.

Release and distribution mechanics are documented in the release process.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

Contributors should preserve Yoing's core product boundary: Yoing behaves like a keyboard and must not become a clipboard manager, transcript workspace, account system, or general AI chat app.

## License

Yoing is licensed under the [MIT License](LICENSE).
