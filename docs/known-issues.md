# Known Issues

## Ghostty session jump can target the wrong window

- Status: TODO
- Area: Ghostty window activation and manual binding

### Reported Behavior

- Double-clicking or opening a session from the Vigil session panel does not reliably jump to the real Ghostty window or tab for that session.
- If another app is currently focused, Vigil may activate the last Ghostty window that lost focus instead of the Ghostty window or tab that actually belongs to the selected session.
- Manual `Bind Frontmost` does not reliably repair this when the intended Ghostty window is no longer considered the focused Ghostty window at bind time.

### Expected Behavior

- Opening a session from the panel should activate the Ghostty window or tab that actually belongs to the selected session.
- The result should not depend on whether Ghostty is currently frontmost.
- Manual binding should persist a reliable session-to-window or session-to-tab association that can be reused later even after focus changes.

### Reproduction Summary

1. Open multiple Ghostty windows or tabs.
2. Associate work with a specific OpenCode session.
3. Focus another macOS app.
4. From Vigil, double-click the session card or trigger the session open action.
5. Observe that Vigil may activate the wrong Ghostty window, often the last Ghostty window that lost focus.

### Notes

- The current implementation relies heavily on the currently focused Ghostty window during bind and on fuzzy matching during activation.
- This likely needs a more reliable persisted identity and an activation path that does not depend on Ghostty still being focused when the user clicks inside the menu bar popover.
