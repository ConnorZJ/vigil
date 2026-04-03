# Popover Outside-Click Close Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Vigil menu bar popover close on the first click outside the popover after it opens.

**Architecture:** Keep the existing `NSPopover` flow and add explicit outside-click monitoring in `StatusItemPopoverController`. Use both local and global mouse monitors so the first outside click is observed whether it lands inside Vigil, another app, or the desktop. Model both the close decision and monitor lifecycle behind a small test seam so XCTest can verify registration and cleanup deterministically.

**Tech Stack:** Swift, AppKit, XCTest

---

### Task 1: Add failing regression test

**Files:**
- Modify: `VigilTests/App/StatusItemPopoverControllerTests.swift`
- Test: `VigilTests/App/StatusItemPopoverControllerTests.swift`

- [ ] **Step 1: Write the failing test**

Add a focused failing test that requires an explicit monitor seam. The test should prove the controller installs dismissal monitors on open, removes them on close, and exposes the outside-click decision in a way that can distinguish inside-vs-outside hits.

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/StatusItemPopoverControllerTests`

Expected: FAIL because the new monitor seam or close-decision behavior does not exist yet.

### Task 2: Implement minimal outside-click handling

**Files:**
- Modify: `Vigil/App/StatusItemPopoverController.swift`
- Test: `VigilTests/App/StatusItemPopoverControllerTests.swift`

- [ ] **Step 1: Add a minimal testable helper**

Introduce the smallest helper needed to answer whether a click should close the popover based on the popover and status item windows, plus a tiny monitor-installation abstraction that can be observed in tests.

- [ ] **Step 2: Install local and global monitors on show**

Register local and global mouse-down monitors when the popover opens.

- [ ] **Step 3: Close on outside click**

If the click is outside the popover and outside the status item button, close the popover immediately.

- [ ] **Step 4: Remove monitors on close**

Ensure both event monitors are removed when the popover closes, whether via explicit close or delegate callback.

- [ ] **Step 5: Run targeted tests**

Run: `xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/StatusItemPopoverControllerTests`

Expected: PASS.

### Task 3: Verify targeted regression coverage

**Files:**
- Test: `VigilTests/App/StatusItemPopoverControllerTests.swift`

- [ ] **Step 1: Re-run the focused regression suite**

Run: `xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/StatusItemPopoverControllerTests`

Expected: PASS with the new outside-click dismissal coverage.
