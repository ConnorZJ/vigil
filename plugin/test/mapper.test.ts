import { describe, expect, test } from "bun:test"
import { mapOpencodeEvent } from "../src/mapper"
import type { OpencodeHookEvent } from "../src/types"

function makeEvent(kind: OpencodeHookEvent["kind"]): OpencodeHookEvent {
  return {
    kind,
    sessionId: "session-1",
    sessionTitle: "Refactor auth middleware",
    projectPath: "/tmp/vigil",
    projectName: "vigil",
    timestamp: "2026-04-02T00:00:00.000Z",
    message: "message",
    error: kind === "error" ? "boom" : undefined,
    cwd: "/tmp/vigil",
    tabTitle: "agent",
    tty: "/dev/ttys001",
  }
}

describe("mapOpencodeEvent", () => {
  test("maps completion to session.completed", () => {
    expect(mapOpencodeEvent(makeEvent("complete")).eventType).toBe("session.completed")
  })

  test("maps permission to session.permission_requested", () => {
    expect(mapOpencodeEvent(makeEvent("permission")).eventType).toBe("session.permission_requested")
  })

  test("maps question to session.waiting_input", () => {
    expect(mapOpencodeEvent(makeEvent("question")).eventType).toBe("session.waiting_input")
  })

  test("maps generic activity to session.updated", () => {
    expect(mapOpencodeEvent(makeEvent("update")).eventType).toBe("session.updated")
  })
})
