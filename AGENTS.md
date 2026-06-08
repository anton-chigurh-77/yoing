# Yoing Agent Guidance

After implementing any new feature or behavior, run basic verification before handing off.

- Always report which checks were run.
- Always report any skipped checks and why they were skipped.
- Prefer targeted behavior verification for the surface you changed, not only a compile check.

For menu bar, popover, and Settings changes, verify at minimum:

- The app builds.
- Tests pass.
- Yoing launches.
- The menu bar popover opens.
- Settings opens from the popover.
- Settings can close and reopen.
- Affected buttons still work.
- `git diff --check` passes.
