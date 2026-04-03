# Vigil Popover Outside-Click Close Design

## Goal

Make the menu bar popover close immediately when the user clicks outside it after opening it.

## Current Behavior

`StatusItemPopoverController` relies on `NSPopover.behavior = .transient`. In the current menu bar setup, the first outside click after opening does not reliably dismiss the popover. The user must first interact with the popover, then click elsewhere to close it.

## Chosen Approach

Keep the existing `NSPopover` implementation and add explicit outside-click monitoring while the popover is open.

When the popover opens, the controller will install both a local and a global mouse-down monitor. The local monitor handles clicks still delivered inside the app process. The global monitor handles clicks delivered to other apps or the desktop. If the click target is outside both the popover window and the status item button window, the controller will close the popover immediately. When the popover closes, both monitors will be removed.

## Why This Approach

- Smallest behavior change in the existing architecture
- Avoids replacing the popover with a heavier custom panel
- Makes outside-click dismissal explicit instead of depending on menu-bar-specific `NSPopover` behavior

## Scope

- Modify `Vigil/App/StatusItemPopoverController.swift`
- Add regression coverage in `VigilTests/App/StatusItemPopoverControllerTests.swift`

## Non-Goals

- Reworking menu bar presentation
- Replacing `NSPopover` with `NSPanel`
- Changing action-driven close rules inside the popover

## Testing

- Add a focused test seam for monitor installation and removal so the controller lifecycle can be verified deterministically in XCTest
- Add tests for the outside-click close decision points
- Run the targeted app test file
