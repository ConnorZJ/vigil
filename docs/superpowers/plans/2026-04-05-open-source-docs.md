# Open Source Docs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add minimal contributor-facing documentation and improve the public README so the GitHub repository is easier to understand and contribute to.

**Architecture:** Keep the change documentation-only. Use `README.md` as the public landing page and add a concise `CONTRIBUTING.md` that points contributors to the real commands and repo expectations already documented in the repository. Keep all guidance aligned with `AGENTS.md`.

**Tech Stack:** Markdown, Make, Bun, XcodeGen, XCTest

---

### Task 1: Reshape the public README

**Files:**
- Modify: `README.md`
- Reference: `AGENTS.md`
- Reference: `plugin/README.md`

- [ ] **Step 1: Add clearer repository framing**

Add a short introduction that explains Vigil is a macOS menu bar companion plus an OpenCode plugin.

- [ ] **Step 2: Add public-facing status and quick start sections**

Document the early-stage status and the main setup / verification commands contributors should discover first.

- [ ] **Step 3: Keep core operating sections intact**

Preserve and lightly tighten the existing `Permissions`, `Session Lifecycle`, and troubleshooting guidance so the README stays useful for real users.

- [ ] **Step 4: Improve local development wording**

Make the local development and verification paths easier for outside contributors to follow, including the plugin setup and check flow.

- [ ] **Step 5: Add a contribution entry point**

Add a short `Contributing` section that points readers to `CONTRIBUTING.md`.

### Task 2: Add a minimal CONTRIBUTING guide

**Files:**
- Create: `CONTRIBUTING.md`
- Reference: `AGENTS.md`
- Reference: `README.md`

- [ ] **Step 1: Document prerequisites and local setup**

Include a `Prerequisites` section and a `Local Development` section with the real tool requirements and plugin dependency install step.

- [ ] **Step 2: Document verification expectations**

Include a `Verification Before PR` section with the real verification surface:

- `make generate`
- `make build`
- `make test`
- `make test-plugin`
- `cd plugin && bun test`
- `cd plugin && bun run typecheck`

- [ ] **Step 3: Document contribution expectations**

Include a `Documentation Expectations` section stating that docs should be kept in sync with behavior changes.

- [ ] **Step 4: Add pull request guidance**

Include a `Pull Requests` section telling contributors to describe the change clearly, run the relevant checks before opening a PR, and avoid mixing unrelated work.

### Task 3: Verify the docs match the repository

**Files:**
- Test: `README.md`
- Test: `CONTRIBUTING.md`

- [ ] **Step 1: Read the final docs**

Confirm commands, paths, and contributor expectations match the current repository.

- [ ] **Step 2: Cross-check documented commands against repo sources**

Confirm the documented commands are present and consistent with `Makefile`, `plugin/package.json`, `plugin/README.md`, `README.md`, and `AGENTS.md`.

- [ ] **Step 3: Optionally spot-check the plugin verification path**

Run: `make test-plugin`

Expected: plugin tests and typecheck succeed, confirming the documented plugin verification command is still valid.
