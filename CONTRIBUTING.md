# Contributing

## Prerequisites

- macOS
- Xcode
- XcodeGen
- Bun

Install the required tools first:

```bash
brew install xcodegen
curl -fsSL https://bun.sh/install | bash
```

## Local Development

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

The main repository areas are:

- `Vigil/` for the macOS app
- `VigilTests/` for XCTest coverage
- `plugin/` for the Bun + TypeScript OpenCode plugin
- `docs/` for supporting product and engineering docs

## Verification Before PR

Run the relevant checks before opening a pull request.

For app changes:

```bash
make test
```

For plugin changes:

```bash
make test-plugin
```

You can also run the plugin checks directly:

```bash
cd plugin && bun test
cd plugin && bun run typecheck
```

If your change only touches a narrow area, prefer the smallest useful verification command first.

## Documentation Expectations

Keep documentation in sync with behavior changes.

- Update `README.md` when setup, installation, or developer workflow changes.
- Update files under `docs/` when user-visible behavior or product rules change.
- Keep session behavior changes aligned with `docs/session-lifecycle.md`.
- Keep contributor guidance aligned with `AGENTS.md`.

## Pull Requests

- Keep pull requests focused on one change.
- Explain what changed and why.
- Mention the verification you ran.
- Avoid mixing unrelated cleanup with the main change.
