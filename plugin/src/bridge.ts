import { readFile } from "node:fs/promises"
import { homedir } from "node:os"
import { join } from "node:path"

export interface BridgeConfig {
  version: number
  port: number
  token: string
  updatedAt: string
}

export class BridgeReader {
  private cached: BridgeConfig | null = null

  constructor(
    private readonly bridgePath: string = join(homedir(), ".config", "vigil", "bridge.json"),
    private readonly readText: (path: string) => Promise<string> = (path) => readFile(path, "utf8")
  ) {}

  async read(): Promise<BridgeConfig | null> {
    if (this.cached) {
      return this.cached
    }

    try {
      const contents = await this.readText(this.bridgePath)
      const parsed = JSON.parse(contents) as BridgeConfig
      this.cached = parsed
      return parsed
    } catch {
      return null
    }
  }

  async refresh(): Promise<BridgeConfig | null> {
    this.cached = null
    return this.read()
  }
}
