import type { OpencodeHookEvent, SessionMetadata } from "./types"

type OpencodeRuntimeEvent = {
  type: string
  properties?: any
}

export function sessionIdFromRuntimeEvent(event: OpencodeRuntimeEvent): string | undefined {
  return event.properties?.sessionID ?? event.properties?.info?.id
}

function toProjectName(directory: string): string {
  const parts = directory.split("/").filter(Boolean)
  return parts[parts.length - 1] ?? "unknown-project"
}

function toTimestamp(value: number | string | undefined): string {
  if (typeof value === "number") {
    return new Date(value).toISOString()
  }

  return value ?? new Date().toISOString()
}

export function metadataFromSessionEvent(event: OpencodeRuntimeEvent): SessionMetadata {
  const properties = event.properties
  const info = properties.info

  return {
    sessionId: sessionIdFromRuntimeEvent(event) ?? info.id,
    sessionTitle: info.title,
    projectPath: info.directory,
    projectName: toProjectName(info.directory),
    timestamp: toTimestamp(info.time?.updated ?? info.time?.created),
  }
}

export function opencodeEventToHookEvent(event: OpencodeRuntimeEvent, metadata: SessionMetadata | undefined): OpencodeHookEvent | null {
  switch (event.type) {
    case "session.status": {
      if (!metadata) return null
      const status = (event as any).properties.status
      if (status.type !== "busy") return null

      return {
        kind: "update",
        sessionId: metadata.sessionId,
        sessionTitle: metadata.sessionTitle,
        projectPath: metadata.projectPath,
        projectName: metadata.projectName,
        timestamp: new Date().toISOString(),
      }
    }

    case "question.asked": {
      if (!metadata) return null
      const properties = (event as any).properties
      return {
        kind: "question",
        sessionId: metadata.sessionId,
        sessionTitle: metadata.sessionTitle,
        projectPath: metadata.projectPath,
        projectName: metadata.projectName,
        message: properties.questions.map((question: { question: string }) => question.question).join(" | "),
        timestamp: new Date().toISOString(),
      }
    }

    case "permission.asked": {
      const properties = (event as any).properties
      if (!metadata || metadata.sessionId !== properties.sessionID) return null

      return {
        kind: "permission",
        sessionId: metadata.sessionId,
        sessionTitle: metadata.sessionTitle,
        projectPath: metadata.projectPath,
        projectName: metadata.projectName,
        message: properties.pattern,
        timestamp: new Date().toISOString(),
      }
    }

    case "session.idle": {
      if (!metadata) return null
      return {
        kind: "complete",
        sessionId: metadata.sessionId,
        sessionTitle: metadata.sessionTitle,
        projectPath: metadata.projectPath,
        projectName: metadata.projectName,
        timestamp: new Date().toISOString(),
      }
    }

    case "session.error": {
      if (!metadata) return null
      const properties = (event as any).properties
      return {
        kind: "error",
        sessionId: metadata.sessionId,
        sessionTitle: metadata.sessionTitle,
        projectPath: metadata.projectPath,
        projectName: metadata.projectName,
        error: properties.error ? JSON.stringify(properties.error) : "unknown error",
        timestamp: new Date().toISOString(),
      }
    }

    case "session.deleted": {
      if (!metadata) return null
      return {
        kind: "close",
        sessionId: metadata.sessionId,
        sessionTitle: metadata.sessionTitle,
        projectPath: metadata.projectPath,
        projectName: metadata.projectName,
        timestamp: new Date().toISOString(),
      }
    }

    default:
      return null
  }
}
