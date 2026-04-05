# Session Lifecycle

Vigil uses a session panel to show the OpenCode sessions that currently matter.

## Visibility Rules

A session enters the session panel when it becomes active in OpenCode. In practice, this means Vigil has received an activity event for that session, such as a running update, a question, or a permission request.

When a session becomes idle, Vigil does not remove it immediately. Instead, the session remains visible for a short idle retention period so the user can still find recent work.

If the session stays idle for longer than the retention period and no new activity arrives, Vigil removes it from the session panel automatically.

Vigil reevaluates session freshness in the background, so long-idle sessions can disappear even if the session panel stays closed.

If a session is explicitly deleted, Vigil removes it from the session panel immediately.

## Product Intent

This behavior keeps the session panel focused on current and recently active work:

- active sessions appear automatically
- recently active sessions remain visible briefly after going idle
- long-idle sessions disappear without manual cleanup
- explicitly deleted sessions disappear immediately
