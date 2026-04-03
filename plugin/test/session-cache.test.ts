import { describe, expect, test } from "bun:test"
import { SessionCache } from "../src/session-cache"
import type { VigilEvent } from "../src/types"

function makeEvent(status: VigilEvent["session"]["status"]): VigilEvent {
  return {
    source: "opencode",
    version: 1,
    eventId: crypto.randomUUID(),
    eventType: "session.updated",
    sentAt: "2026-04-02T00:00:00.000Z",
    session: {
      sessionId: "session-1",
      sessionTitle: "Refactor auth middleware",
      projectPath: "/tmp/vigil",
      projectName: "vigil",
      terminalApp: "ghostty",
      status,
      updatedAt: "2026-04-02T00:00:00.000Z",
      windowHint: {
        cwd: "/tmp/vigil",
      },
      workspaceHint: null,
      lastError: null,
      requiresAttentionReason: null,
      isStale: false,
    },
    payload: {
      message: null,
      error: null,
      requiresAttentionReason: null,
    },
  }
}

describe("SessionCache", () => {
  test("returns the latest full snapshot", () => {
    const cache = new SessionCache()
    cache.upsert(makeEvent("running"))
    cache.upsert(makeEvent("waitingInput"))

    expect(cache.snapshot("session-1")?.status).toBe("waitingInput")
  })

  test("heartbeat preserves latest status", () => {
    const cache = new SessionCache()
    cache.upsert(makeEvent("permission"))

    expect(cache.heartbeat("session-1", "2026-04-02T00:01:00.000Z")?.session.status).toBe("permission")
  })

  test("closed session removes cache entry", () => {
    const cache = new SessionCache()
    cache.upsert(makeEvent("running"))
    cache.close("session-1")

    expect(cache.snapshot("session-1")).toBeUndefined()
  })
})
