# AGENTS.md

This file is the working contract for agentic coding assistants in this repository.

Future implementation work in this repository must follow this file.
If a feature, workflow, behavior, command, or product rule changes, update the relevant docs in the same change.

## Project Summary

- `Vigil/` contains the macOS app code.
- `VigilTests/` contains XCTest unit tests.
- `plugin/` contains the OpenCode plugin written in TypeScript for Bun.
- `project.yml` defines the XcodeGen project structure.
- `README.md` is the main contributor-facing entry point.
- `docs/` holds supporting product and engineering documentation.

This repo is a dual-stack project:

- Swift/AppKit/SwiftUI macOS menu bar app
- Bun + TypeScript OpenCode plugin

## Rule Files

Repository-specific rule files were checked before writing this document.

- No root-level `AGENTS.md` existed before this one.
- No `.cursorrules` file exists in this repo.
- No `.cursor/rules/` directory exists in this repo.
- No `.github/copilot-instructions.md` file exists in this repo.

If any of those files are added later, merge their guidance into future edits of `AGENTS.md` and keep all rule sources consistent.

## Tooling And Dependencies

- Xcode
- XcodeGen
- Bun
- TypeScript (installed under `plugin/node_modules`)

## Build Commands

Generate the Xcode project:

```bash
make generate
```

Build the macOS app:

```bash
make build
```

Direct build command:

```bash
xcodegen generate
xcodebuild build -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS'
```

## Test Commands

Run the full macOS XCTest suite:

```bash
make test
```

Run the full plugin checks:

```bash
make test-plugin
```

Package scripts from `plugin/package.json`:

```bash
cd plugin && bun test
cd plugin && bun run typecheck
```

## Single-Test Workflows

Run a single XCTest method:

```bash
xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/StatusItemPopoverControllerTests/testDismissMonitorClosesOnFirstOutsideClickOnly
```

Run a single plugin test file:

```bash
cd plugin && bun test test/transport.test.ts
```

Run a single plugin test by name:

```bash
cd plugin && bun test --test-name-pattern "sends bearer token header"
```

## Lint / Formatting Status

There is currently no dedicated repository lint command and no standalone formatting command wired into `Makefile`.

Do not invent `lint` or `format` commands in documentation or task summaries.
Use the real verification surface that exists today:

- Swift: `make test` or targeted `xcodebuild test`
- Plugin tests: `bun test`
- Plugin type safety: `tsc --noEmit`

## Swift Code Guidelines

- Use `import` lines only for modules the file actually needs.
- Follow the existing style of one import per line.
- Prefer `Foundation`-only imports when AppKit or CoreGraphics are not needed.
- Use `final class` by default for concrete reference types.
- Use `struct` for immutable value models and snapshots.
- Use protocols to define boundaries for side effects and injected dependencies.
- Inject dependencies through initializers with sensible production defaults.
- Keep APIs narrow and repo-specific; do not add generic abstractions without a real reuse case.
- Naming is descriptive and concrete: `SessionStore`, `GhosttyWindowActivator`, `DiagnosticsSnapshot`.
- Use `Bool`-returning methods such as `openSession` only when the caller needs success/failure.
- Prefer early `guard` exits for invalid state.
- Throw domain-specific errors for operational failures instead of returning magic values.
- When catching errors at app boundaries, log with `Logger.shared.log(...)` and preserve user-facing state if needed.
- Do not swallow errors silently unless the existing interface explicitly models best-effort behavior.
- Keep literal strings user-facing and specific; diagnostics strings in this repo are short and direct.
- Match the existing formatting: four-space indentation and trailing commas where Swift style here already uses them.

## TypeScript / Plugin Guidelines

- Use ESM syntax and keep imports grouped at the top.
- Use `import type` for type-only imports.
- Keep functions small and event-pipeline oriented.
- Prefer explicit exported interfaces and narrow unions over loose object shapes.
- Reuse existing domain types from `plugin/src/types.ts` instead of ad hoc inline shapes when possible.
- Use camelCase for variables and functions, PascalCase for classes and interfaces, and UPPER_SNAKE_CASE only for true constants such as event-kind sets.
- Prefer simple maps and caches (`Map`, `Set`) over heavier abstractions.
- Preserve the existing style: two-space indentation, semicolon-free statements, double quotes.
- Keep async boundaries explicit with `async` / `await`; do not hide Promise chains in complex helpers.
- Do not add logging noise unless it helps trace plugin delivery or event mapping behavior.

## Testing Expectations

- Always run the smallest relevant test slice first.
- If you change Swift app behavior, run the affected XCTest target or method with `-only-testing`.
- If you change plugin runtime code, run at least the affected Bun test file and `bun run typecheck`.
- If you change cross-cutting behavior, run the broader relevant suite before claiming completion.
- Do not claim a fix works without fresh command output.

## Documentation Expectations

- Update `README.md` when setup, commands, installation, or developer workflow changes.
- Update files under `docs/` when user-visible behavior or product rules change.
- Keep session-behavior changes aligned with `docs/session-lifecycle.md`.
- Future implementation work must continue to follow `AGENTS.md`.
- If you add a new persistent rule for contributors or agents, update `AGENTS.md` in the same change.

## Practical Working Notes

- The macOS target is `Vigil`.
- The test bundle target is `VigilTests`.
- The app runs as a menu bar app (`INFOPLIST_KEY_LSUIElement: YES`).
- The plugin package name is `vigil-opencode-plugin`.
- Local bridge state is expected at `~/.config/vigil/bridge.json`.

When in doubt, prefer the smallest correct change, run the narrowest useful verification command, and keep docs synchronized with behavior.
