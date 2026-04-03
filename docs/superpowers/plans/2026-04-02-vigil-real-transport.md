# Vigil Real Transport Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the placeholder local transport shell with a real localhost listener so the Vigil app can receive actual OpenCode events and update the UI from real traffic.

**Architecture:** Use `Network.framework` for the socket/listener layer, keep HTTP parsing minimal and explicit, preserve `EventIngestionController` as the business boundary, and push listener/ingestion facts into diagnostics without changing the plugin event schema or session store semantics.

**Tech Stack:** Swift, AppKit, Network.framework, XCTest, TypeScript, Bun, curl

---

## Important Agent Rules

- Do not add third-party HTTP server dependencies.
- Do not widen route scope beyond `POST /v1/events` and `GET /v1/health` in this phase.
- Do not change the plugin event envelope.
- Do not add chunked encoding or keep-alive support.
- Always include `Connection: close` in server responses.
- Keep HTTP parsing and business ingestion in separate files.
- Diagnostics must distinguish `listener`, `parse`, `auth`, `route`, `ingestion`, and `action` error stages.

## File Structure

### Files to modify

- `vigil/Vigil/Transport/EmbeddedHTTPServer.swift`: replace placeholder startup with real listener lifecycle.
- `vigil/Vigil/Transport/EventIngestionController.swift`: add `/v1/health` handling and possibly explicit route/method helpers without coupling to `Network.framework`.
- `vigil/Vigil/State/AppState.swift`: expose listener and ingestion diagnostics facts and stop preview-mode confusion once real events arrive.
- `vigil/Vigil/UI/PopoverPresentationBuilder.swift`: include refined diagnostics facts if needed.
- `vigil/Vigil/App/AppDelegate.swift`: ensure listener startup path is used on launch.
- `vigil/plugin/README.md`: document real local verification path.
- `vigil/README.md`: document health endpoint and local verification.

### New files to create

- `vigil/Vigil/Transport/HTTPMessageParser.swift`: minimal request parser and response serializer helpers.
- `vigil/Vigil/Transport/HTTPServerConnection.swift`: one-request-per-connection reader/writer wrapper.
- `vigil/Vigil/Transport/TransportDiagnostics.swift`: listener and ingestion diagnostics models.
- `vigil/VigilTests/Transport/HTTPMessageParserTests.swift`: parser/framing tests.
- `vigil/VigilTests/Transport/EmbeddedHTTPServerTests.swift`: lifecycle/response tests where feasible.

## Build And Verification Commands

```bash
cd vigil && xcodegen generate
cd vigil && make test
cd vigil && make test-plugin
```

Manual transport verification commands:

```bash
curl -i http://127.0.0.1:<port>/v1/health
curl -i -X POST http://127.0.0.1:<port>/v1/events \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  --data @sample-event.json
```

## Task Breakdown

### Task 1: Add Minimal HTTP Parser And Response Serialization

**Files:**
- Create: `vigil/Vigil/Transport/HTTPMessageParser.swift`
- Create: `vigil/VigilTests/Transport/HTTPMessageParserTests.swift`
- Modify: `vigil/project.yml`

- [ ] **Step 1: Write the failing parser tests**

Test cases:

- parses request line, headers, and body with `Content-Length`
- rejects request without complete header terminator
- rejects body shorter than declared `Content-Length`
- enforces request size limit
- serializes a response with `Connection: close`
- serializes `/v1/health` success responses as JSON bodies, not empty responses

- [ ] **Step 2: Run the parser tests to verify they fail**

```bash
cd vigil && xcodegen generate && xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/HTTPMessageParserTests
```

Expected: FAIL because parser types do not exist.

- [ ] **Step 3: Implement the minimal parser and serializer**

Requirements:

- parse one request only
- support only `Content-Length`
- no chunked support
- return explicit parse errors
- response serializer must emit a JSON body for health success, for example `{ "ok": true }`

- [ ] **Step 4: Re-run focused tests**

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Vigil/Transport/HTTPMessageParser.swift VigilTests/Transport/HTTPMessageParserTests.swift project.yml
git commit -m "feat: add vigil minimal http parser"
```

### Task 2: Implement Real Network.framework Listener

**Files:**
- Create: `vigil/Vigil/Transport/HTTPServerConnection.swift`
- Modify: `vigil/Vigil/Transport/EmbeddedHTTPServer.swift`
- Modify: `vigil/Vigil/Transport/BridgeFileWriter.swift`
- Create: `vigil/VigilTests/Transport/EmbeddedHTTPServerTests.swift`

- [ ] **Step 1: Write the failing listener tests where feasible**

Test cases:

- startup transitions listener to active state
- active port is exposed after bind
- bridge file is written only after successful bind
- `Connection: close` response is emitted
- incomplete requests time out and are closed with a timeout-class transport error fact

- [ ] **Step 2: Run the listener tests to verify they fail**

```bash
cd vigil && xcodegen generate && xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/EmbeddedHTTPServerTests
```

Expected: FAIL because the listener is still a placeholder.

- [ ] **Step 3: Implement `HTTPServerConnection`**

Responsibilities:

- accumulate bytes until `\r\n\r\n`
- parse headers
- continue reading body until declared length
- hand request to `EventIngestionController`
- write serialized response and close
- enforce a short read timeout for incomplete requests and surface a timeout-class parse/listener error fact

- [ ] **Step 4: Replace placeholder server startup**

Requirements:

- use `NWListener`
- bind localhost only
- support explicit or dynamic port
- only write bridge file after successful bind

- [ ] **Step 5: Re-run focused tests**

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Vigil/Transport/HTTPServerConnection.swift Vigil/Transport/EmbeddedHTTPServer.swift Vigil/Transport/BridgeFileWriter.swift VigilTests/Transport/EmbeddedHTTPServerTests.swift
git commit -m "feat: add vigil localhost listener"
```

### Task 3: Expand Controller Routes And Diagnostics Facts

**Files:**
- Create: `vigil/Vigil/Transport/TransportDiagnostics.swift`
- Modify: `vigil/Vigil/Transport/EventIngestionController.swift`
- Modify: `vigil/Vigil/State/AppState.swift`
- Modify: `vigil/Vigil/UI/PopoverPresentationBuilder.swift`

- [ ] **Step 1: Write failing controller/diagnostics tests**

Test cases:

- `GET /v1/health` returns `200`
- `GET /v1/health` returns a small JSON body
- wrong method on known route returns `405`
- unknown route returns `404`
- diagnostics classify parse/auth/route errors distinctly
- diagnostics expose listener active state, bound port, bridge-write success, and last successful event time

- [ ] **Step 2: Run the focused tests to verify they fail**

Run targeted transport tests.

- [ ] **Step 3: Implement health route and categorized diagnostics**

Requirements:

- add error stage enum: `listener`, `parse`, `auth`, `route`, `ingestion`, `action`
- keep controller free of UI concerns
- surface the latest categorized transport fact through `AppState`
- also surface listener active state, bound port, bridge-write success, and last successful event time through `AppState` diagnostics

- [ ] **Step 4: Re-run focused tests**

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Vigil/Transport/TransportDiagnostics.swift Vigil/Transport/EventIngestionController.swift Vigil/State/AppState.swift Vigil/UI/PopoverPresentationBuilder.swift
git commit -m "feat: add vigil transport diagnostics"
```

### Task 4: Manual curl Verification And Preview Behavior Tightening

**Files:**
- Modify: `vigil/Vigil/State/AppState.swift`

- [ ] **Step 1: Ensure preview data does not obscure real transport testing**

Requirements:

- preview mode only seeds when appropriate for development
- first real event should make real state clearly distinguishable

- [ ] **Step 2: Run full automated verification**

```bash
cd vigil && make test
cd vigil && make test-plugin
```

Expected: PASS.

- [ ] **Step 3: Perform manual curl verification**

Checklist:

- launch app
- inspect bridge file for port/token
- `curl /v1/health`
- send authenticated sample event JSON to `/v1/events`
- confirm UI updates from real event
- confirm diagnostics show real last-event timing

- [ ] **Step 4: Commit**

```bash
git add Vigil/State/AppState.swift
git commit -m "feat: support real transport verification mode"
```

### Task 5: Connect Plugin To Real Listener And Verify End-To-End

**Files:**
- Modify: `vigil/plugin/README.md`
- Modify: `vigil/README.md`
- Modify: `vigil/plugin/src/plugin.ts` if real hook glue needs a minimal correction

- [ ] **Step 1: Verify plugin assumptions against the real listener**

Requirements:

- plugin requests include `Content-Length`
- plugin tolerates one-request-per-connection behavior
- plugin treats status code as success signal

- [ ] **Step 2: Make only minimal plugin changes if required**

Do not redesign the plugin transport.

- [ ] **Step 3: Run full plugin verification**

```bash
cd vigil && make test-plugin
```

Expected: PASS.

- [ ] **Step 4: Perform real end-to-end verification**

Checklist:

- app running
- plugin using bridge file
- real event delivered from plugin path
- menu bar/popover update from real state
- diagnostics show successful receipt and listener facts

- [ ] **Step 5: Update docs**

Document:

- health endpoint
- bridge verification
- curl verification flow
- plugin real-event verification path

- [ ] **Step 6: Commit**

```bash
git add README.md plugin/README.md plugin/src/plugin.ts
git commit -m "feat: wire vigil real transport end to end"
```

## Final Verification Checklist

- [ ] `cd vigil && xcodegen generate`
- [ ] `cd vigil && make test`
- [ ] `cd vigil && make test-plugin`
- [ ] manual `curl /v1/health`
- [ ] manual authenticated `POST /v1/events`
- [ ] manual confirmation that UI updates from a real event
- [ ] manual confirmation that diagnostics show listener active state, bound port, and bridge-write success
- [ ] manual confirmation that diagnostics classify route/auth/parse failures distinctly

## Reviewer Checklist

- listener binds localhost only
- bridge file is written only after a successful bind
- every response includes `Connection: close`
- no chunked or keep-alive support was added
- controller remains independent of `Network.framework`
- diagnostics expose categorized error stages
- plugin schema is unchanged
