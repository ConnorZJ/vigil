# Ghostty Tab Targeting And Session Restore Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make bound Ghostty session cards target the correct tab in multi-tab windows, and restore persisted active sessions when Vigil restarts.

**Architecture:** Extend the existing Ghostty binding signature and query/match pipeline to carry tab-level identifiers (`tabTitle`, `tty`, `cwd`) in a backward-compatible way, then use those identifiers during re-match and activation. Restore persisted snapshots into `SessionStore` during `AppState.bootstrap()` before transport startup so live events can naturally supersede restored state by timestamp.

**Tech Stack:** Swift, AppKit, ApplicationServices, XCTest

---

### File Structure

**Modify:**
- `Vigil/Domain/WindowSignature.swift` - add optional tab-level persisted fields while keeping old on-disk bindings decodable
- `Vigil/Ghostty/GhosttyWindowBinder.swift` - persist richer signatures and use them during re-match scoring
- `Vigil/Ghostty/GhosttyWindowMatcher.swift` - give persisted tab-level identifiers stronger weight than loose title/frame matches
- `Vigil/Ghostty/GhosttyWindowActivator.swift` - match AX-discovered targets with the richer descriptor identity instead of title+frame only
- `Vigil/Ghostty/GhosttyAXWindowQueryService.swift` - populate tab-level descriptor fields from accessibility data where available
- `Vigil/Persistence/SessionPersistence.swift` - expose a protocol-backed load dependency for bootstrap restoration
- `Vigil/State/SessionStore.swift` - add a hydration-safe insertion path that respects existing freshness ordering
- `Vigil/State/AppState.swift` - load persisted snapshots before starting transport and mark restored sessions stale using existing rules
- `VigilTests/Ghostty/GhosttyWindowBinderTests.swift` - cover richer signature persistence and reload
- `VigilTests/Ghostty/GhosttyWindowMatcherTests.swift` - cover persisted tab-level signature preference
- `VigilTests/Ghostty/GhosttyWindowActivatorTests.swift` - cover descriptor identity selection for multi-tab activation
- `VigilTests/State/SessionStoreTests.swift` - cover hydration freshness ordering
- `VigilTests/State/AppStateTransportDiagnosticsTests.swift` - add startup restoration coverage with a fake persistence source

### Task 1: Ghostty tab-aware binding and matching

**Files:**
- Modify: `Vigil/Domain/WindowSignature.swift`
- Modify: `Vigil/Ghostty/GhosttyWindowBinder.swift`
- Modify: `Vigil/Ghostty/GhosttyWindowMatcher.swift`
- Modify: `VigilTests/Ghostty/GhosttyWindowBinderTests.swift`
- Modify: `VigilTests/Ghostty/GhosttyWindowMatcherTests.swift`

- [ ] **Step 1: Write the failing tests**

Add tests that require:
- `WindowSignature` to retain `cwd`, `tabTitle`, and `tty` when present
- older persisted bindings without those fields to remain decodable
- persisted tab-level signature data to beat a competing window/tab candidate with the same title and frame

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/GhosttyWindowBinderTests -only-testing:VigilTests/GhosttyWindowMatcherTests`

Expected: FAIL because the richer signature fields and stronger matching behavior do not exist yet.

- [ ] **Step 3: Implement minimal binding model changes**

Add optional `cwd`, `tabTitle`, and `tty` fields to `WindowSignature` and persist them from `GhosttyWindowBinder.bind(window:to:)`.

- [ ] **Step 4: Implement minimal matching changes**

Update binder rematch scoring and matcher scoring so persisted tab-level identity outranks plain title/frame similarity, while still falling back when new fields are absent.

- [ ] **Step 5: Re-run focused tests**

Run: `xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/GhosttyWindowBinderTests -only-testing:VigilTests/GhosttyWindowMatcherTests`

Expected: PASS.

### Task 2: Ghostty activation uses richer descriptor identity

**Files:**
- Modify: `Vigil/Ghostty/GhosttyAXWindowQueryService.swift`
- Modify: `Vigil/Ghostty/GhosttyWindowActivator.swift`
- Create: `VigilTests/Ghostty/GhosttyWindowActivatorTests.swift`

- [ ] **Step 1: Write the failing test seam**

Add a focused test seam in `GhosttyWindowActivatorTests` around the activator’s descriptor identity comparison so a bound second tab beats a first-tab candidate in the same window title/frame family.

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/GhosttyWindowActivatorTests`

Expected: FAIL because the activator does not yet expose or use a descriptor-based identity comparison path.

- [ ] **Step 3: Extend query descriptors minimally**

Populate `GhosttyWindowDescriptor` fields from the accessibility query service wherever the data is available, without restructuring the service.

- [ ] **Step 4: Implement descriptor-based activation matching**

Change the AX raise path to select the AX target using the same richer identity fields as the chosen descriptor, falling back to title/frame only when tab-level data is absent.

- [ ] **Step 5: Re-run focused tests**

Run: `xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/GhosttyWindowActivatorTests`

Expected: PASS.

### Task 3: Restore persisted sessions during bootstrap

**Files:**
- Modify: `Vigil/Persistence/SessionPersistence.swift`
- Modify: `Vigil/State/SessionStore.swift`
- Modify: `Vigil/State/AppState.swift`
- Modify: `VigilTests/State/SessionStoreTests.swift`
- Modify: `VigilTests/State/AppStateTransportDiagnosticsTests.swift`
- Modify: `VigilTests/Persistence/SessionPersistenceTests.swift`

- [ ] **Step 1: Write the failing tests**

Add tests that require:
- a protocol-backed session persistence dependency that `AppState` can fake in tests
- a hydration path in `SessionStore` to preserve freshness ordering against later live events
- `AppState.bootstrap()` to restore persisted active snapshots before transport startup

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/SessionStoreTests -only-testing:VigilTests/AppStateTransportDiagnosticsTests -only-testing:VigilTests/SessionPersistenceTests`

Expected: FAIL because there is no restore path today.

- [ ] **Step 3: Implement minimal store hydration support**

Add a small insertion API to `SessionStore` that accepts restored snapshots and preserves timestamp freshness guarantees already used by event ingestion.

- [ ] **Step 4: Implement bootstrap restoration**

Introduce the smallest persistence protocol/dependency needed for `AppState` to load persisted snapshots in tests and production, then restore snapshots into the store before `transportServer.start(port:)`, followed by existing stale-session and change notification behavior.

- [ ] **Step 5: Re-run focused tests**

Run: `xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/SessionStoreTests -only-testing:VigilTests/AppStateTransportDiagnosticsTests -only-testing:VigilTests/SessionPersistenceTests`

Expected: PASS.

### Task 4: Verify the combined regression surface

**Files:**
- Test: `VigilTests/Ghostty/GhosttyWindowBinderTests.swift`
- Test: `VigilTests/Ghostty/GhosttyWindowMatcherTests.swift`
- Test: `VigilTests/Ghostty/GhosttyWindowActivatorTests.swift`
- Test: `VigilTests/State/SessionStoreTests.swift`
- Test: `VigilTests/State/AppStateTransportDiagnosticsTests.swift`
- Test: `VigilTests/Persistence/SessionPersistenceTests.swift`

- [ ] **Step 1: Run the combined targeted suite**

Run: `xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/GhosttyWindowBinderTests -only-testing:VigilTests/GhosttyWindowMatcherTests -only-testing:VigilTests/GhosttyWindowActivatorTests -only-testing:VigilTests/SessionStoreTests -only-testing:VigilTests/AppStateTransportDiagnosticsTests -only-testing:VigilTests/SessionPersistenceTests`

Expected: PASS.
