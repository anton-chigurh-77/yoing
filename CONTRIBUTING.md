# Contributing To Yoing

Thanks for helping build Yoing. This project is early, so the most valuable contributions are focused changes that keep the product simple and buildable.

## Contribution Standard

- Keep pull requests focused and reviewable.
- Keep `main` buildable.
- Include verification notes for code changes.
- Update product docs when product behavior changes.
- Do not commit API keys, secrets, local configuration, or build outputs.
- Do not add clipboard or pasteboard reads, writes, monitoring, or fallback behavior.
- Do not add accounts, billing, teams, sync, or sharing.

## Product Boundaries

Yoing is a macOS-only menubar speech-to-text app that behaves like a keyboard.

Do not turn Yoing into:

- A clipboard manager.
- A transcript workspace.
- An account system.
- A team sharing product.
- A billing platform.
- A general AI chat app.

If a change affects product direction, update or discuss the relevant docs first:

- `docs/product/product-principles.md`
- `docs/product/roadmap.md`
- `docs/product/features.md`

## Pull Request Checklist

Use the pull request template when opening a PR. It owns the review checklist for testing, secrets, product boundaries, and documentation updates.

Before opening a pull request, make sure the change has a clear scope, reviewable rationale, and verification notes appropriate to the current state of the app.

## Docs Expectations

Use the product docs as the source of truth for behavior and scope:

- `product-principles.md` controls durable product boundaries.
- `roadmap.md` controls milestone timing.
- `features.md` controls feature-level behavior and implementation status.

Documentation changes should keep those responsibilities separate. Do not turn roadmap notes into product doctrine, and do not add feature behavior to the principles doc unless the product boundary itself changes.
