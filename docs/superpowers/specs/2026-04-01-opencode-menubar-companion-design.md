# OpenCode Menu Bar Companion Design

## Summary

Build a non-sandboxed macOS menu bar application called `Vigil` that receives OpenCode session status updates from a local OpenCode plugin and helps the user track multiple concurrent Ghostty-based OpenCode sessions. The product should surface which sessions are running, waiting for input, requesting permission, completed, or failed, and allow the user to jump back to the most relevant Ghostty window from the menu.

The first version focuses on reliability and clarity rather than high-fidelity visual chrome. The primary UI is a menu bar item with a dropdown session list. Dynamic notch-adjacent UI is explicitly deferred until the underlying status transport, session model, and window-jump behavior are proven stable.

## Goals

- Show the current global OpenCode attention state from the macOS menu bar.
- Track multiple concurrent OpenCode sessions from Ghostty.
- Strongly surface sessions that need user attention.
- Let the user click a session in the menu and jump back to the corresponding Ghostty window.
- Keep the OpenCode-side integration thin so the product can evolve independently.
- Ship first as a local-install macOS app, with GitHub Releases and Homebrew Cask support added after the core workflow is stable.

## Non-Goals

- Notch-adjacent floating UI in the first version.
- Mac App Store distribution or sandbox compliance in the first version.
- Multi-terminal support in the first version.
- Pane-accurate Ghostty navigation in the first version.
- Sending prompts or commands back into OpenCode from the app.
- Cloud sync, shared dashboards, or remote multi-machine orchestration.

## User Experience

### Primary workflow

1. The user installs the macOS menu bar app.
2. The user installs the companion OpenCode plugin.
3. OpenCode sessions emit local events to the app.
4. The menu bar icon reflects the highest-priority active session state.
5. Clicking the menu bar icon opens a dropdown with all tracked sessions.
6. Clicking a session attempts to activate the matching Ghostty window.
7. If matching fails, the user can manually bind the frontmost Ghostty window to that session.

### Menu bar behavior

- The top-level menu bar icon uses a monochrome template image.
- The icon represents the single highest-priority active state.
- A small count badge may be shown when multiple sessions are active.
- The menu opens to a structured list rather than directly jumping to a window.

### Session grouping in the menu

- Summary section
- Needs attention
- Running
- Recently completed
- Utility actions

Each session row shows:

- Session title
- Project name
- Current status
- Relative last-updated time
- Optional secondary detail such as error text or waiting reason

## System Architecture

The system is split into three layers.

### 1. OpenCode plugin

Responsibilities:

- Observe OpenCode events.
- Translate raw OpenCode activity into a stable companion protocol.
- Send events to the local menu bar app.

Non-responsibilities:

- UI
- Window activation
- Long-term state management

### 2. macOS menu bar app

Responsibilities:

- Run as the single state authority.
- Receive and store session updates.
- Compute global attention priority.
- Render menu bar state and dropdown UI.
- Trigger notifications.
- Handle permissions and diagnostics.
- Jump to Ghostty windows.

### 3. Ghostty integration layer

Responsibilities:

- Discover Ghostty windows.
- Match OpenCode sessions to likely Ghostty windows.
- Cache successful mappings.
- Activate the chosen window.

This layer should be isolated behind an internal interface so later support for iTerm, WezTerm, or Terminal.app does not affect the plugin or session model.

## Event Model

The app should not consume raw OpenCode event names directly. The plugin should translate them into a smaller product-specific event vocabulary.

### Session states

- `running`
- `waiting_input`
- `permission`
- `complete`
- `error`
- `unknown`

### Global priority order

`error > waiting_input > permission > complete > running > unknown`

This priority drives the top-level menu bar icon and determines what the product considers the current primary attention target.

### Business events

- `session.started`
- `session.updated`
- `session.waiting_input`
- `session.permission_requested`
- `session.completed`
- `session.failed`
- `session.closed`

This indirection keeps the app protocol stable even if OpenCode's internal event hooks evolve.

## Session Data Model

Each tracked session should store at least:

- `sessionId`
- `sessionTitle`
- `projectPath`
- `projectName`
- `status`
- `updatedAt`
- `terminalApp`
- `windowHint`
- `workspaceHint`
- `lastError`
- `requiresAttention`

### Window hint contents

The first version should support fuzzy Ghostty window matching using any available hints:

- `cwd`
- `tty`
- `tabTitle`
- future Ghostty metadata if available

The app should be resilient to incomplete hints and should treat the hint object as advisory rather than authoritative.

## Plugin-to-App Transport

### Chosen transport

Use local HTTP on `127.0.0.1` with a shared secret.

This is the best first-version tradeoff because it is simple to implement, easy to debug, and naturally decouples the plugin from the app.

The app should choose an available localhost port on first launch and publish both the port and token through a shared bridge file.

### Endpoints

- `POST /v1/events`
- `GET /v1/health`
- `GET /v1/sessions` for diagnostics and future tooling

### Event envelope

```json
{
  "source": "opencode",
  "version": 1,
  "eventId": "uuid",
  "eventType": "session.waiting_input",
  "sentAt": "2026-04-01T12:34:56Z",
  "session": {
    "sessionId": "abc123",
    "sessionTitle": "refactor auth middleware",
    "projectPath": "/Users/you/project/foo",
    "projectName": "foo",
    "terminalApp": "ghostty",
    "status": "waiting_input",
    "windowHint": {
      "cwd": "/Users/you/project/foo",
      "tabTitle": "foo",
      "tty": "/dev/ttys012"
    }
  },
  "payload": {
    "message": "Session is waiting for user input"
  }
}
```

### Authentication

- The app generates a local bearer token on first launch.
- The app writes the token and active localhost port to a shared bridge file at `~/.config/vigil/bridge.json`.
- The plugin reads this bridge file at startup and refreshes it when delivery fails.
- Requests include `Authorization: Bearer <token>`.

Example bridge file:

```json
{
  "version": 1,
  "port": 48127,
  "token": "local-generated-token",
  "updatedAt": "2026-04-01T12:34:56Z"
}
```

Bootstrap and rotation rules:

- The app is the only writer of the bridge file.
- The plugin is read-only.
- If the bridge file is missing, the plugin skips delivery and retries discovery on the next emission.
- If the token changes because the app is reinstalled or reset, the plugin re-reads the bridge file after any `401` or connection failure.

This is sufficient for first-version local-only protection.

### Failure handling

- If the app is offline, the plugin must fail silently and never block OpenCode.
- Requests should time out quickly.
- The app should deduplicate by `eventId`.
- The app should use timestamp-aware state transition logic to handle out-of-order delivery.
- Sessions with no updates for a long period may become `stale` internally.

### Snapshot semantics

Every event sent to the app must include a full session snapshot for the receiving app state, not a partial patch. This keeps reconciliation simple and allows the app to remain the single state authority even if events arrive out of order.

Required fields on every event:

- `eventId`
- `eventType`
- `sentAt`
- `session.sessionId`
- `session.sessionTitle`
- `session.projectPath`
- `session.projectName`
- `session.terminalApp`
- `session.status`

Optional fields:

- `session.windowHint`
- `session.workspaceHint`
- `payload.message`
- `payload.error`
- `payload.requiresAttentionReason`

Event type semantics:

- `session.started`: first snapshot for a newly observed session, status usually `running`
- `session.updated`: non-terminal refresh where the status may stay the same or move between active states
- `session.waiting_input`: snapshot where status is `waiting_input`
- `session.permission_requested`: snapshot where status is `permission`
- `session.completed`: snapshot where status is `complete`
- `session.failed`: snapshot where status is `error`
- `session.closed`: terminal lifecycle event indicating the session should be removed from active UI according to retention rules

## Ghostty Window Matching and Jumping

The first version should optimize for high success rates in common workflows rather than perfect session-to-pane fidelity.

### Chosen control path

The first version should use macOS Accessibility APIs as the primary Ghostty integration mechanism.

Specifically:

- enumerate Ghostty windows through Accessibility
- inspect window titles for fuzzy matching
- activate Ghostty and raise the matched window through Accessibility-compatible window actions

The design should not depend on a Ghostty-specific remote control interface for first release viability.

This decision fixes the permission and implementation model for V1:

- Accessibility permission is required
- Apple Events automation is optional and should only be added later if needed for reliability improvements

### Matching strategy

Use layered matching:

1. Search for candidate Ghostty windows using available hints.
2. Prefer cached successful mappings for previously matched sessions.
3. Fall back to fuzzy matching when the cached reference is missing or stale.

### Matching inputs

- Window title
- `projectPath` and `projectName` from the plugin snapshot
- Session title from the plugin snapshot
- Optional current working directory if the plugin can provide it
- Optional tab title hints if available
- Optional TTY hints if available

Minimum guaranteed match data from the plugin for V1:

- `sessionId`
- `sessionTitle`
- `projectPath`
- `projectName`

Optional hints improve accuracy but are not required for the feature to exist.

### Jump behavior

When the user clicks a session row:

1. Find the best Ghostty window match.
2. Bring Ghostty to the foreground.
3. Bring the matched window to the front.
4. Stop at the window level if pane-level routing is unavailable.

### Manual recovery

If automatic matching fails, the menu should expose:

- `Jump to Window`
- `Bind Frontmost Ghostty Window`

Manual binding allows the user to repair the session-to-window association without restarting either side of the system.

Manual binding semantics:

- the app records a persistent window signature against the selected `sessionId`, not an opaque system window id
- the window signature should include any stable fields the app can observe, such as last known title, approximate frame, and observation timestamp
- this binding survives app relaunch as a best-effort rematch profile
- on relaunch or activation, the app re-identifies the best current Ghostty window from that signature before attempting activation
- the binding is invalidated automatically if no plausible rematch is available or the rematched window can no longer be activated

### Permissions

The app should be designed with non-sandboxed desktop automation in mind and may require:

- Accessibility permission
- Automation permission depending on the chosen control path

Permission state should be visible in the app rather than only surfacing as a failed jump action.

## Session Lifecycle and Retention

The app should persist active session state so relaunching the app does not blank the menu unexpectedly.

Persistence policy:

- `running`, `waiting_input`, `permission`, and `error` sessions are persisted across app relaunches
- `complete` sessions are retained for 10 minutes, then evicted automatically
- `closed` sessions are removed from the active menu immediately
- manual window bindings persist until invalidated or explicitly cleared

Staleness policy:

- the plugin should emit a heartbeat-style `session.updated` snapshot for active sessions every 15 seconds while a session remains active
- if the app receives no update for 45 seconds from an active session, it marks the session as `stale`
- stale sessions remain visible but are visually degraded and are never allowed to outrank non-stale sessions of the same priority

Relaunch behavior:

- persisted active sessions are restored on app launch
- completed sessions are restored only if they are still within the 10-minute retention window
- stale restored sessions remain stale until a fresh snapshot arrives

## Notifications

The menu bar icon is necessary but not sufficient. The app should also emit system notifications for meaningful attention states.

### Notify by default

- `waiting_input`
- `permission`
- `error`
- `complete`

### Do not notify

- `running`

The default policy should be useful but conservative. Completion notifications may later become configurable, but they should be enabled initially because completion is one of the user's primary goals.

## Visual Asset Policy

### Menu bar icon

- Use a monochrome template icon.
- The icon should remain legible at menu bar sizes.
- State changes should rely on a combination of shape and subtle animation rather than color alone.

### Color usage

Rich colored assets are allowed in:

- dropdown menu rows
- settings UI
- onboarding
- app icon
- notifications where appropriate

This keeps the top-level menu bar presence native while still allowing expressive branding and status visuals in expanded surfaces.

## Technology Stack

The first version should use a native macOS stack with minimal moving parts.

### macOS app

- Language: `Swift`
- UI: `SwiftUI` for settings and menu content where practical
- Menu bar integration: `AppKit` via `NSStatusItem`
- Window and permission integration: native macOS frameworks

Rationale:

- best fit for a menu bar utility
- strongest compatibility with macOS permissions and Accessibility APIs
- easiest path to a polished non-sandboxed desktop app

### Local transport server

- lightweight embedded HTTP server inside the macOS app
- bind to `127.0.0.1` only
- avoid heavyweight server frameworks in V1

Implementation preference:

- choose a small native Swift HTTP implementation with low dependency overhead
- keep the transport layer thin and replaceable

### Desktop automation and window control

- primary control path: `Accessibility API`
- optional future enhancement: Apple Events automation only if Accessibility alone proves insufficient

### Persistence

- store app state under `~/Library/Application Support/Vigil/`
- persist session state, bindings, and diagnostics as local JSON in V1
- avoid introducing SQLite unless JSON persistence becomes a real bottleneck

### Bridge file

- store plugin discovery data under `~/.config/vigil/bridge.json`
- this file contains the active localhost port and bearer token

### OpenCode plugin

- language: `TypeScript`
- package form: standard OpenCode plugin installable from local files first, npm package later

Rationale:

- aligns with the documented OpenCode plugin model
- keeps packaging simple for V1
- makes future npm distribution straightforward

### Logging and diagnostics

- app logs written locally in app support storage
- plugin logs should be minimal and fail-silent during normal operation
- diagnostics UI can be added later without changing the transport contract

## Distribution Strategy

### First release

- Non-sandboxed local macOS application
- Local installation workflow
- No Mac App Store support

### Follow-up distribution

- GitHub Releases
- Developer ID signing and notarization
- Homebrew Cask distribution

This sequence preserves delivery speed while keeping a clean path to a polished install story.

## Risks and Mitigations

### Ghostty window identification may be imperfect

Mitigation:

- layered matching
- cached mappings
- manual bind fallback

### Plugin events may be noisy or inconsistent

Mitigation:

- use a narrow business event vocabulary
- keep state transition logic in the app
- deduplicate with event IDs

### Local app may not be running when events occur

Mitigation:

- plugin fails silently
- health endpoint can support future diagnostics

### Desktop automation permissions may confuse users

Mitigation:

- explicit permission status in the menu
- onboarding that explains why the permissions are needed

## First-Version Success Criteria

The first version is successful if:

- the user can install the app and plugin locally
- multiple OpenCode sessions appear in the menu reliably
- attention states are easy to understand at a glance
- waiting, permission, completion, and error states are surfaced clearly
- clicking a session usually returns the user to the right Ghostty window
- mapping failures are recoverable without restarting the system

## Open Questions

- How should the app surface stale sessions in the menu without creating unnecessary alarm?
- Should completion notifications be enabled by default forever, or only during onboarding until the user tunes preferences?
- What diagnostics surface is most useful for plugin delivery failures: menu-only status, a dedicated logs window, or both?

## Implementation Direction

The implementation should start with:

1. menu bar shell app with a fake in-memory session source
2. local HTTP ingestion endpoint and token bootstrapping
3. OpenCode plugin that emits normalized events
4. session store and priority computation
5. Ghostty matching and manual bind flow
6. notifications, diagnostics, and packaging

## Notes

This workspace is not currently a Git repository, so the design document can be written here but cannot be committed until the project is placed under Git.
