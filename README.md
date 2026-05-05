# Rawi (راوي)

Rawi is a cross-platform desktop dictation app built with Tauri, Rust, TypeScript, and Vite. It records from your microphone, transcribes speech with either local Whisper or Groq Cloud, and pastes the result into the active application. Runs on **Windows** and **Linux (Ubuntu)**.

## Features

- Global push-to-talk dictation from the system tray.
- Local Whisper transcription through the bundled `whisper.cpp` sidecar.
- Groq Cloud transcription with a locally stored API key and model id.
- Mixed Arabic and English speech mode for same-sentence dictation without translation.
- Configurable global hotkey with presets for `Ctrl + Space`, `Ctrl + Alt + Space`, and `Ctrl + Shift + Space`.
- Launch-at-startup support (Windows Registry / Linux XDG autostart), enabled by default and controlled from Settings.
- Microphone, paste delay, audio device, and transcription engine settings.
- Linux support: X11 and Wayland clipboard, enigo + xdotool paste fallback.

## Requirements

### Windows

- Windows 10 or later.
- Node.js and npm.
- Rust and Cargo.
- Tauri v2 prerequisites.
- A microphone.
- A Groq API key if you use Groq Cloud transcription.

### Linux (Ubuntu / Debian)

- Ubuntu 20.04 or later (or any Debian-based distro).
- Node.js and npm.
- Rust and Cargo.
- System libraries (installed automatically by `build-linux.sh --setup`):
  - `libwebkit2gtk-4.1-dev`, `libgtk-3-dev`, `libayatana-appindicator3-dev`, `librsvg2-dev`
  - `libasound2-dev` (ALSA audio)
  - `libxdo-dev`, `libxtst-dev`, `libx11-dev` (X11 input)
  - `libwayland-dev`, `wayland-protocols` (Wayland clipboard)
  - `xdotool` (paste fallback)
  - `cmake`, `build-essential` (for building whisper.cpp)
- A microphone.
- A Groq API key if you use Groq Cloud transcription.

## Development

### Windows

Install dependencies:

```powershell
npm install
```

Run the Tauri app in development:

```powershell
npm run tauri dev
```

Build the desktop app:

```powershell
npm run tauri build
```

Or use the build script:

```powershell
# Check system dependencies
.\build-windows.ps1 -Setup

# Verify whisper.cpp sidecar
.\build-windows.ps1 -Sidecar

# Build production installer
.\build-windows.ps1 -Build

# Run in dev mode
.\build-windows.ps1 -Dev
```

### Linux (Ubuntu)

Use the build script for a guided setup:

```bash
chmod +x build-linux.sh

# Step 1: Install system dependencies
./build-linux.sh --setup

# Step 2: Build whisper.cpp sidecar binary
./build-linux.sh --sidecar

# Step 3a: Run in development mode
./build-linux.sh --dev

# Step 3b: OR build production AppImage/deb
./build-linux.sh --build
```

Alternatively, do it manually:

```bash
# Install system deps (Ubuntu)
sudo apt-get install -y libwebkit2gtk-4.1-dev build-essential curl wget file \
  libssl-dev libgtk-3-dev libayatana-appindicator3-dev librsvg2-dev \
  libasound2-dev pkg-config libxdo-dev libxtst-dev libx11-dev \
  libwayland-dev wayland-protocols xdotool cmake

# Install npm dependencies
npm install

# Run in dev mode
npm run tauri dev

# Build production package
npm run tauri build
```

The built `.deb` and `.AppImage` packages will be in `src-tauri/target/release/bundle/`.

## Settings

Rawi stores settings locally on the machine. The settings screen includes:

- General: microphone selection, launch-at-startup toggle, and paste delay.
- Engine: Local Whisper or Groq Cloud, speech language mode, Groq API key, Groq model id, and connection testing.
- Recording: hotkey presets, custom hotkey capture, and recording behavior.
- About: app information.

The default hotkey is `Ctrl + Space`. Modifier-only shortcuts such as only `Ctrl`, `Ctrl + Alt`, or `Ctrl + Shift` are not valid global shortcuts, so Rawi uses those modifier combinations with `Space`.

## Startup Behavior

Launch at startup is enabled by default:
- **Windows**: Uses the Windows Registry to start Rawi on login.
- **Linux**: Uses XDG autostart (places a `.desktop` file in `~/.config/autostart/`).

When the OS starts Rawi automatically, the app opens in the background and is available from the tray. You can turn this off in Settings under General.

## Project Structure

- `src/` contains the TypeScript UI logic.
- `src/style.css` contains the app styling.
- `index.html` contains the settings and app shell markup.
- `src-tauri/` contains the Rust backend, Tauri configuration, tray integration, recording pipeline, transcription logic, settings, and installer configuration.
- `src-tauri/binaries/` contains sidecar binaries used by the app.

## Verification

Useful local checks before shipping changes:

```bash
npm run build
cd src-tauri
cargo test
```
