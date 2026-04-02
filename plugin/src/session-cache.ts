import type { VigilEvent, VigilSessionSnapshot } from "./types"

export class SessionCache {
  private snapshots = new Map<string, VigilSessionSnapshot>()

  upsert(event: VigilEvent): VigilSessionSnapshot {
    this.snapshots.set(event.session.sessionId, event.session)
    return event.session
  }

  snapshot(sessionId: string): VigilSessionSnapshot | undefined {
    return this.snapshots.get(sessionId)
  }

  close(sessionId: string): void {
    this.snapshots.delete(sessionId)
  }

  heartbeat(sessionId: string, timestamp: string): VigilEvent | null {
    const snapshot = this.snapshots.get(sessionId)
    if (!snapshot) {
      return null
    }

    return {
      source: "opencode",
      version: 1,
      eventId: crypto.randomUUID(),
      eventType: "session.updated",
      sentAt: timestamp,
      session: snapshot,
      payload: {
        message: "Session heartbeat",
        error: null,
        requiresAttentionReason: null,
      },
    }
  }
}
