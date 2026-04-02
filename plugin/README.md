# Vigil OpenCode Plugin

Companion plugin for sending OpenCode session updates to the local Vigil macOS app.

## Local Development

Install dependencies:

```bash
/Users/connor/.bun/bin/bun install
```

Run tests:

```bash
/Users/connor/.bun/bin/bun test
/Users/connor/.bun/bin/bun run typecheck
```

## Bridge Discovery

The plugin reads the local bridge file from:

```text
~/.config/vigil/bridge.json
```

That file is written by the macOS app and contains:

- localhost port
- bearer token
- last update timestamp

## Local Install Shape

The final OpenCode install glue will expose this package through `src/index.ts` and register a thin set of hooks that forward OpenCode session events into `createVigilPlugin(...)`.

## Delivery Verification

You can verify local delivery by:

1. Launching the macOS app
2. Confirming the bridge file exists
3. Hitting the app health endpoint
4. Triggering a mapped event and checking the menu updates
