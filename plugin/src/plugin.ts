import type { Plugin } from "@opencode-ai/plugin"
import type { Event } from "@opencode-ai/sdk"
import { mapOpencodeEvent } from "./mapper"
import { metadataFromSessionEvent, opencodeEventToHookEvent, sessionIdFromRuntimeEvent } from "./opencode-adapter"
import { BridgeReader } from "./bridge"
import { SessionCache } from "./session-cache"
import type { OpencodeHookEvent, SessionMetadata } from "./types"
import { VigilTransport } from "./transport"

export interface VigilPluginController {
  handle(event: OpencodeHookEvent): Promise<void>
  dispose(): void
}

const ACTIVE_EVENT_KINDS = new Set<OpencodeHookEvent["kind"]>(["update", "question", "permission"])

export function createVigilPlugin(transport: VigilTransport): VigilPluginController {
  const cache = new SessionCache()
  const heartbeats = new Map<string, Timer>()

  async function handle(event: OpencodeHookEvent): Promise<void> {
    const mapped = mapOpencodeEvent(event)

    if (event.kind === "close") {
      cache.close(event.sessionId)
      stopHeartbeat(event.sessionId)
      await transport.send(mapped)
      return
    }

    cache.upsert(mapped)
    await transport.send(mapped)

    if (ACTIVE_EVENT_KINDS.has(event.kind)) {
      startHeartbeat(event.sessionId)
    } else {
      stopHeartbeat(event.sessionId)
    }
  }

  function startHeartbeat(sessionId: string): void {
    stopHeartbeat(sessionId)

    const timer = setInterval(async () => {
      const heartbeat = cache.heartbeat(sessionId, new Date().toISOString())
      if (heartbeat) {
        await transport.send(heartbeat)
      }
    }, 15_000)

    heartbeats.set(sessionId, timer)
  }

  function stopHeartbeat(sessionId: string): void {
    const timer = heartbeats.get(sessionId)
    if (timer) {
      clearInterval(timer)
      heartbeats.delete(sessionId)
    }
  }

  return {
    handle,
    dispose() {
      for (const timer of heartbeats.values()) {
        clearInterval(timer)
      }
      heartbeats.clear()
    },
  }
}

export const VigilPlugin: Plugin = async () => {
  const controller = createVigilPlugin(new VigilTransport(new BridgeReader()))
  const metadata = new Map<string, SessionMetadata>()

  return {
    event: async ({ event }: { event: Event }) => {
      const payload: Event = ((event as any).payload ?? event) as Event

      if (payload.type === "session.created" || payload.type === "session.updated") {
        const sessionMetadata = metadataFromSessionEvent(payload)
        metadata.set(sessionMetadata.sessionId, sessionMetadata)
        return
      }

      const sessionID = sessionIdFromRuntimeEvent(payload as any)
      const hookEvent = opencodeEventToHookEvent(payload, sessionID ? metadata.get(sessionID) : undefined)

      if (!hookEvent) {
        return
      }

      await controller.handle(hookEvent)

      if (hookEvent.kind === "close") {
        metadata.delete(hookEvent.sessionId)
      }
    },
  }
}
