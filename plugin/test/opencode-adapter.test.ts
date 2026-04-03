import { describe, expect, test } from "bun:test"
import { metadataFromSessionEvent, opencodeEventToHookEvent } from "../src/opencode-adapter"

describe("opencode-adapter", () => {
  test("extracts metadata from session.updated", () => {
    const metadata = metadataFromSessionEvent({
      type: "session.updated",
      properties: {
        sessionID: "session-1",
        info: {
          id: "session-1",
          slug: "session-1",
          projectID: "project-1",
          directory: "/tmp/vigil",
          title: "Refactor auth middleware",
          version: "1",
          time: { created: 1, updated: 2 },
        },
      },
    } as any)

    expect(metadata.projectName).toBe("vigil")
    expect(metadata.sessionTitle).toBe("Refactor auth middleware")
  })

  test("maps question.asked into question hook event", () => {
    const hookEvent = opencodeEventToHookEvent(
      {
        type: "question.asked",
        properties: {
          id: "request-1",
          sessionID: "session-1",
          questions: [
            {
              question: "Continue?",
              header: "Continue",
              options: [],
            },
          ],
        },
      } as any,
      {
        sessionId: "session-1",
        sessionTitle: "Refactor auth middleware",
        projectPath: "/tmp/vigil",
        projectName: "vigil",
        timestamp: new Date().toISOString(),
      }
    )

    expect(hookEvent?.kind).toBe("question")
    expect(hookEvent?.projectName).toBe("vigil")
  })
})
