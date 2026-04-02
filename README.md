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

Run plugin checks:

```bash
cd plugin
/Users/connor/.bun/bin/bun test
/Users/connor/.bun/bin/bun run typecheck
```

## Previewing The App

Open `Vigil.xcodeproj` in the worktree and run the app target. The current debug build seeds preview sessions so you can inspect the menu bar UI before wiring the real OpenCode plugin.

## Permissions

For Ghostty window discovery and jumping, the app needs macOS Accessibility permission. The menu includes a `Request Accessibility` action to prompt for it.
