export type VigilStatus =
  | "running"
  | "waitingInput"
  | "permission"
  | "complete"
  | "error"
  | "unknown"

export type VigilEventType =
  | "session.started"
  | "session.updated"
  | "session.waiting_input"
  | "session.permission_requested"
  | "session.completed"
  | "session.failed"
  | "session.closed"

export interface WindowHint {
  cwd?: string
  tabTitle?: string
  tty?: string
}

export interface VigilSessionSnapshot {
  sessionId: string
  sessionTitle: string
  projectPath: string
  projectName: string
  terminalApp: "ghostty"
  status: VigilStatus
  updatedAt: string
  windowHint?: WindowHint
  workspaceHint?: string | null
  lastError?: string | null
  requiresAttentionReason?: string | null
  isStale: boolean
}

export interface VigilEventPayload {
  message?: string | null
  error?: string | null
  requiresAttentionReason?: string | null
}

export interface VigilEvent {
  source: "opencode"
  version: 1
  eventId: string
  eventType: VigilEventType
  sentAt: string
  session: VigilSessionSnapshot
  payload: VigilEventPayload
}

export interface OpencodeHookEvent {
  kind: "update" | "question" | "permission" | "complete" | "error" | "close"
  sessionId: string
  sessionTitle: string
  projectPath: string
  projectName: string
  message?: string
  error?: string
  cwd?: string
  tabTitle?: string
  tty?: string
  timestamp: string
}

export interface SessionMetadata {
  sessionId: string
  sessionTitle: string
  projectPath: string
  projectName: string
  timestamp: string
}
