# Vigil

Native macOS menu bar companion for OpenCode sessions.

## Requirements

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

## Previewing The App

Open `Vigil.xcodeproj` in the worktree and run the app target. The current debug build seeds preview sessions so you can inspect the menu bar UI before wiring the real OpenCode plugin.

The current preview flow now uses:

- a simplified pixel-art menu bar status icon
- a custom popover instead of the old `NSMenu`
- pixel-art session cards, diagnostics, and utility actions inside the popover

## Permissions

For Ghostty window discovery and jumping, the app needs macOS Accessibility permission. The menu includes a `Request Accessibility` action to prompt for it.

## Local Plugin Install

At this stage the plugin source lives in `plugin/`. The final packaging path can point OpenCode at the built package entry from `plugin/src/index.ts` or a published npm package later.

For local development, the important pieces are:

- app bridge file: `~/.config/vigil/bridge.json`
- plugin entry exports: `plugin/src/index.ts`
- plugin tests: `make test-plugin`

## Troubleshooting

- If the menu updates but jumps do not work, check macOS Accessibility permission.
- If the plugin cannot deliver events, confirm `~/.config/vigil/bridge.json` exists.
- If Bun is not in your shell `PATH`, use `/Users/connor/.bun/bin/bun` directly.
- If Xcode build settings drift, regenerate with `make generate` before debugging project file issues.
- For real transport verification, first launch the app, then `curl http://127.0.0.1:<port>/v1/health` using the port from `~/.config/vigil/bridge.json`.
