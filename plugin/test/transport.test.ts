import { describe, expect, test } from "bun:test"
import { BridgeReader } from "../src/bridge"
import { VigilTransport } from "../src/transport"
import type { VigilEvent } from "../src/types"

function makeEvent(): VigilEvent {
  return {
    source: "opencode",
    version: 1,
    eventId: "event-1",
    eventType: "session.updated",
    sentAt: "2026-04-02T00:00:00.000Z",
    session: {
      sessionId: "session-1",
      sessionTitle: "Refactor auth middleware",
      projectPath: "/tmp/vigil",
      projectName: "vigil",
      terminalApp: "ghostty",
      status: "running",
      updatedAt: "2026-04-02T00:00:00.000Z",
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

describe("VigilTransport", () => {
  test("sends bearer token header", async () => {
    let authHeader = ""
    const reader = new BridgeReader("/tmp/bridge.json", async () =>
      JSON.stringify({ version: 1, port: 48127, token: "secret", updatedAt: "2026-04-02T00:00:00.000Z" })
    )
    const transport = new VigilTransport(reader, async (_url: string, init?: RequestInit) => {
      authHeader = String((init?.headers as Record<string, string>).Authorization)
      return new Response(null, { status: 202 })
    })

    await transport.send(makeEvent())
    expect(authHeader).toBe("Bearer secret")
  })

  test("fails fast on timeout or network error", async () => {
    const reader = new BridgeReader("/tmp/bridge.json", async () =>
      JSON.stringify({ version: 1, port: 48127, token: "secret", updatedAt: "2026-04-02T00:00:00.000Z" })
    )
    const transport = new VigilTransport(reader, async () => {
      throw new Error("network")
    })

    expect(await transport.send(makeEvent())).toEqual({ ok: false })
  })

  test("swallows connection failure without throwing", async () => {
    const reader = new BridgeReader("/tmp/bridge.json", async () =>
      JSON.stringify({ version: 1, port: 48127, token: "secret", updatedAt: "2026-04-02T00:00:00.000Z" })
    )
    const transport = new VigilTransport(reader, async () => {
      throw new Error("connection refused")
    })

    await expect(transport.send(makeEvent())).resolves.toEqual({ ok: false })
  })
})
