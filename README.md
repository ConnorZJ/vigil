# Vigil

Vigil is a native macOS menu bar companion for OpenCode sessions.

It combines:

- a macOS app that shows active and recent sessions in the menu bar
- a local OpenCode plugin that forwards session events into the app

## Status

Vigil is an early-stage project. The app is available as an unsigned GitHub Release DMG, and the OpenCode plugin is still installed separately from local source.

## Install Vigil

### App Install

1. Download `Vigil.dmg` from the latest GitHub Release for this repository.
2. Open the DMG and drag `Vigil.app` into `Applications`.
3. Launch `Vigil.app` from `Applications`, not directly from the mounted DMG.
4. If macOS blocks the first launch because the app is unsigned, right-click `Vigil.app`, choose `Open`, then confirm the prompt.
5. Grant Accessibility permission when Vigil asks for it, or use the menu bar app's `Request Accessibility` action.

### App Install Check

After launching the app:

1. Confirm the Vigil menu bar icon appears.
2. Open the menu bar item to verify the app is running.

### OpenCode Plugin Setup

The DMG installs only the macOS app. The OpenCode plugin still needs a separate local setup.

Before running any plugin commands, clone or otherwise check out this repository locally. The plugin install commands and OpenCode plugin path below assume you are working from a local checkout of this repo.

Install Bun if needed:

```bash
curl -fsSL https://bun.sh/install | bash
```

Install plugin dependencies:

```bash
cd plugin && bun install
```

Then configure OpenCode to load the local plugin from this repository. The current plugin entry point is `plugin/src/index.ts`.

This repository does not yet provide a bundled plugin installer. You need to use OpenCode's local plugin workflow to point your OpenCode setup at this local source checkout.

### Plugin Setup Check

After the app is running and OpenCode is configured to load the local plugin:

1. Confirm `~/.config/vigil/bridge.json` exists.
2. Start or resume an OpenCode session.
3. Confirm the running app receives session updates in the menu bar UI.

## Contributor Requirements

These requirements are for contributors building Vigil from source, not for end users installing `Vigil.dmg`.

- macOS
- Xcode
- XcodeGen
- Bun

Install tool dependencies:

```bash
brew install xcodegen
```

Install Bun if needed:

```bash
curl -fsSL https://bun.sh/install | bash
```

## Quick Start

This section is for contributors building Vigil from source.

Install plugin dependencies:

```bash
cd plugin && bun install
```

Generate the Xcode project:

```bash
make generate
```

Build the app locally:

```bash
make build
```

Run the main verification commands:

```bash
make test
make test-plugin
```

## Development

Generate the Xcode project:

```bash
make generate
```

Run tests:

```bash
make test
```

Build the app locally:

```bash
make build
```

Run plugin checks:

```bash
make test-plugin
```

You can also run the plugin checks directly:

```bash
cd plugin && bun test
cd plugin && bun run typecheck
```

## Previewing The App

Open `Vigil.xcodeproj` and run the app target. The current debug build seeds preview sessions so you can inspect the menu bar UI before wiring the real OpenCode plugin.

The current preview flow now uses:

- a simplified pixel-art menu bar status icon
- a custom popover instead of the old `NSMenu`
- pixel-art session cards, diagnostics, and utility actions inside the popover

## Permissions

For Ghostty window discovery and jumping, the app needs macOS Accessibility permission. The menu includes a `Request Accessibility` action to prompt for it.

## Local Plugin Install

At this stage the plugin source lives in `plugin/`. The app install and plugin install are still separate. The DMG does not bundle the plugin.

The final packaging path can point OpenCode at the built package entry from `plugin/src/index.ts` or a published npm package later.

For local development, the important pieces are:

- app bridge file: `~/.config/vigil/bridge.json`
- plugin entry exports: `plugin/src/index.ts`
- plugin dependencies: `cd plugin && bun install`
- plugin tests: `make test-plugin`

## Session Lifecycle

Vigil shows active and recently active OpenCode sessions in a session panel.

Sessions appear when Vigil receives activity from OpenCode, remain visible for a short period after becoming idle, and are removed automatically after staying idle long enough. Explicitly deleted sessions are removed immediately.

See `docs/session-lifecycle.md` for the full behavior.

## Troubleshooting

- If the menu updates but jumps do not work, check macOS Accessibility permission.
- If the plugin cannot deliver events, confirm `~/.config/vigil/bridge.json` exists.
- If Bun is not in your shell `PATH`, use `$HOME/.bun/bin/bun` directly.
- If Xcode build settings drift, regenerate with `make generate` before debugging project file issues.
- For real transport verification, first launch the app, then `curl http://127.0.0.1:<port>/v1/health` using the port from `~/.config/vigil/bridge.json`.

## Contributing

Contributions are welcome. For local setup, verification expectations, and pull request guidance, see `CONTRIBUTING.md`.

## License

MIT. See `LICENSE`.
