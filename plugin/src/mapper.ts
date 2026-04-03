import type { OpencodeHookEvent, VigilEvent, VigilEventType, VigilStatus } from "./types"

function mapKindToStatus(kind: OpencodeHookEvent["kind"]): VigilStatus {
  switch (kind) {
    case "question":
      return "waitingInput"
    case "permission":
      return "permission"
    case "complete":
      return "complete"
    case "error":
      return "error"
    case "update":
      return "running"
    case "close":
      return "complete"
  }
}

function mapKindToEventType(kind: OpencodeHookEvent["kind"]): VigilEventType {
  switch (kind) {
    case "question":
      return "session.waiting_input"
    case "permission":
      return "session.permission_requested"
    case "complete":
      return "session.completed"
    case "error":
      return "session.failed"
    case "close":
      return "session.closed"
    case "update":
      return "session.updated"
  }
}

export function mapOpencodeEvent(event: OpencodeHookEvent): VigilEvent {
  const status = mapKindToStatus(event.kind)

  return {
    source: "opencode",
    version: 1,
    eventId: crypto.randomUUID(),
    eventType: mapKindToEventType(event.kind),
    sentAt: event.timestamp,
    session: {
      sessionId: event.sessionId,
      sessionTitle: event.sessionTitle,
      projectPath: event.projectPath,
      projectName: event.projectName,
      terminalApp: "ghostty",
      status,
      updatedAt: event.timestamp,
      windowHint: {
        cwd: event.cwd,
        tabTitle: event.tabTitle,
        tty: event.tty,
      },
      workspaceHint: null,
      lastError: event.error ?? null,
      requiresAttentionReason:
        status === "waitingInput" || status === "permission" || status === "error"
          ? event.message ?? event.error ?? null
          : null,
      isStale: false,
    },
    payload: {
      message: event.message ?? null,
      error: event.error ?? null,
      requiresAttentionReason:
        status === "waitingInput" || status === "permission" || status === "error"
          ? event.message ?? event.error ?? null
          : null,
    },
  }
}
