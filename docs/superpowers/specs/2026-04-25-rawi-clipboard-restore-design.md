# Rawi Clipboard Restore Design

## Goal

When Rawi auto-pastes a transcription, it should preserve the user's previous copied text. After Rawi finishes pasting, pressing Ctrl+V should paste the text that was copied before Rawi ran.

## Design

`paste_text` will read the current text clipboard before replacing it with the transcription. It will then set the clipboard to the transcription, wait briefly, simulate the paste shortcut, wait again so the focused app can consume the paste, and restore the previous text clipboard if one was available.

This intentionally preserves plain text only. If the clipboard cannot be read as text, Rawi will still paste the transcription using the existing flow. If restoring the previous text fails, `paste_text` will report that failure after the paste attempt.

## Testing

Backend verification should cover the Rust paste module where practical and run the existing Rust test suite or compiler checks.
