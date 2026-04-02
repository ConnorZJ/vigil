# Vigil Menu Bar Companion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `Vigil`, a native macOS menu bar app plus OpenCode plugin that tracks multi-session OpenCode state, surfaces attention states, and jumps back to the matching Ghostty window.

**Architecture:** `Vigil` is split into two deliverables inside one repo: a native macOS app and a TypeScript OpenCode plugin. The plugin emits full session snapshots over localhost HTTP using a shared bridge file. The macOS app owns session state, notifications, persistence, and Ghostty window matching through Accessibility wrappers and best-effort binding.

**Tech Stack:** Swift, SwiftUI, AppKit, XCTest, XcodeGen, TypeScript, Bun, OpenCode plugin hooks, local HTTP, JSON persistence

---

## Important Agent Rules

These rules exist because a lower-cost model will execute this plan later.

- Keep files small and single-purpose.
- Do not hand-edit a `.pbxproj` file. Use `XcodeGen` and regenerate the project.
- Do not implement direct system APIs in menu/UI code. Put them behind services and protocols first.
- Every task that adds new Swift or test files must update `project.yml` before running `xcodegen generate`.
- Follow TDD wherever practical. For system APIs that cannot be tested directly, test the pure matching/state logic around them.
- Do not add speculative features beyond the spec.
- Prefer JSON persistence over databases in V1.
- Every transport event must be a full session snapshot, never a partial patch.
- When a task says “minimal implementation,” stop at the smallest code that makes the tests pass.
- After each task, run only the relevant tests first, then run the broader suite.
- Keep commit scope narrow. One task, one commit.

## Repository Layout

Create this structure first and keep responsibilities fixed:

```text
vigil/
  project.yml
  Makefile
  README.md
  .gitignore
  Vigil/
    App/
      VigilApp.swift
      AppDelegate.swift
      MenuBarController.swift
    Domain/
      SessionStatus.swift
      SessionSnapshot.swift
      SessionEvent.swift
      SessionPriority.swift
      WindowSignature.swift
    State/
      SessionStore.swift
      AppState.swift
    Persistence/
      JSONFileStore.swift
      SessionPersistence.swift
      BridgeFileWriter.swift
      BindingPersistence.swift
    Transport/
      EmbeddedHTTPServer.swift
      EventIngestionController.swift
      AuthTokenProvider.swift
    Notifications/
      NotificationPolicy.swift
      UserNotificationClient.swift
    Ghostty/
      AXPermissionService.swift
      GhosttyWindowDescriptor.swift
      GhosttyWindowQuerying.swift
      GhosttyAXWindowQueryService.swift
      GhosttyWindowMatcher.swift
      GhosttyWindowBinder.swift
      GhosttyWindowActivator.swift
    UI/
      SessionMenuBuilder.swift
      SessionMenuRowViewModel.swift
      SessionMenuActions.swift
      DiagnosticsView.swift
      SettingsView.swift
    Support/
      Paths.swift
      Logger.swift
      Clock.swift
  VigilTests/
    Domain/
      SessionPriorityTests.swift
      SessionSnapshotTests.swift
    State/
      SessionStoreTests.swift
    Persistence/
      SessionPersistenceTests.swift
      BridgeFileWriterTests.swift
      BindingPersistenceTests.swift
    Transport/
      EventIngestionControllerTests.swift
    Notifications/
      NotificationPolicyTests.swift
    Ghostty/
      GhosttyWindowMatcherTests.swift
      GhosttyWindowBinderTests.swift
    UI/
      SessionMenuBuilderTests.swift
  plugin/
    package.json
    tsconfig.json
    README.md
    src/
      index.ts
      types.ts
      bridge.ts
      transport.ts
      mapper.ts
      session-cache.ts
      plugin.ts
    test/
      mapper.test.ts
      bridge.test.ts
      transport.test.ts
      session-cache.test.ts
```

## Build and Test Commands

Use these commands consistently.

### Tool bootstrap

```bash
brew install xcodegen bun
```

### Generate Xcode project

```bash
cd vigil && xcodegen generate
```

### Run macOS tests

```bash
cd vigil && xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS'
```

### Run plugin tests

```bash
cd vigil/plugin && bun test
```

### Run all verification

```bash
cd vigil && make test
```

## File Responsibilities

### App files

- `Vigil/App/VigilApp.swift`: app entry point.
- `Vigil/App/AppDelegate.swift`: lifecycle bootstrap, permissions, menu setup.
- `Vigil/App/MenuBarController.swift`: owns `NSStatusItem`, icon state, click-to-open menu.
- `Vigil/Domain/*`: pure types only, no system calls.
- `Vigil/State/SessionStore.swift`: source of truth for in-memory session state and retention logic.
- `Vigil/State/AppState.swift`: aggregates store, services, and global status.
- `Vigil/Persistence/*`: JSON read/write wrappers and bridge/session persistence.
- `Vigil/Transport/*`: local HTTP server and auth enforcement.
- `Vigil/Notifications/*`: notification decision logic and OS delivery wrapper.
- `Vigil/Ghostty/*`: Accessibility adapters, matching logic, activation, manual bind support.
- `Vigil/UI/*`: menu section/view-model construction and user-triggered actions.
- `Vigil/Support/*`: filesystem paths, clock abstraction, logging.

### Plugin files

- `plugin/src/types.ts`: transport and snapshot types.
- `plugin/src/bridge.ts`: bridge file reader and reload behavior.
- `plugin/src/transport.ts`: authenticated POST client with fast-fail behavior.
- `plugin/src/mapper.ts`: maps OpenCode events to Vigil business events.
- `plugin/src/session-cache.ts`: tracks latest full snapshot per session and heartbeat timer state.
- `plugin/src/plugin.ts`: OpenCode hook registration.
- `plugin/src/index.ts`: package export entry.

## Cross-Cutting Decisions

- Use `XcodeGen` so the project can be regenerated from `project.yml`.
- Use `XCTest`, not UI tests, for V1.
- Use `UNUserNotificationCenter` for notifications.
- Use protocol-based wrappers around Accessibility and notification APIs.
- Store app files under `~/Library/Application Support/Vigil/` and the bridge file under `~/.config/vigil/bridge.json`.
- Plugin must silently no-op when the bridge file or local app is unavailable.

## Shared Transport Contract

The app and plugin must use the exact same envelope shape from the spec.

```json
{
  "source": "opencode",
  "version": 1,
  "eventId": "uuid",
  "eventType": "session.updated",
  "sentAt": "2026-04-01T12:34:56Z",
  "session": {
    "sessionId": "abc123",
    "sessionTitle": "refactor auth middleware",
    "projectPath": "/Users/you/project/foo",
    "projectName": "foo",
    "terminalApp": "ghostty",
    "status": "running",
    "windowHint": {
      "cwd": "/Users/you/project/foo",
      "tabTitle": "foo",
      "tty": "/dev/ttys012"
    },
    "workspaceHint": null
  },
  "payload": {
    "message": "Session heartbeat",
    "error": null,
    "requiresAttentionReason": null
  }
}
```

Required top-level fields:

- `source`
- `version`
- `eventId`
- `eventType`
- `sentAt`
- `session`

Required session fields:

- `sessionId`
- `sessionTitle`
- `projectPath`
- `projectName`
- `terminalApp`
- `status`

App-side Swift types and plugin-side TypeScript types must mirror this contract exactly.

---

### Task 1: Bootstrap the Repository and Native Project Generator

**Files:**
- Create: `vigil/.gitignore`
- Create: `vigil/Makefile`
- Create: `vigil/README.md`
- Create: `vigil/project.yml`
- Create: `vigil/Vigil/App/VigilApp.swift`
- Create: `vigil/Vigil/App/AppDelegate.swift`
- Create: `vigil/Vigil/App/MenuBarController.swift`
- Create: `vigil/Vigil/Support/Logger.swift`
- Create: `vigil/VigilTests/Smoke/SmokeTests.swift`

- [ ] **Step 1: Write a smoke test target plan into `project.yml`**

Define one app target named `Vigil` and one unit test target named `VigilTests`. Prefer broad source globs that already include all planned folders under `Vigil/` and `VigilTests/` so later tasks only need regeneration, not fragile target rewrites.

- [ ] **Step 2: Write the failing smoke test**

```swift
import XCTest

final class SmokeTests: XCTestCase {
    func testSmoke() {
        XCTAssertTrue(true)
    }
}
```

- [ ] **Step 3: Add minimal app bootstrap code**

Create a compile-only shell:

```swift
import SwiftUI

@main
struct VigilApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
```

`AppDelegate` should create `MenuBarController`. `MenuBarController` should create a basic `NSStatusItem` with a placeholder title or image.

- [ ] **Step 4: Generate the project**

Run: `cd vigil && xcodegen generate`
Expected: `Vigil.xcodeproj` generated without errors.

- [ ] **Step 5: Run the smoke test**

Run: `cd vigil && xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS'`
Expected: PASS.

- [ ] **Step 6: Add `make` commands**

Add at least:

```make
generate:
	xcodegen generate

test:
	xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS'
```

- [ ] **Step 7: Commit**

Commit message: `chore: bootstrap vigil macos app`

### Task 2: Define Pure Domain Types and Priority Rules

**Files:**
- Create: `vigil/Vigil/Domain/SessionStatus.swift`
- Create: `vigil/Vigil/Domain/SessionPriority.swift`
- Create: `vigil/Vigil/Domain/WindowSignature.swift`
- Create: `vigil/Vigil/Domain/SessionSnapshot.swift`
- Create: `vigil/Vigil/Domain/SessionEvent.swift`
- Create: `vigil/VigilTests/Domain/SessionPriorityTests.swift`
- Create: `vigil/VigilTests/Domain/SessionSnapshotTests.swift`
- Modify: `vigil/project.yml`

- [ ] **Step 1: Write the failing priority tests**

```swift
func testErrorOutranksWaitingInput() {
    XCTAssertGreaterThan(SessionPriority(status: .error).value,
                         SessionPriority(status: .waitingInput).value)
}

func testRunningDoesNotRequireAttention() {
    XCTAssertFalse(SessionStatus.running.requiresAttention)
}
```

- [ ] **Step 2: Write the failing snapshot tests**

```swift
func testSnapshotRequiresCoreFields() throws {
    let snapshot = SessionSnapshot(
        sessionId: "1",
        sessionTitle: "title",
        projectPath: "/tmp/project",
        projectName: "project",
        terminalApp: "ghostty",
        status: .running,
        updatedAt: Date()
    )

    XCTAssertEqual(snapshot.projectName, "project")
}
```

- [ ] **Step 3: Implement minimal pure types**

Requirements:

- `SessionStatus` enum with `running`, `waitingInput`, `permission`, `complete`, `error`, `unknown`
- `requiresAttention` computed property
- `SessionPriority` wrapper with comparable integer ranking
- `WindowSignature` struct for persisted binding metadata
- `SessionSnapshot` struct with optional `windowHint`, `workspaceHint`, `lastError`, `requiresAttentionReason`, `isStale`
- `SessionEvent` struct with `source`, `version`, `eventId`, `eventType`, `sentAt`, nested `session`, and structured `payload`

- [ ] **Step 4: Run focused domain tests**

Run: `cd vigil && xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/SessionPriorityTests -only-testing:VigilTests/SessionSnapshotTests`
Expected: PASS.

- [ ] **Step 5: Run full app test suite**

Run: `cd vigil && make test`
Expected: PASS.

- [ ] **Step 6: Commit**

Commit message: `feat: add vigil session domain models`

### Task 3: Implement Path Helpers, JSON Storage, and Bridge File Writer

**Files:**
- Create: `vigil/Vigil/Support/Paths.swift`
- Create: `vigil/Vigil/Support/Clock.swift`
- Create: `vigil/Vigil/Persistence/JSONFileStore.swift`
- Create: `vigil/Vigil/Persistence/BridgeFileWriter.swift`
- Create: `vigil/Vigil/Persistence/BindingPersistence.swift`
- Create: `vigil/VigilTests/Persistence/BridgeFileWriterTests.swift`
- Create: `vigil/VigilTests/Persistence/BindingPersistenceTests.swift`
- Modify: `vigil/project.yml`

- [ ] **Step 1: Write the failing bridge-file tests**

Test cases:

- writer creates `~/.config/vigil/bridge.json` equivalent under a temporary root
- file includes `version`, `port`, `token`, `updatedAt`
- write is atomic

Skeleton:

```swift
func testBridgeFileContainsPortAndToken() throws {
    let root = temporaryDirectory()
    let writer = BridgeFileWriter(baseURL: root, clock: FixedClock())

    try writer.write(port: 48127, token: "abc")

    let data = try Data(contentsOf: root.appendingPathComponent(".config/vigil/bridge.json"))
    XCTAssertTrue(String(decoding: data, as: UTF8.self).contains("48127"))
}
```

- [ ] **Step 2: Implement path helpers**

Add helpers for:

- app support root: `~/Library/Application Support/Vigil/`
- config root: `~/.config/vigil/`
- bridge file path
- session persistence file path
- binding persistence file path

- [ ] **Step 3: Implement generic JSON file store**

Requirements:

- create parent directories
- atomic write
- decode optional file contents
- no app-specific logic

- [ ] **Step 4: Implement bridge writer**

Minimal API:

```swift
protocol BridgeWriting {
    func write(port: Int, token: String) throws
}
```

- [ ] **Step 5: Write the failing binding persistence tests**

Test cases:

- saves a `sessionId -> WindowSignature` map
- reloads persisted bindings on a fresh store instance
- removing a binding persists the deletion

- [ ] **Step 6: Implement binding persistence**

Minimal API:

```swift
protocol BindingPersisting {
    func load() throws -> [String: WindowSignature]
    func save(_ bindings: [String: WindowSignature]) throws
}
```

- [ ] **Step 7: Run focused persistence tests**

Run: `cd vigil && xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/BridgeFileWriterTests -only-testing:VigilTests/BindingPersistenceTests`
Expected: PASS.

- [ ] **Step 8: Run full app test suite**

Run: `cd vigil && make test`
Expected: PASS.

- [ ] **Step 9: Commit**

Commit message: `feat: add vigil bridge file persistence`

### Task 4: Implement Session Persistence and Retention-Aware Session Store

**Files:**
- Create: `vigil/Vigil/Persistence/SessionPersistence.swift`
- Create: `vigil/Vigil/State/SessionStore.swift`
- Create: `vigil/VigilTests/Persistence/SessionPersistenceTests.swift`
- Create: `vigil/VigilTests/State/SessionStoreTests.swift`

- [ ] **Step 1: Write the failing session persistence tests**

Test cases:

- active sessions are restored on relaunch
- complete sessions older than 10 minutes are dropped
- stale flag survives encode/decode

- [ ] **Step 2: Write the failing session store tests**

Test cases:

- applying `session.completed` moves a session to `complete`
- `session.closed` removes from active list
- stale session never outranks non-stale peer of same priority
- highest-priority global session is computed correctly

Example:

```swift
func testHighestPriorityPrefersWaitingInputOverRunning() {
    let store = SessionStore(clock: FixedClock())
    store.apply(event: .fixture(status: .running, sessionId: "a"))
    store.apply(event: .fixture(status: .waitingInput, sessionId: "b"))

    XCTAssertEqual(store.primarySession?.sessionId, "b")
}
```

- [ ] **Step 3: Implement session persistence**

Persist an array or keyed dictionary of session snapshots. Keep it simple JSON.

- [ ] **Step 4: Implement session store**

Responsibilities:

- apply full-snapshot events
- dedupe by `eventId`
- track latest `sentAt`
- ignore or safely reject older snapshots that would regress the stored state for the same session
- mark stale when heartbeat exceeds 45 seconds
- compute sections: attention, running, recently completed
- schedule eviction for completed sessions older than 10 minutes

- [ ] **Step 5: Add explicit helper methods**

Add small pure helpers for:

- `applyRetentionPolicy(now:)`
- `markStaleSessions(now:)`
- `primarySession`
- `menuSections`

- [ ] **Step 6: Run focused tests**

Run: `cd vigil && xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/SessionPersistenceTests -only-testing:VigilTests/SessionStoreTests`
Expected: PASS.

- [ ] **Step 7: Run full app test suite**

Run: `cd vigil && make test`
Expected: PASS.

- [ ] **Step 8: Commit**

Commit message: `feat: add vigil session store and retention rules`

### Task 5: Implement Notification Policy Before OS Delivery

**Files:**
- Create: `vigil/Vigil/Notifications/NotificationPolicy.swift`
- Create: `vigil/Vigil/Notifications/UserNotificationClient.swift`
- Create: `vigil/VigilTests/Notifications/NotificationPolicyTests.swift`

- [ ] **Step 1: Write the failing notification policy tests**

Test cases:

- `running` does not notify
- `waitingInput`, `permission`, `error`, `complete` notify
- duplicate status updates for same session do not re-notify unless status changed

- [ ] **Step 2: Implement pure notification policy**

Suggested API:

```swift
struct NotificationPolicy {
    func shouldNotify(previous: SessionSnapshot?, current: SessionSnapshot) -> Bool
}
```

- [ ] **Step 3: Add OS notification wrapper only after policy passes**

Create a thin wrapper protocol around `UNUserNotificationCenter`. No business logic in the OS wrapper.

- [ ] **Step 4: Run focused notification tests**

Run: `cd vigil && xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/NotificationPolicyTests`
Expected: PASS.

- [ ] **Step 5: Run full app test suite**

Run: `cd vigil && make test`
Expected: PASS.

- [ ] **Step 6: Commit**

Commit message: `feat: add vigil notification policy`

### Task 6: Build the Local HTTP Ingestion Endpoint and Auth Enforcement

**Files:**
- Create: `vigil/Vigil/Transport/AuthTokenProvider.swift`
- Create: `vigil/Vigil/Transport/EventIngestionController.swift`
- Create: `vigil/Vigil/Transport/EmbeddedHTTPServer.swift`
- Create: `vigil/VigilTests/Transport/EventIngestionControllerTests.swift`
- Modify: `vigil/Vigil/Persistence/BridgeFileWriter.swift`

- [ ] **Step 1: Write failing ingestion controller tests**

Test cases:

- rejects missing bearer token
- rejects malformed JSON
- accepts full snapshot event
- hands accepted event to `SessionStore`

Example:

```swift
func testRejectsMissingAuthorization() throws {
    let controller = EventIngestionController(...)
    let response = try controller.handle(request: .fixture(headers: [:], body: Data()))
    XCTAssertEqual(response.statusCode, 401)
}
```

- [ ] **Step 2: Implement auth token provider**

Requirements:

- load persisted token if present
- generate one if missing
- expose active port and token for bridge writing

- [ ] **Step 3: Implement ingestion controller as a pure boundary**

Do not couple this to a specific HTTP library yet. First define a tiny request/response model the tests can use.

- [ ] **Step 4: Implement embedded HTTP server**

Requirements:

- bind only to `127.0.0.1`
- choose an available port
- route `/v1/health`, `/v1/events`, `/v1/sessions`
- write the bridge file after binding succeeds

- [ ] **Step 5: Run focused transport tests**

Run: `cd vigil && xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/EventIngestionControllerTests`
Expected: PASS.

- [ ] **Step 6: Run full app test suite**

Run: `cd vigil && make test`
Expected: PASS.

- [ ] **Step 7: Manually verify health endpoint**

Run the app, then:

```bash
curl -i http://127.0.0.1:<port>/v1/health
```

Expected: `200` with a simple JSON health body.

- [ ] **Step 8: Commit**

Commit message: `feat: add vigil localhost event ingestion`

### Task 7: Wire App State and Menu Bar Presentation

**Files:**
- Create: `vigil/Vigil/State/AppState.swift`
- Create: `vigil/Vigil/UI/SessionMenuRowViewModel.swift`
- Create: `vigil/Vigil/UI/SessionMenuBuilder.swift`
- Create: `vigil/Vigil/UI/SessionMenuActions.swift`
- Create: `vigil/VigilTests/UI/SessionMenuBuilderTests.swift`
- Modify: `vigil/Vigil/App/AppDelegate.swift`
- Modify: `vigil/Vigil/App/MenuBarController.swift`

- [ ] **Step 1: Write failing menu builder tests**

Test cases:

- primary session determines top icon state
- sessions are grouped into summary, attention, running, recently completed
- row view models show relative age and project name

- [ ] **Step 2: Implement pure menu builder view models**

Menu-building logic should be pure and testable. Do not write AppKit menu code first.

- [ ] **Step 3: Implement app state coordinator**

`AppState` should own:

- `SessionStore`
- notification client
- transport server
- optional ghostty services

It should expose minimal methods for bootstrap and user actions.

- [ ] **Step 4: Implement `MenuBarController` rendering**

Requirements:

- create `NSStatusItem`
- set monochrome template icon
- rebuild menu when session state changes
- clicking opens menu, not direct jump

- [ ] **Step 5: Run focused UI logic tests**

Run: `cd vigil && xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/SessionMenuBuilderTests`
Expected: PASS.

- [ ] **Step 6: Run full app test suite**

Run: `cd vigil && make test`
Expected: PASS.

- [ ] **Step 7: Manually verify menu sections**

Use a temporary fake event injector or hardcoded preview data to confirm the menu shows all expected sections.

- [ ] **Step 8: Commit**

Commit message: `feat: add vigil menu bar session ui`

### Task 8: Implement Accessibility Permission and Ghostty Window Query Abstractions

**Files:**
- Create: `vigil/Vigil/Ghostty/AXPermissionService.swift`
- Create: `vigil/Vigil/Ghostty/GhosttyWindowDescriptor.swift`
- Create: `vigil/Vigil/Ghostty/GhosttyWindowQuerying.swift`
- Create: `vigil/Vigil/Ghostty/GhosttyAXWindowQueryService.swift`
- Modify: `vigil/Vigil/State/AppState.swift`

- [ ] **Step 1: Write protocol-first query design**

Define pure types and protocols before touching AX APIs.

Suggested types:

```swift
struct GhosttyWindowDescriptor: Equatable {
    let title: String
    let frame: CGRect
    let isFocused: Bool
}

protocol GhosttyWindowQuerying {
    func currentWindows() throws -> [GhosttyWindowDescriptor]
    func frontmostWindow() throws -> GhosttyWindowDescriptor?
}
```

- [ ] **Step 2: Add a small compile-only permission service**

Expose:

- current permission status
- request/open-settings action

Keep system calls isolated.

- [ ] **Step 3: Implement AX query service minimally**

Only enumerate Ghostty windows and basic metadata. Do not add matching or activation here.

- [ ] **Step 4: Manually verify window enumeration**

Run the app with Ghostty open and confirm the query service can see at least one Ghostty window title.

- [ ] **Step 5: Run full app test suite**

Run: `cd vigil && make test`
Expected: PASS.

- [ ] **Step 6: Commit**

Commit message: `feat: add vigil ghostty window query services`

### Task 9: Implement Pure Ghostty Matching and Manual Binding Logic

**Files:**
- Create: `vigil/Vigil/Ghostty/GhosttyWindowMatcher.swift`
- Create: `vigil/Vigil/Ghostty/GhosttyWindowBinder.swift`
- Modify: `vigil/Vigil/Persistence/BindingPersistence.swift`
- Create: `vigil/VigilTests/Ghostty/GhosttyWindowMatcherTests.swift`
- Create: `vigil/VigilTests/Ghostty/GhosttyWindowBinderTests.swift`

- [ ] **Step 1: Write failing matcher tests**

Test cases:

- exact project name/title match beats loose substring match
- `cwd` hint match beats title-only fuzzy match
- `tty` or `tabTitle` hint improves score when present
- persisted window signature improves match confidence
- stale or missing signature falls back to fuzzy match

- [ ] **Step 2: Write failing binder tests**

Test cases:

- binding stores a `WindowSignature`
- invalidated window removes binding
- binder can produce a rematch candidate after relaunch

- [ ] **Step 3: Implement pure matcher scoring**

Suggested weighted inputs:

- strong match: project name in title
- strong match: exact `cwd` path hint match if available
- strong match: exact `tabTitle` hint match if available
- medium match: `tty` hint match if available
- medium match: session title in title
- medium match: frame similarity to persisted signature
- weak match: recent frontmost preference

Do not over-engineer. A simple additive score is enough.

- [ ] **Step 4: Implement binder persistence logic**

Store:

- title
- frame
- observedAt
- sessionId

Persist bindings using `BindingPersistence`, not in-memory only.

- [ ] **Step 5: Run focused ghostty logic tests**

Run: `cd vigil && xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/GhosttyWindowMatcherTests -only-testing:VigilTests/GhosttyWindowBinderTests`
Expected: PASS.

- [ ] **Step 6: Run full app test suite**

Run: `cd vigil && make test`
Expected: PASS.

- [ ] **Step 7: Commit**

Commit message: `feat: add vigil ghostty matching and binding`

### Task 10: Implement Ghostty Window Activation and Menu Actions

**Files:**
- Create: `vigil/Vigil/Ghostty/GhosttyWindowActivator.swift`
- Modify: `vigil/Vigil/UI/SessionMenuActions.swift`
- Modify: `vigil/Vigil/App/MenuBarController.swift`
- Modify: `vigil/Vigil/State/AppState.swift`

- [ ] **Step 1: Add protocol for activation**

Define a protocol separate from matching:

```swift
protocol GhosttyWindowActivating {
    func activateBestWindow(for snapshot: SessionSnapshot) throws
    func bindFrontmostWindow(to sessionId: String) throws
}
```

- [ ] **Step 2: Implement activation flow**

Requirements:

- ask matcher for best window
- raise Ghostty app
- raise chosen window
- return typed errors for permission denied, no match, activation failure

- [ ] **Step 3: Expose menu actions**

Actions needed:

- jump to window
- bind frontmost ghostty window
- refresh mappings

- [ ] **Step 4: Manually verify jump behavior**

Create at least two Ghostty windows, simulate two sessions, and verify clicking the menu item usually raises the expected window.

- [ ] **Step 5: Run full app test suite**

Run: `cd vigil && make test`
Expected: PASS.

- [ ] **Step 6: Commit**

Commit message: `feat: add vigil ghostty jump actions`

### Task 11: Create the Plugin Package and Pure Mapping Logic

**Files:**
- Create: `vigil/plugin/package.json`
- Create: `vigil/plugin/tsconfig.json`
- Create: `vigil/plugin/README.md`
- Create: `vigil/plugin/src/types.ts`
- Create: `vigil/plugin/src/mapper.ts`
- Create: `vigil/plugin/src/session-cache.ts`
- Create: `vigil/plugin/test/mapper.test.ts`
- Create: `vigil/plugin/test/session-cache.test.ts`

- [ ] **Step 1: Initialize the plugin package**

Use Bun-compatible scripts:

```json
{
  "name": "vigil-opencode-plugin",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "bun test",
    "typecheck": "tsc --noEmit"
  }
}
```

- [ ] **Step 2: Write failing mapper tests**

Test cases:

- OpenCode idle/completion maps to `session.completed`
- permission request maps to `session.permission_requested`
- question maps to `session.waiting_input`
- generic activity maps to `session.updated`

- [ ] **Step 3: Write failing session-cache tests**

Test cases:

- cache returns full latest snapshot
- heartbeat refresh preserves latest status
- closed session removes cache entry

- [ ] **Step 4: Implement shared plugin types**

Mirror the app transport schema exactly. Do not create “similar but different” names.

- [ ] **Step 5: Implement mapper and session cache**

The mapper should not perform I/O. It only turns hook input into a `VigilEvent | null`.

- [ ] **Step 6: Run plugin tests and typecheck**

Run:

```bash
cd vigil/plugin && bun test && bun run typecheck
```

Expected: PASS.

- [ ] **Step 7: Commit**

Commit message: `feat: add vigil plugin event mapping`

### Task 12: Implement Bridge Discovery and HTTP Delivery in the Plugin

**Files:**
- Create: `vigil/plugin/src/bridge.ts`
- Create: `vigil/plugin/src/transport.ts`
- Create: `vigil/plugin/test/bridge.test.ts`
- Create: `vigil/plugin/test/transport.test.ts`

- [ ] **Step 1: Write failing bridge tests**

Test cases:

- reads `~/.config/vigil/bridge.json`
- returns null when file missing
- reloads after failure

- [ ] **Step 2: Write failing transport tests**

Test cases:

- sends bearer token header
- fails fast on timeout
- swallows connection failure without throwing into plugin caller

- [ ] **Step 3: Implement bridge reader**

Requirements:

- lazy load
- cache successful read briefly
- force refresh after `401` or network failure

- [ ] **Step 4: Implement HTTP transport**

Requirements:

- POST full snapshot event to `/v1/events`
- 1-2 second timeout
- no retries in-line with a user-facing OpenCode turn
- return structured result instead of throwing raw errors

- [ ] **Step 5: Run plugin tests and typecheck**

Run:

```bash
cd vigil/plugin && bun test && bun run typecheck
```

Expected: PASS.

- [ ] **Step 6: Commit**

Commit message: `feat: add vigil plugin bridge delivery`

### Task 13: Register OpenCode Hooks and Emit Real Events

**Files:**
- Create: `vigil/plugin/src/plugin.ts`
- Create: `vigil/plugin/src/index.ts`
- Modify: `vigil/plugin/README.md`

- [ ] **Step 1: Implement plugin registration with the thinnest possible hooks**

Requirements:

- subscribe only to events needed by the spec
- feed raw input into mapper
- update session cache
- send full snapshot through transport

- [ ] **Step 2: Add active-session heartbeat support**

Requirements:

- emit `session.updated` every 15 seconds for active sessions
- stop heartbeat for `complete`, `error`, or `closed`
- keep implementation isolated in `session-cache.ts` or a tiny helper, not inside hook glue

- [ ] **Step 3: Document local plugin install flow**

Document at least:

- where to place the plugin locally
- how the bridge file is discovered
- how to verify delivery using the app logs or health endpoint

- [ ] **Step 4: Run plugin tests and typecheck**

Run:

```bash
cd vigil/plugin && bun test && bun run typecheck
```

Expected: PASS.

- [ ] **Step 5: Commit**

Commit message: `feat: add vigil opencode plugin integration`

### Task 14: Connect App and Plugin End-to-End with Diagnostics

**Files:**
- Create: `vigil/Vigil/UI/DiagnosticsView.swift`
- Modify: `vigil/Vigil/State/AppState.swift`
- Modify: `vigil/Vigil/App/MenuBarController.swift`
- Modify: `vigil/Vigil/README.md`
- Modify: `vigil/plugin/README.md`

- [ ] **Step 1: Add app-side diagnostics state**

Track:

- transport server status
- bridge file status
- last event received time
- accessibility permission status
- last jump error

- [ ] **Step 2: Surface diagnostics in the menu or settings**

Keep V1 minimal. A simple diagnostics submenu or SwiftUI sheet is enough.

- [ ] **Step 3: Run an end-to-end manual test**

Checklist:

- launch app
- confirm bridge file exists
- curl health endpoint
- install plugin locally
- trigger OpenCode activity
- verify menu updates for running, waiting input, complete, error
- click a session and verify Ghostty jumps
- manually bind frontmost Ghostty window and verify improved matching

- [ ] **Step 4: Write README setup instructions**

Document:

- prerequisites
- permissions
- build commands
- local plugin install
- troubleshooting

- [ ] **Step 5: Run full verification**

Run:

```bash
cd vigil && make test
cd vigil/plugin && bun test && bun run typecheck
```

Expected: PASS.

- [ ] **Step 6: Commit**

Commit message: `feat: wire vigil end to end`

### Task 15: Packaging Prep for Local Install and Future Brew Distribution

**Files:**
- Modify: `vigil/README.md`
- Create: `vigil/docs/distribution.md`
- Modify: `vigil/Makefile`

- [ ] **Step 1: Add local build commands**

Add `make build` and `make test-plugin` or similar.

- [ ] **Step 2: Write distribution notes**

Include:

- local unsigned install workflow
- future GitHub Releases plan
- future notarization plan
- future Homebrew Cask outline

- [ ] **Step 3: Verify clean-room setup docs**

Pretend you are a new contributor. Confirm the README is enough to bootstrap the app and plugin from scratch.

- [ ] **Step 4: Commit**

Commit message: `docs: add vigil distribution and setup notes`

## Final Verification Checklist

Before claiming implementation complete, the executing agent must run all of these and record the output summary:

- [ ] `cd vigil && xcodegen generate`
- [ ] `cd vigil && xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS'`
- [ ] `cd vigil/plugin && bun test`
- [ ] `cd vigil/plugin && bun run typecheck`
- [ ] manual health endpoint check
- [ ] manual menu update check
- [ ] manual Ghostty jump check
- [ ] manual bind-current-window recovery check

## Reviewer Checklist

The final reviewer should explicitly verify:

- the app uses a monochrome menu bar template icon
- all event payloads are full snapshots
- the plugin never blocks OpenCode when Vigil is offline
- stale/complete/closed retention rules match the spec
- Ghostty APIs are isolated behind service boundaries
- no `.pbxproj` was edited directly if `XcodeGen` is in use
- the README documents permissions and local install flow

## Handoff Notes for a Low-Cost Coding Agent

If a lower-cost model executes this plan, it should follow these constraints:

1. Never jump ahead and edit five subsystems at once.
2. Finish one numbered task completely before starting the next.
3. Keep all system integrations behind protocols.
4. Prefer adding pure tests first, then system wrappers.
5. If a macOS system API is hard to test, test the pure logic around it and keep the API wrapper tiny.
6. If Ghostty integration becomes unclear, do not invent private APIs. Stay with Accessibility-based discovery and activation.
7. If OpenCode hook names differ from assumptions, adapt only `plugin.ts` and keep the shared event schema unchanged.
8. If packaging or signing becomes distracting, stop and leave it for the packaging task.

## Notes

- This workspace is not currently a Git repository, so commit steps are part of the execution plan but cannot be performed yet unless the repo is initialized.
- If implementation starts before Git initialization, still follow task boundaries and run verification after each task.
