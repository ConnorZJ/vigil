# Ghostty Tab Targeting And Session Restore Design

## Goal

Fix two user-visible issues in Vigil:

1. When a Ghostty window contains multiple tabs, clicking a session card should jump to the bound tab instead of always landing on the first tab in that window.
2. After restarting Vigil, the app should immediately restore all still-relevant active sessions from local persistence before fresh OpenCode events arrive.

## Current Behavior

### Ghostty tab targeting

The current binding layer stores only a window title and frame in `WindowSignature`. That is enough to re-identify a Ghostty window, but not enough to disambiguate multiple tabs inside the same window. The activation path also raises a window by matching only AX window title and frame distance, so the best result in a multi-tab window is often the first visible match instead of the tab associated with the selected session.

### Session restore after Vigil restart

`SessionPersistence` can save and load snapshots, but `AppState.bootstrap()` currently only starts the transport server and optional preview data. It does not hydrate `SessionStore` from persisted snapshots, so Vigil starts empty until new events arrive.

## Chosen Approach

Keep the existing architecture, but strengthen the identifying information at both boundaries:

1. Extend Ghostty binding persistence to store tab-level hints, not just window-level hints.
2. Load persisted active session snapshots into `SessionStore` during startup before live transport events arrive.

This keeps the fix local to the existing matching, activation, and persistence flows without introducing a new OpenCode query mechanism.

## Ghostty Tab Targeting Design

### Binding model

When the user binds the frontmost Ghostty target to a session, persist a richer signature built from the current `GhosttyWindowDescriptor`. In addition to title and frame, include the tab-disambiguating fields already present in the descriptor and session hints when available, especially `tabTitle`, `tty`, and `cwd`.

The stored signature should be used as the strongest signal when re-matching a session to a Ghostty target after the initial bind.

To make this possible, the Ghostty query layer must explicitly collect these tab-level fields when available. The design assumes extending the current `GhosttyAXWindowQueryService` and related descriptor-building code so that bind-time and activation-time descriptors actually contain `tabTitle`, `tty`, and `cwd` instead of only `title`, `frame`, and focus state.

### Persistence compatibility

The richer binding signature must remain backward-compatible with existing persisted binding files. Any new stored fields should decode safely when absent, so older on-disk bindings continue loading and simply behave as lower-fidelity window-level matches until they are rebound.

### Matching and activation

The matching path should prefer the persisted tab-level signature first, then fall back to the existing `SessionSnapshot.windowHint` scoring if the persisted data is incomplete or no exact candidate exists.

The activation path should stop relying on window title and frame alone. It should compare the selected matched descriptor against the AX-discovered candidates using the same identifying fields used for matching, so a bound second tab in a shared window can be selected instead of raising the first tab-like match.

### Failure handling

If a persisted tab signature no longer matches any current Ghostty target, Vigil should keep the existing fallback behavior: try the best available runtime match, and if nothing is suitable, surface the existing jump error.

This avoids making the feature brittle when a tab has been renamed, closed, or recreated.

## Session Restore Design

### Startup hydration

During `AppState.bootstrap()`, load persisted snapshots from `SessionPersistence` and apply them into `SessionStore` before starting transport listening.

The restored set should include all locally persisted active sessions that are still within the existing retention rules. This means non-complete sessions should be restored, and recently completed sessions should continue to follow the current persistence filter policy. The user specifically wants all active sessions restored after a Vigil restart, regardless of project.

The hydration path should preserve the snapshot `updatedAt` values and insert them through a store path that respects freshness ordering, so later live events naturally win. Hydration must not run after transport startup in a way that could overwrite newer live state with older persisted data.

### Interaction with live events

Restored snapshots are only an initial view. Once OpenCode emits new events, the normal `SessionStore.apply(event:)` path should overwrite the restored state using live event timestamps.

No separate merge system is needed beyond the existing freshness logic, but the restore insertion path must obey the same timestamp ordering guarantees as event ingestion.

### Staleness

After restoring snapshots, the existing stale-session marking rules should still apply so the UI does not imply that an old restored session is currently active if no new events arrive.

## Alternatives Considered

### Option 1: Recommended

Extend persisted binding signatures and hydrate persisted session snapshots on launch.

Pros:
- Smallest architecture change that addresses both root causes directly
- Uses existing persistence and matching structures
- No dependency on OpenCode being immediately available after launch

Cons:
- Requires evolving persistence models and related tests

### Option 2: Match only from runtime `windowHint`

Do not expand persisted signatures; only tune the matcher to prefer `tabTitle`, `tty`, and `cwd` from the current session snapshot.

Pros:
- Slightly smaller model change

Cons:
- Does not fix the post-bind precision problem when multiple tabs share a window and the persisted bind itself lacks tab-level identity

### Option 3: Query OpenCode for current sessions at launch

Ask OpenCode for live session state after Vigil starts instead of restoring from local persistence.

Pros:
- Potentially freshest state

Cons:
- Introduces a new integration path outside the current architecture
- Larger scope than needed for the reported bugs

## Scope

- Modify Ghostty binding, matching, and activation code to carry tab-level identifying signals
- Modify Vigil startup to restore persisted active session snapshots
- Add focused regression tests for both behaviors

## Non-Goals

- Reworking the overall Ghostty accessibility integration
- Building a new OpenCode session query API
- Changing the general session retention policy beyond using the existing persisted snapshot filtering rules

## Testing

- Add regression coverage for a bound session targeting a non-first tab in a shared Ghostty window
- Add startup hydration coverage proving persisted active sessions are loaded into `SessionStore`
- Verify existing matching and persistence behavior still works for simpler single-window cases
