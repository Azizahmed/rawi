use std::time::Duration;

const CLIPBOARD_SET_DELAY: Duration = Duration::from_millis(50);
const CLIPBOARD_RESTORE_DELAY: Duration = Duration::from_millis(100);

trait ClipboardText {
    fn get_text(&mut self) -> Result<String, String>;
    fn set_text(&mut self, text: &str) -> Result<(), String>;
}

impl ClipboardText for arboard::Clipboard {
    fn get_text(&mut self) -> Result<String, String> {
        arboard::Clipboard::get_text(self).map_err(|e| e.to_string())
    }

    fn set_text(&mut self, text: &str) -> Result<(), String> {
        arboard::Clipboard::set_text(self, text).map_err(|e| e.to_string())
    }
}

pub fn paste_text(text: &str) -> Result<(), String> {
    let mut clipboard = arboard::Clipboard::new().map_err(|e| e.to_string())?;
    paste_text_with_clipboard(
        &mut clipboard,
        text,
        simulate_paste_shortcut,
        std::thread::sleep,
    )
}

fn paste_text_with_clipboard<C, P, S>(
    clipboard: &mut C,
    text: &str,
    mut paste_shortcut: P,
    mut sleep: S,
) -> Result<(), String>
where
    C: ClipboardText,
    P: FnMut() -> Result<(), String>,
    S: FnMut(Duration),
{
    let previous_text = clipboard.get_text().ok();

    clipboard.set_text(text)?;
    sleep(CLIPBOARD_SET_DELAY);

    paste_shortcut().map_err(|error| {
        format!(
            "{} The transcription was copied to your clipboard, so you can paste it manually.",
            error
        )
    })?;

    sleep(CLIPBOARD_RESTORE_DELAY);

    if let Some(previous_text) = previous_text {
        clipboard
            .set_text(&previous_text)
            .map_err(|error| format!("Failed to restore previous clipboard text: {}", error))?;
    }

    Ok(())
}

fn simulate_paste_shortcut() -> Result<(), String> {
    // Simulate Cmd+V via osascript (works from any thread, unlike enigo which
    // calls TSMGetInputSourceProperty requiring the main thread)
    #[cfg(target_os = "macos")]
    {
        std::process::Command::new("osascript")
            .args([
                "-e",
                r#"tell application "System Events" to keystroke "v" using command down"#,
            ])
            .output()
            .map_err(|e| format!("Failed to simulate paste: {}", e))?;
    }

    #[cfg(target_os = "windows")]
    {
        use enigo::{Enigo, Settings};
        let mut enigo = Enigo::new(&Settings::default()).map_err(|e| e.to_string())?;
        send_windows_paste_shortcut(&mut enigo).map_err(|e| e.to_string())?;
    }

    Ok(())
}

#[cfg(target_os = "windows")]
fn send_windows_paste_shortcut<K>(keyboard: &mut K) -> enigo::InputResult<()>
where
    K: enigo::Keyboard,
{
    use enigo::{Direction, Key};

    keyboard.key(Key::Control, Direction::Press)?;
    keyboard.key(Key::V, Direction::Click)?;
    keyboard.key(Key::Control, Direction::Release)?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    struct FakeClipboard {
        text: Result<String, String>,
        writes: Vec<String>,
    }

    impl FakeClipboard {
        fn with_text(text: &str) -> Self {
            Self {
                text: Ok(text.to_string()),
                writes: Vec::new(),
            }
        }
    }

    impl ClipboardText for FakeClipboard {
        fn get_text(&mut self) -> Result<String, String> {
            self.text.clone()
        }

        fn set_text(&mut self, text: &str) -> Result<(), String> {
            self.writes.push(text.to_string());
            self.text = Ok(text.to_string());
            Ok(())
        }
    }

    #[test]
    fn restores_previous_text_after_paste() {
        let mut clipboard = FakeClipboard::with_text("previous copy");
        let mut pasted = false;

        paste_text_with_clipboard(
            &mut clipboard,
            "rawi transcription",
            || {
                pasted = true;
                Ok(())
            },
            |_| {},
        )
        .unwrap();

        assert!(pasted);
        assert_eq!(
            clipboard.writes,
            vec!["rawi transcription".to_string(), "previous copy".to_string()]
        );
        assert_eq!(clipboard.text.unwrap(), "previous copy");
    }

    #[cfg(target_os = "windows")]
    #[test]
    fn windows_paste_shortcut_uses_virtual_v_key() {
        use enigo::{Direction, InputResult, Key, Keyboard};

        struct FakeKeyboard {
            events: Vec<(Key, Direction)>,
        }

        impl Keyboard for FakeKeyboard {
            fn fast_text(&mut self, _text: &str) -> InputResult<Option<()>> {
                Ok(None)
            }

            fn key(&mut self, key: Key, direction: Direction) -> InputResult<()> {
                self.events.push((key, direction));
                Ok(())
            }

            fn raw(&mut self, _keycode: u16, _direction: Direction) -> InputResult<()> {
                Ok(())
            }
        }

        let mut keyboard = FakeKeyboard { events: Vec::new() };

        send_windows_paste_shortcut(&mut keyboard).unwrap();

        assert_eq!(
            keyboard.events,
            vec![
                (Key::Control, Direction::Press),
                (Key::V, Direction::Click),
                (Key::Control, Direction::Release),
            ]
        );
    }
}
