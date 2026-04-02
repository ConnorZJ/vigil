import type { VigilEvent } from "./types"
import type { BridgeConfig, BridgeReader } from "./bridge"

export interface DeliveryResult {
  ok: boolean
  status?: number
}

type FetchLike = (input: string, init?: RequestInit) => Promise<Response>

export class VigilTransport {
  constructor(
    private readonly bridgeReader: BridgeReader,
    private readonly fetchImpl: FetchLike = fetch
  ) {}

  async send(event: VigilEvent): Promise<DeliveryResult> {
    const bridge = await this.bridgeReader.read()
    if (!bridge) {
      return { ok: false }
    }

    return this.deliver(event, bridge)
  }

  private async deliver(event: VigilEvent, bridge: BridgeConfig): Promise<DeliveryResult> {
    try {
      const response = await this.fetchImpl(`http://127.0.0.1:${bridge.port}/v1/events`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${bridge.token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(event),
        signal: AbortSignal.timeout(2000),
      })

      if (response.status === 401) {
        await this.bridgeReader.refresh()
      }

      return { ok: response.ok, status: response.status }
    } catch {
      await this.bridgeReader.refresh()
      return { ok: false }
    }
  }
}
