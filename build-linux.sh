#!/usr/bin/env bash
#
# Rawi - Linux (Ubuntu) Build Script
# Usage: ./build-linux.sh [--setup | --build | --dev | --sidecar]
#
# --setup   : Install all system dependencies needed to build Rawi on Ubuntu
# --build   : Build the production AppImage/deb package
# --dev     : Run in development mode
# --sidecar : Download and set up the whisper.cpp Linux sidecar binary
set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIDECAR_DIR="$SCRIPT_DIR/src-tauri/binaries"
SIDECAR_BINARY="$SIDECAR_DIR/whisper-cpp-x86_64-unknown-linux-gnu"

# ─── System Dependencies ──────────────────────────────────────────────────────
setup() {
    info "Installing system dependencies for Rawi on Ubuntu..."

    sudo apt-get update

    # Tauri v2 prerequisites
    sudo apt-get install -y \
        libwebkit2gtk-4.1-dev \
        build-essential \
        curl \
        wget \
        file \
        libssl-dev \
        libgtk-3-dev \
        libayatana-appindicator3-dev \
        librsvg2-dev

    # Audio (cpal / ALSA)
    sudo apt-get install -y \
        libasound2-dev \
        pkg-config

    # X11 input simulation (enigo)
    sudo apt-get install -y \
        libxdo-dev \
        libxtst-dev \
        libx11-dev

    # Wayland clipboard support (arboard wayland-data-control)
    sudo apt-get install -y \
        libwayland-dev \
        wayland-protocols

    # Optional: xdotool for paste fallback
    sudo apt-get install -y xdotool

    # Node.js (if not present)
    if ! command -v node &>/dev/null; then
        warn "Node.js not found. Installing via NodeSource..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    # Rust (if not present)
    if ! command -v cargo &>/dev/null; then
        warn "Rust not found. Installing via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    info "System dependencies installed."
}

# ─── Whisper.cpp Sidecar ──────────────────────────────────────────────────────
download_sidecar() {
    if [ -f "$SIDECAR_BINARY" ]; then
        info "Sidecar binary already exists at $SIDECAR_BINARY"
        read -rp "Re-download? [y/N] " choice
        [[ "$choice" =~ ^[Yy]$ ]] || return 0
    fi

    info "Building whisper.cpp from source for Linux..."

    local WHISPER_VERSION="v1.7.5"
    local BUILD_DIR="/tmp/whisper-cpp-build"

    rm -rf "$BUILD_DIR"
    git clone --depth 1 --branch "$WHISPER_VERSION" https://github.com/ggerganov/whisper.cpp.git "$BUILD_DIR"

    pushd "$BUILD_DIR" >/dev/null

    # Build the CLI binary (CPU-only, no CUDA/ROCm)
    cmake -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DWHISPER_CUDA=OFF \
        -DWHISPER_OPENBLAS=OFF \
        -DBUILD_SHARED_LIBS=OFF
    cmake --build build --config Release -j"$(nproc)"

    popd >/dev/null

    mkdir -p "$SIDECAR_DIR"
    cp "$BUILD_DIR/build/bin/whisper-cli" "$SIDECAR_BINARY"
    chmod +x "$SIDECAR_BINARY"

    # Clean up
    rm -rf "$BUILD_DIR"

    info "Sidecar binary saved to $SIDECAR_BINARY"
}

# ─── Build ─────────────────────────────────────────────────────────────────────
build() {
    [ -f "$SIDECAR_BINARY" ] || {
        error "Sidecar binary not found. Run './build-linux.sh --sidecar' first."
    }

    info "Installing npm dependencies..."
    npm install

    info "Building Rawi for Linux..."
    npm run tauri build

    info "Build complete! Check src-tauri/target/release/bundle/ for .deb and .AppImage"
}

# ─── Dev Mode ──────────────────────────────────────────────────────────────────
dev() {
    [ -f "$SIDECAR_BINARY" ] || {
        warn "Sidecar binary not found. Run './build-linux.sh --sidecar' first."
    }

    info "Starting Rawi in development mode..."
    npm install
    npm run tauri dev
}

# ─── Main ──────────────────────────────────────────────────────────────────────
case "${1:-}" in
    --setup)   setup ;;
    --sidecar) download_sidecar ;;
    --build)   build ;;
    --dev)     dev ;;
    *)
        echo "Rawi Linux Build Script"
        echo ""
        echo "Usage: $0 {--setup|--sidecar|--build|--dev}"
        echo ""
        echo "  --setup   Install system dependencies (Ubuntu/Debian)"
        echo "  --sidecar Build whisper.cpp sidecar binary for Linux"
        echo "  --build   Build production AppImage/deb package"
        echo "  --dev     Run in development mode with hot-reload"
        exit 1
        ;;
esac
