import { describe, expect, test } from "bun:test"
import { BridgeReader } from "../src/bridge"

describe("BridgeReader", () => {
  test("reads bridge config", async () => {
    const reader = new BridgeReader("/tmp/bridge.json", async () =>
      JSON.stringify({ version: 1, port: 48127, token: "secret", updatedAt: "2026-04-02T00:00:00.000Z" })
    )

    const bridge = await reader.read()
    expect(bridge?.port).toBe(48127)
  })

  test("returns null when bridge file is missing", async () => {
    const reader = new BridgeReader("/tmp/missing.json", async () => {
      throw new Error("missing")
    })

    expect(await reader.read()).toBeNull()
  })

  test("refresh reloads after failure", async () => {
    let calls = 0
    const reader = new BridgeReader("/tmp/bridge.json", async () => {
      calls += 1
      if (calls === 1) {
        return JSON.stringify({ version: 1, port: 1111, token: "old", updatedAt: "2026-04-02T00:00:00.000Z" })
      }

      return JSON.stringify({ version: 1, port: 2222, token: "new", updatedAt: "2026-04-02T00:00:01.000Z" })
    })

    expect((await reader.read())?.port).toBe(1111)
    expect((await reader.refresh())?.port).toBe(2222)
  })
})
