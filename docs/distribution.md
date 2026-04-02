# Vigil Distribution Notes

## Local Unsigned Install

The first release path is a local unsigned macOS app build.

Suggested workflow:

1. Run `make build`
2. Locate the built app in Xcode DerivedData or archive it manually
3. Launch the app locally
4. Grant Accessibility permission when prompted
5. Confirm the bridge file is written to `~/.config/vigil/bridge.json`

## Future GitHub Releases

The intended next distribution step is GitHub Releases with a zipped `.app` or `.dmg` artifact.

Recommended sequence:

1. build release app
2. sign with Developer ID
3. notarize with Apple
4. upload artifact to GitHub Releases

## Future Notarization

Notarization is not required for local development, but it is strongly recommended before sharing builds broadly.

The expected future path is:

1. Developer ID signing
2. `notarytool` submission
3. staple ticket to archive or app bundle

## Future Homebrew Cask

Once GitHub Releases are stable, `Vigil` should ship through a Homebrew Cask rather than a formula because it is a GUI macOS app.

Likely structure:

1. GitHub Release artifact
2. separate Homebrew tap
3. `brew install --cask vigil`

## Plugin Packaging

The OpenCode plugin can initially be installed from local source. Later it can move to a published npm package once the API surface is stable.
