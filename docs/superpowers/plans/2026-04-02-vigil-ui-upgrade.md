# Vigil UI Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade `Vigil` so the menu bar uses simplified pixel-art status icons and the expanded UI moves from `NSMenu` to a custom `NSPopover` with richer SwiftUI content.

**Architecture:** Keep the existing session store, transport, diagnostics, and Ghostty action logic unchanged. Add a dedicated presentation layer for popover content, a simplified top-icon provider for the menu bar button, and an AppKit popover host that renders SwiftUI views from presentation models rather than directly from service objects.

**Tech Stack:** Swift, SwiftUI, AppKit, XCTest, XcodeGen, NSStatusItem, NSPopover

---

## Important Agent Rules

- Do not change plugin protocol, session store semantics, or Ghostty matching rules unless a test proves a UI dependency requires it.
- Preserve aggregate status precedence exactly: `error > waitingInput > permission > complete > running > idle`.
- Keep the top menu bar icon provider separate from the expanded row icon provider.
- Do not put derivation logic in SwiftUI `View` bodies.
- Do not keep `NSMenu` and `NSPopover` active for the same status item at the same time.
- Every new Swift file must be covered by `project.yml` and validated with `xcodegen generate`.
- Keep TDD discipline: write failing tests first, run them red, then implement minimally.

## File Structure

### Existing files to modify

- `vigil/Vigil/App/MenuBarController.swift`: remove `NSMenu`-centric behavior, install popover host, update menu bar image source.
- `vigil/Vigil/App/AppDelegate.swift`: keep bootstrap intact while wiring the new popover-capable controller.
- `vigil/Vigil/State/AppState.swift`: expose UI-ready state and action hooks needed by the popover without moving business logic into views.
- `vigil/Vigil/State/AppState.swift`: expose raw coordination hooks only; presentation derivation must stay out of `AppState`.
- `vigil/Vigil/UI/SessionMenuBuilder.swift`: either evolve into a toolkit-agnostic presentation builder or delegate to one.
- `vigil/Vigil/UI/SessionMenuRowViewModel.swift`: expand row data needed by custom cards.
- `vigil/Vigil/UI/PixelArtMenuIconProvider.swift`: keep as expanded-row icon provider only.
- `vigil/VigilTests/UI/SessionMenuBuilderTests.swift`: extend for popover presentation expectations.
- `vigil/project.yml`: include any newly created Swift files if necessary.

### New files to create

- `vigil/Vigil/App/StatusItemPopoverController.swift`: owns `NSPopover`, hosts SwiftUI root content, and implements explicit open/close behavior.
- `vigil/Vigil/UI/MenuBarTopIconProvider.swift`: simplified top-icon family for 14-18 px menu bar rendering.
- `vigil/Vigil/UI/PopoverPresentation.swift`: toolkit-agnostic popover presentation models and section definitions.
- `vigil/Vigil/UI/PopoverPresentationBuilder.swift`: builds popover content from `AppState` inputs while preserving status precedence.
- `vigil/Vigil/UI/PopoverPresentationBuilder.swift`: builds popover content from session/diagnostic inputs while preserving status precedence and owning all display derivation.
- `vigil/Vigil/UI/PopoverRootView.swift`: SwiftUI root for the custom popover surface.
- `vigil/Vigil/UI/SessionCardView.swift`: custom session row card.
- `vigil/Vigil/UI/DiagnosticsSectionView.swift`: styled diagnostics block.
- `vigil/Vigil/UI/UtilityActionsView.swift`: refresh/accessibility/quit section.
- `vigil/VigilTests/UI/MenuBarTopIconProviderTests.swift`: verifies simplified top icon provider coverage.
- `vigil/VigilTests/UI/PopoverPresentationBuilderTests.swift`: verifies section order, summary precedence, and action-related view model data.

## Build And Test Commands

Use these commands exactly:

```bash
cd vigil && xcodegen generate
cd vigil && xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS'
cd vigil && make test
```

## Task Breakdown

### Task 1: Add Menu Bar Top Icon Provider

**Files:**
- Create: `vigil/Vigil/UI/MenuBarTopIconProvider.swift`
- Create: `vigil/VigilTests/UI/MenuBarTopIconProviderTests.swift`
- Modify: `vigil/project.yml`

- [ ] **Step 1: Write the failing top-icon tests**

Test cases:

- provider returns a non-template image for each top icon state
- each image is sized for menu bar usage
- `waitingInput` and `permission` can intentionally map to distinct or shared simplified glyphs, but the mapping must be explicit in the provider

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```bash
cd vigil && xcodegen generate && xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/MenuBarTopIconProviderTests
```

Expected: FAIL because the provider and tests target do not exist yet.

- [ ] **Step 3: Implement the minimal simplified provider**

Requirements:

- expose one method like `image(for: MenuBarIconState) -> NSImage?`
- use a simplified icon family separate from row icons
- optimize for 16x16 rendering

- [ ] **Step 4: Run the focused tests again**

Run the same command.
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Vigil/UI/MenuBarTopIconProvider.swift VigilTests/UI/MenuBarTopIconProviderTests.swift project.yml
git commit -m "feat: add vigil top status icon provider"
```

### Task 2: Introduce Toolkit-Agnostic Popover Presentation Models

**Files:**
- Create: `vigil/Vigil/UI/PopoverPresentation.swift`
- Create: `vigil/Vigil/UI/PopoverPresentationBuilder.swift`
- Create: `vigil/VigilTests/UI/PopoverPresentationBuilderTests.swift`
- Modify: `vigil/Vigil/State/AppState.swift`
- Modify: `vigil/Vigil/UI/SessionMenuBuilder.swift`
- Modify: `vigil/Vigil/UI/SessionMenuRowViewModel.swift`

- [ ] **Step 1: Write the failing popover presentation tests**

Test cases:

- section order is `summary`, `needsAttention`, `running`, `recentlyCompleted`, `diagnostics`, `utilityActions`
- summary primary state respects the existing aggregate precedence
- row presentation still includes the correct icon state and actions needed by the popover card

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```bash
cd vigil && xcodegen generate && xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS' -only-testing:VigilTests/PopoverPresentationBuilderTests -only-testing:VigilTests/SessionMenuBuilderTests
```

Expected: FAIL because popover presentation types do not exist yet.

- [ ] **Step 3: Implement presentation models and builder**

Requirements:

- no SwiftUI imports in builder/model files
- keep diagnostics derivation outside the views
- preserve current session precedence rules
- keep `SessionStore` untouched beyond read-only access
- summary must contain: primary state label, tracked session count, attention-required count
- each session card model must contain: title, project name, relative age, right-side status badge/label, primary action identity, bind action identity
- diagnostics model must contain: transport listener status, bridge file status, accessibility permission state, last event age, last jump error when present

- [ ] **Step 4: Update `AppState` to expose the new presentation**

Requirements:

- `AppState` must remain action coordinator, not a view model dumping ground
- `AppState` may expose raw session snapshots, diagnostics facts, and callbacks, but must not derive section ordering, summary labels, row card models, or diagnostics strings

- [ ] **Step 5: Re-run focused tests**

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Vigil/UI/PopoverPresentation.swift Vigil/UI/PopoverPresentationBuilder.swift VigilTests/UI/PopoverPresentationBuilderTests.swift Vigil/State/AppState.swift Vigil/UI/SessionMenuBuilder.swift Vigil/UI/SessionMenuRowViewModel.swift
git commit -m "feat: add vigil popover presentation models"
```

### Task 3: Add AppKit Popover Host

**Files:**
- Create: `vigil/Vigil/App/StatusItemPopoverController.swift`
- Modify: `vigil/Vigil/App/MenuBarController.swift`
- Modify: `vigil/Vigil/App/AppDelegate.swift`

- [ ] **Step 1: Write a failing popover behavior test for any extracted toggle/dismiss helper**

At minimum, extract and test one pure helper that covers open/close toggle intent and dismissal policy inputs. Do not skip automated validation entirely.

- [ ] **Step 2: Implement the popover host**

Requirements:

- status item click toggles open/closed
- clicking outside dismisses popover
- no regular app window opens
- host SwiftUI root view inside the popover

- [ ] **Step 3: Migrate `MenuBarController` away from `NSMenu`**

Requirements:

- use `MenuBarTopIconProvider` for the top icon
- stop assigning `statusItem.menu`
- route button action into the popover host

- [ ] **Step 4: Run full test suite**

Run:

```bash
cd vigil && make test
```

Expected: PASS.

- [ ] **Step 5: Manual verification**

Run the app in Xcode and confirm:

- clicking the status item opens the popover
- clicking again closes it
- clicking outside dismisses it
- opening the popover does not create a regular window

- [ ] **Step 6: Commit**

```bash
git add Vigil/App/StatusItemPopoverController.swift Vigil/App/MenuBarController.swift Vigil/App/AppDelegate.swift
git commit -m "feat: add vigil status item popover host"
```

### Task 4: Build SwiftUI Popover Content

**Files:**
- Create: `vigil/Vigil/UI/PopoverRootView.swift`
- Create: `vigil/Vigil/UI/SessionCardView.swift`
- Create: `vigil/Vigil/UI/DiagnosticsSectionView.swift`
- Create: `vigil/Vigil/UI/UtilityActionsView.swift`
- Modify: `vigil/Vigil/App/StatusItemPopoverController.swift`

- [ ] **Step 1: Implement SwiftUI sections from presentation models**

Requirements:

- summary header at top
- grouped sections below
- session cards use full pixel-art row icons
- diagnostics block remains visually secondary
- summary header shows: primary state label, tracked session count, attention-required count
- each session card shows: title, project name, relative age, right-side status badge/label
- diagnostics section shows: listener status, bridge status, accessibility status, last event age, and last jump error when present

- [ ] **Step 2: Implement session card interactions**

Requirements:

- primary tap calls jump action
- bind action remains separate and explicit
- no additional row secondary actions added

- [ ] **Step 3: Hook the SwiftUI root view into the popover host**

Use the existing `AppState` callbacks rather than direct service calls.

- [ ] **Step 4: Run full test suite**

Expected: PASS.

- [ ] **Step 5: Manual verification**

Run the app and confirm:

- rows render with pixel-art icons
- diagnostics render in the popover
- refresh/accessibility/quit actions are visible
- clicking a session card still triggers the existing behavior path

- [ ] **Step 6: Commit**

```bash
git add Vigil/UI/PopoverRootView.swift Vigil/UI/SessionCardView.swift Vigil/UI/DiagnosticsSectionView.swift Vigil/UI/UtilityActionsView.swift Vigil/App/StatusItemPopoverController.swift
git commit -m "feat: add vigil popover session surface"
```

### Task 5: Tighten Dismissal and Action Semantics

**Files:**
- Modify: `vigil/Vigil/App/StatusItemPopoverController.swift`
- Modify: `vigil/Vigil/App/MenuBarController.swift`
- Modify: `vigil/Vigil/State/AppState.swift`

- [ ] **Step 1: Add the explicit semantics from the spec**

Requirements:

- successful jump dismisses popover
- bind/refresh/accessibility keep the popover open
- failed jump keeps popover open and leaves diagnostics visible
- outside click dismisses popover
- Ghostty focus shift after successful jump is treated as expected, not as an error path

- [ ] **Step 2: Run full test suite**

Expected: PASS.

- [ ] **Step 3: Manual verification**

Confirm the three action paths behave differently in the intended way.

- [ ] **Step 4: Commit**

```bash
git add Vigil/App/StatusItemPopoverController.swift Vigil/App/MenuBarController.swift Vigil/State/AppState.swift
git commit -m "feat: refine vigil popover action behavior"
```

### Task 6: Final Verification And Documentation Touch-Up

**Files:**
- Modify: `vigil/README.md`
- Modify: `vigil/docs/distribution.md`

- [ ] **Step 1: Update docs for the new popover UI**

Document:

- top icon now uses simplified pixel-art status icons
- expanded UI is now a popover, not an `NSMenu`
- preview expectations when running from Xcode

- [ ] **Step 2: Run full verification**

```bash
cd vigil && xcodegen generate
cd vigil && make test
```

Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add README.md docs/distribution.md
git commit -m "docs: update vigil ui usage notes"
```

### Task 7: Add Light Top-Bar Animation

**Files:**
- Modify: `vigil/Vigil/UI/MenuBarTopIconProvider.swift`
- Modify: `vigil/Vigil/App/MenuBarController.swift`

- [ ] **Step 1: Define the minimal animation policy in code**

Requirements:

- `running`: subtle low-frame loop
- `waitingInput` and `permission`: slightly stronger but still lightweight loop
- `complete` and `error`: brief playback, then settle to static
- `idle`: static

- [ ] **Step 2: Add a tiny timer-driven frame switcher in the menu bar controller**

Do not introduce animation into the popover in this phase.

- [ ] **Step 3: Run full verification**

```bash
cd vigil && make test
```

Expected: PASS.

- [ ] **Step 4: Manual verification**

Run the app and confirm the top icon animates lightly for active states without becoming distracting.

- [ ] **Step 5: Commit**

```bash
git add Vigil/UI/MenuBarTopIconProvider.swift Vigil/App/MenuBarController.swift
git commit -m "feat: add vigil top icon motion"
```

## Final Verification Checklist

Before claiming work complete:

- [ ] `cd vigil && xcodegen generate`
- [ ] `cd vigil && make test`
- [ ] manual run of app from Xcode
- [ ] manual check that top icon changes by seeded mock state
- [ ] manual check that top icon motion matches the lightweight policy
- [ ] manual check that popover opens, closes, and dismisses correctly
- [ ] manual check that session rows render pixel-art icons
- [ ] manual check that jump dismisses popover only on success path

## Reviewer Checklist

The reviewer should explicitly verify:

- top icon uses the simplified icon provider, not row art
- popover content uses presentation models rather than direct service state
- status precedence is unchanged
- no extra row-level secondary actions were introduced
- `NSMenu` is no longer the primary expanded surface
- diagnostics remain present but visually secondary
