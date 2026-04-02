# Vigil UI Upgrade Design

## Summary

Upgrade `Vigil` from a mostly system-native menu bar utility into a more expressive companion app while preserving the existing session, transport, and Ghostty integration layers. The upgrade has two visible parts:

- replace the top menu bar status image with a simplified pixel-art icon set tailored for macOS menu bar constraints
- replace the current `NSMenu` dropdown with a custom `NSPopover` backed by SwiftUI so session rows can use richer visuals, clearer grouping, and better action affordances

This work is intentionally scoped to presentation and interaction. It must not change the event contract, plugin transport, session model, or Ghostty matching rules unless strictly needed to support the new UI.

## Goals

- Give `Vigil` a distinctive visual identity using the approved pixel-art language.
- Preserve good menu bar readability at tiny sizes.
- Make expanded content feel more like a companion dashboard than a raw macOS menu.
- Keep the interaction model fast and lightweight.
- Reuse existing session store and diagnostics data rather than introducing a second state layer.

## Non-Goals

- No changes to plugin protocol or event schema.
- No notch-adjacent floating UI in this iteration.
- No complex settings redesign.
- No large animation system for the first pass.
- No replacement of Ghostty activation or matching logic.

## Current Problems

The current implementation proves the architecture but feels visually flat for three reasons:

- the top icon is still a system symbol rather than part of the product identity
- `NSMenu` imposes strict layout constraints and weak visual hierarchy
- session rows are mostly plain text with limited emphasis on attention states

The current menu is functionally correct but not aligned with the product’s intended personality.

## Design Overview

The upgrade will happen in two layers.

The upgrade must preserve the existing aggregate state precedence used by the current implementation:

`error > waitingInput > permission > complete > running > idle`

This precedence continues to drive:

- the top menu bar icon state
- the summary header primary state label
- the current global attention target

### Layer 1: Menu Bar Status Icon

Use a new simplified pixel-art status icon provider for the menu bar button.

Important constraint:

- the current full-detail pixel icons used inside the expanded UI are too dense for the menu bar at tiny sizes

Therefore the top bar needs its own reduced icon set with:

- fewer internal details
- stronger silhouettes
- limited color regions
- state clarity before expressiveness

The menu bar icon should still support all app states:

- `idle`
- `running`
- `waitingInput`
- `permission`
- `complete`
- `error`

### Layer 2: Expanded Session Surface

Replace the current `NSMenu` with an `NSPopover` containing a SwiftUI view hierarchy.

This gives the app:

- custom row layouts
- richer grouping
- inline action buttons
- expressive use of the existing pixel-art icons
- a better place for diagnostics without abusing menu item text

`NSPopover` is preferred over `NSPanel` for this phase because it preserves the lightweight menu bar interaction model while greatly improving design flexibility.

## UI Structure

The popover should contain these sections in order:

1. Global Summary
2. Needs Attention
3. Running
4. Recently Completed
5. Diagnostics
6. Utility Actions

### 1. Global Summary

Show:

- current primary state label
- tracked session count
- attention-required session count

This should read as a compact companion header rather than a verbose debug block.

### 2. Needs Attention

Contains `error`, `waitingInput`, and `permission` sessions.

Rows in this section should have the strongest contrast and clearest visual weight.

### 3. Running

Contains active sessions that do not currently require user intervention.

This section should feel calmer and less urgent.

### 4. Recently Completed

Contains recent completed sessions still inside the retention window.

This section should feel visually lighter than the attention section.

### 5. Diagnostics

Show small status lines for:

- transport listener status
- bridge file status
- accessibility permission state
- last event age
- last jump error when present

This section should remain available but visually secondary.

### 6. Utility Actions

Keep these actions exposed:

- Refresh Mappings
- Request Accessibility
- Quit

Settings can remain deferred unless needed during implementation.

## Session Row Design

Each row becomes a custom SwiftUI card with:

- left: full pixel-art icon for session state
- middle: session title, project name, relative age
- right: state badge or short label
- secondary action: bind frontmost window

Primary row action:

- clicking the row triggers jump-to-session behavior

Secondary row action:

- bind current frontmost Ghostty window to that session

The row should visually separate primary navigation from secondary maintenance actions.

No other row-level secondary action is allowed in this phase.

## Pixel Art Asset Strategy

There will now be two icon families.

### A. Expanded UI Icons

Use the existing approved pixel-art assets for popover session rows.

These icons can stay colorful and expressive because the popover has enough space.

### B. Menu Bar Icons

Create a separate simplified icon family for the top menu bar button.

These icons should be:

- smaller
- less detailed
- optimized for 14-18 px rendering
- readable in both light and dark appearances

The top icon family should not reuse the full row-art 1:1.

## Animation Policy

Animation is allowed, but only in controlled forms.

### Top Menu Bar

- `running`: subtle loop, low frame count
- `waitingInput` and `permission`: slightly stronger loop or pulse
- `complete` and `error`: short playback, then settle to static
- `idle`: static

### Popover

Popover content may later gain richer animation, but this phase does not require it.

This prevents UI complexity from blocking the container migration.

## Architecture Changes

The UI upgrade should add or modify these responsibilities.

### MenuBarController

Current role:

- builds `NSMenu`

New role:

- owns the `NSStatusItem`
- manages the popover presentation lifecycle
- updates the menu bar image using the simplified pixel icon provider
- routes status button clicks to show or hide the popover

### New Popover Host

Add a lightweight AppKit bridge that presents a SwiftUI root view inside `NSPopover`.

Responsibilities:

- create and retain popover
- host SwiftUI content
- anchor to status bar button
- apply explicit presentation and dismissal rules

Required popover semantics:

- clicking the status item toggles the popover open and closed
- clicking outside the popover dismisses it
- a successful primary jump action dismisses the popover
- bind, refresh, and accessibility actions keep the popover open
- if a Ghostty jump fails, the popover stays open and diagnostics remain visible
- focus shifting to Ghostty after a successful jump is expected and must not be treated as an error state
- the app must remain a menu bar utility and must not open a regular main window during this interaction

### New SwiftUI Session Surface

Add a focused SwiftUI view tree for:

- summary header
- section containers
- session cards
- diagnostics panel
- utility action row

This tree must consume a dedicated presentation model, not raw service objects and not direct session-store internals.

### Presentation Models

Introduce a dedicated popover presentation model that remains UI-facing but toolkit-agnostic.

Required boundary:

- `SessionStore` owns session facts and retention only
- `AppState` coordinates actions and service access only
- presentation builders derive all display models for the menu bar and popover
- SwiftUI views render presentation models and dispatch callbacks only

Avoid putting view logic directly into the session store or SwiftUI view bodies.

## Data Flow

The data path should remain:

- plugin events
- session store
- app state
- presentation builder
- menu bar / popover UI

The upgrade should not create parallel sources of truth.

If additional derived state is needed for row cards or diagnostics, compute it inside presentation-building layers.

## Interaction Model

### Status Button Click

- if popover closed: open it
- if popover open: close it

### Session Card Click

- trigger jump to the matching Ghostty session/window

### Bind Action

- trigger bind frontmost Ghostty window to selected session

### Utility Actions

- refresh mappings
- request accessibility
- quit app

## Testing Strategy

Keep most tests in the presentation layer and icon providers.

Add tests for:

- row presentation includes icon state for every session row
- pixel icon provider returns images for all required states
- popover presentation builder preserves expected section ordering

Do not attempt deep UI automation in this phase.

Manual verification should focus on:

- top icon changes per state
- popover appears and dismisses correctly
- rows show pixel-art icons and metadata
- action buttons still call existing behaviors

## Risks and Mitigations

### Risk: Menu Bar Icon Becomes Hard To Read

Mitigation:

- use a separate simplified top icon family
- keep shapes stronger than details

### Risk: Popover Feels Too Heavy

Mitigation:

- keep size compact
- do not add unnecessary navigation or settings flows

### Risk: UI Upgrade Entangles Business Logic With View Code

Mitigation:

- keep state derivation in builders/view models
- keep `SessionStore` and services unchanged

### Risk: Diagnostics Overpower Primary Session UX

Mitigation:

- place diagnostics lower in the surface
- keep typography and color more subdued there

## Implementation Sequence

1. Add simplified top icon provider
2. Swap menu bar image source from system symbols to top icon provider
3. Add popover host and SwiftUI root view shell
4. Migrate existing presentation data into SwiftUI sections
5. Replace plain menu rows with session cards using pixel-art icons
6. Move diagnostics and utility actions into popover sections
7. Add light state animation only after layout and interaction are stable

## Success Criteria

This upgrade is successful if:

- the top bar icon clearly reflects session state while feeling more branded
- the expanded UI no longer feels like a plain system menu
- session rows visually use the pixel-art language consistently
- the app remains fast and lightweight to open from the menu bar
- no existing transport, store, or Ghostty functionality regresses
