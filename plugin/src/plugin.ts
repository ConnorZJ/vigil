import { mapOpencodeEvent } from "./mapper"
import { SessionCache } from "./session-cache"
import type { OpencodeHookEvent } from "./types"
import type { VigilTransport } from "./transport"

export interface HookRegistrar {
  on(eventName: string, handler: (event: OpencodeHookEvent) => void | Promise<void>): void
}

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

export function registerHooks(registrar: HookRegistrar, controller: VigilPluginController): void {
  for (const eventName of ["update", "question", "permission", "complete", "error", "close"] as const) {
    registrar.on(eventName, controller.handle)
  }
}
