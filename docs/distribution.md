# Vigil Distribution Notes

## Current Release Path

Vigil is currently distributed as an unsigned `Vigil.dmg` asset attached to a GitHub Release.

The release flow is:

1. Create and push the release tag first.
2. Ensure the tag version matches `MARKETING_VERSION` in `project.yml`, allowing the common `v0.1.0` tag form to map to app version `0.1.0`.
3. Trigger the `release-dmg.yml` GitHub Actions workflow manually with that existing release tag.
4. The workflow checks out the tagged commit directly and fails clearly if the requested tag does not exist in git.
5. Run `scripts/build-dmg.sh <release-tag>` on the pinned macOS runner.
6. Validate that the built DMG mounts correctly and contains `Vigil.app` plus the `Applications` shortcut.
7. Upload `Vigil.dmg` to the targeted GitHub Release.

The DMG contains the macOS app and an `Applications` shortcut for drag-and-drop installation. It does not bundle the OpenCode plugin.

The workflow does not create a new tag from the workflow commit. Manual publishing only works for tags that already exist in the repository, and it checks that the requested release tag matches the app `MARKETING_VERSION` from `project.yml` before publishing.

## What Users Should Expect

Because the app is unsigned, macOS Gatekeeper may block the first launch.

Expected user flow:

1. Download `Vigil.dmg` from GitHub Releases.
2. Open the DMG and drag `Vigil.app` into `Applications`.
3. Launch the copied app from `Applications` rather than running it directly from the mounted DMG.
4. If Gatekeeper blocks it, right-click `Vigil.app`, choose `Open`, then confirm the launch.
5. Grant Accessibility permission when prompted so Vigil can perform its window-management integration.

App-only success looks like a running menu bar icon and a working app popover. Plugin-ready success is a later step: after the separate local OpenCode plugin setup, users should expect a bridge file at `~/.config/vigil/bridge.json` and session updates flowing into the app.

## Unsigned Distribution Notes

Unsigned GitHub Releases are the smallest workable distribution path for the current phase, but they come with tradeoffs:

1. first launch may require the manual right-click `Open` path
2. users should expect stronger macOS warnings than they would for a signed and notarized build
3. some teams may not allow running unsigned apps at all

This is acceptable for early adopters and local evaluation, but it is not the final long-term distribution model.

## Future Signing And Notarization

The next release-quality upgrade path is:

1. sign the app with an Apple Developer ID certificate
2. submit the build to Apple notarization with `notarytool`
3. staple the notarization ticket to the shipped artifact
4. keep publishing the notarized DMG through GitHub Releases

That future path should reduce Gatekeeper friction and make the install flow feel like a normal macOS app download.

## Future Homebrew Cask

Once signed GitHub Releases are stable, Vigil can later add a Homebrew Cask on top of the same release artifact.

## Plugin Packaging

The OpenCode plugin remains a separate install path for now. Users must still configure OpenCode to load the local plugin source from this repository. Later it can move to a published npm package or another simpler install flow once the plugin interface is stable.
