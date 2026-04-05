# Open Source Docs Design

## Goal

Add the minimum contributor-facing documentation needed to make the public GitHub repository easier to understand and contribute to.

## Scope

- create a concise `CONTRIBUTING.md`
- improve `README.md` for open source readers
- keep changes small and operational
- avoid adding workflow rules that do not exist yet

## Recommended Approach

Use a minimal documentation pass:

- `README.md` becomes the external landing page for users and contributors
- `CONTRIBUTING.md` documents the smallest real contribution workflow
- both files should point to existing commands and repo rules only

## README Changes

Add or improve these sections:

- short project description with app + plugin context
- `Status` section explaining the repository is early-stage / evolving
- `Quick Start` section for generating, building, and testing
- clearer local development and troubleshooting wording for external users
- `Contributing` section pointing to `CONTRIBUTING.md`
- keep the existing permissions and session lifecycle information

## CONTRIBUTING Changes

Create a short file with these sections:

- `Prerequisites`
- `Local Development`
- `Verification Before PR`
- `Documentation Expectations`
- `Pull Requests`

The file should reference existing commands only:

- `cd plugin && bun install`
- `make generate`
- `make build`
- `make test`
- `make test-plugin`
- `cd plugin && bun test`
- `cd plugin && bun run typecheck`

## Constraints

- keep the tone direct and practical
- do not invent lint or formatting commands
- do not document a contribution workflow that the repo does not already use
- keep the change small enough that it is easy to maintain
- keep new contribution guidance aligned with `AGENTS.md`

## Success Criteria

- a new external contributor can install dependencies and run the real verification commands
- the README presents both the macOS app and plugin verification paths
- `CONTRIBUTING.md` stays short and does not over-specify process that the repo does not enforce
