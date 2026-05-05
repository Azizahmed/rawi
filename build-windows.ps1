# Rawi - Windows Build Script
# Usage: .\build-windows.ps1 [-Setup] [-Build] [-Dev] [-Sidecar]
#
# -Setup   : Install system dependencies (Rust, Node.js, Visual Studio Build Tools)
# -Build   : Build the production .msi/.exe installer
# -Dev     : Run in development mode
# -Sidecar : Verify whisper.cpp sidecar binary is present

param(
    [switch]$Setup,
    [switch]$Build,
    [switch]$Dev,
    [switch]$Sidecar
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SidecarDir = Join-Path $ScriptDir "src-tauri\binaries"
$SidecarBinary = Join-Path $SidecarDir "whisper-cpp-x86_64-pc-windows-msvc.exe"

function Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function ErrorExit($msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red; exit 1 }

# --- Setup ---
if ($Setup) {
    Info "Installing system dependencies for Rawi on Windows..."

    # Check Visual Studio Build Tools
    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vsWhere) -or -not (& $vsWhere -latest -property installationPath 2>$null)) {
        Warn "Visual Studio Build Tools not found."
        Warn "Install from: https://visualstudio.microsoft.com/visual-cpp-build-tools/"
        Warn "Select: 'Desktop development with C++' workload"
    } else {
        Info "Visual Studio Build Tools found."
    }

    # Rust
    if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
        Warn "Rust not found. Install from: https://rustup.rs/"
    } else {
        Info "Rust found: $(cargo --version)"
    }

    # Node.js
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Warn "Node.js not found. Install from: https://nodejs.org/"
    } else {
        Info "Node.js found: $(node --version)"
    }

    Info "Setup check complete."
}

# --- Sidecar ---
if ($Sidecar) {
    if (Test-Path $SidecarBinary) {
        Info "Sidecar binary found: $SidecarBinary"
    } else {
        Warn "Sidecar binary not found at: $SidecarBinary"
        Warn "The Windows whisper.cpp binary should already be in src-tauri\binaries\"
        Warn "If missing, download from: https://github.com/ggerganov/whisper.cpp/releases"
    }
}

# --- Build ---
if ($Build) {
    if (-not (Test-Path $SidecarBinary)) {
        ErrorExit "Sidecar binary not found. Place whisper-cpp-x86_64-pc-windows-msvc.exe in src-tauri\binaries\"
    }

    Info "Installing npm dependencies..."
    npm install

    Info "Building Rawi for Windows..."
    npm run tauri build

    Info "Build complete! Check src-tauri\target\release\bundle\ for .msi and .exe"
}

# --- Dev ---
if ($Dev) {
    if (-not (Test-Path $SidecarBinary)) {
        Warn "Sidecar binary not found. Some features may not work."
    }

    Info "Starting Rawi in development mode..."
    npm install
    npm run tauri dev
}

# --- No flags ---
if (-not ($Setup -or $Build -or $Dev -or $Sidecar)) {
    Write-Host "Rawi Windows Build Script"
    Write-Host ""
    Write-Host "Usage: .\build-windows.ps1 [-Setup] [-Build] [-Dev] [-Sidecar]"
    Write-Host ""
    Write-Host "  -Setup   Check/install system dependencies"
    Write-Host "  -Sidecar Verify whisper.cpp sidecar binary"
    Write-Host "  -Build   Build production .msi/.exe installer"
    Write-Host "  -Dev     Run in development mode with hot-reload"
}
