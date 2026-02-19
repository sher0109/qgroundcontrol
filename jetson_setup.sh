#!/bin/bash
#============================================================
# SVP GCS — Setup completo per NVIDIA Jetson (aarch64)
# Da eseguire SUL Jetson via SSH o direttamente
#
# Uso:
#   chmod +x jetson_setup.sh
#   ./jetson_setup.sh
#
# Al termine installa:
#   - Dipendenze di sistema (build tools, Qt deps, GStreamer)
#   - CMake 3.25+
#   - Qt 6.10.2 per aarch64
#   - Variabili d'ambiente in ~/.bashrc
#============================================================

set -e

# ── Colori ───────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
print_ok()      { echo -e "${GREEN}[OK]${NC} $1"; }
print_err()     { echo -e "${RED}[ERRORE]${NC} $1"; }
print_warn()    { echo -e "${YELLOW}[INFO]${NC} $1"; }
print_section() { echo -e "\n${BLUE}══════════════════════════════════════${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}══════════════════════════════════════${NC}"; }

# ── Configurazione ───────────────────────────────────────
QGC_DIR="$HOME/qgroundcontrol"
QT_VERSION="6.10.2"
QT_PATH="/opt/Qt"
QT_ARCH_DIR="gcc_arm64"
QT_ROOT="$QT_PATH/$QT_VERSION/$QT_ARCH_DIR"
QT_MODULES="qtcharts qtlocation qtpositioning qtspeech qt5compat qtmultimedia qtserialport qtimageformats qtshadertools qtconnectivity qtquick3d qtsensors qtscxml qtwebsockets qthttpserver"
CMAKE_MIN="3.25"

# ── Check architettura ───────────────────────────────────
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
    print_err "Questo script è pensato per Jetson (aarch64). Architettura rilevata: $ARCH"
    print_err "Sei sul Jetson? Usa SSH: ssh user@<jetson-ip> 'bash -s' < jetson_setup.sh"
    exit 1
fi

print_section "SVP GCS Setup — Jetson aarch64"
echo "  Qt:      $QT_VERSION"
echo "  CMake:   >= $CMAKE_MIN"
echo "  QT dir:  $QT_ROOT"
echo ""

# ── 1. Aggiorna apt ──────────────────────────────────────
print_section "1/5 — Aggiornamento apt"
sudo apt-get update -y -qq
print_ok "apt aggiornato"

# ── 2. Dipendenze di sistema ─────────────────────────────
print_section "2/5 — Dipendenze di sistema"

PKGS_CORE=(
    software-properties-common gnupg2 ca-certificates
    binutils build-essential ccache file gdb git
    libfuse2 fuse3 libtool locales mold ninja-build
    patchelf pipx pkgconf python3 python3-pip rsync
    unzip wget zsync curl
)

PKGS_QT=(
    libatspi2.0-dev libfontconfig1-dev libfreetype-dev libgtk-3-dev
    libsm-dev libx11-dev libx11-xcb-dev libxcb-cursor-dev
    libxcb-glx0-dev libxcb-icccm4-dev libxcb-image0-dev
    libxcb-keysyms1-dev libxcb-present-dev libxcb-randr0-dev
    libxcb-render-util0-dev libxcb-render0-dev libxcb-shape0-dev
    libxcb-shm0-dev libxcb-sync-dev libxcb-util-dev
    libxcb-xfixes0-dev libxcb-xinerama0-dev libxcb-xkb-dev
    libxcb1-dev libxext-dev libxfixes-dev libxi-dev
    libxkbcommon-dev libxkbcommon-x11-dev libxrender-dev libunwind-dev
)

PKGS_GSTREAMER=(
    libgstreamer1.0-dev libgstreamer-plugins-bad1.0-dev
    libgstreamer-plugins-base1.0-dev libgstreamer-plugins-good1.0-dev
    libgstreamer-gl1.0-0
    gstreamer1.0-plugins-bad gstreamer1.0-plugins-base
    gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly
    gstreamer1.0-gl gstreamer1.0-libav gstreamer1.0-rtsp gstreamer1.0-x
)

print_warn "Installazione pacchetti core..."
sudo apt-get install -y -qq --no-install-recommends "${PKGS_CORE[@]}"

print_warn "Installazione dipendenze Qt..."
sudo apt-get install -y -qq --no-install-recommends "${PKGS_QT[@]}"

print_warn "Installazione GStreamer..."
# Jetson ha i plugin NVIDIA già installati da JetPack; installiamo quelli standard
sudo apt-get install -y -qq --no-install-recommends "${PKGS_GSTREAMER[@]}"

print_ok "Dipendenze di sistema installate"

# ── 3. CMake 3.25+ ───────────────────────────────────────
print_section "3/5 — CMake >= $CMAKE_MIN"

CMAKE_INSTALLED=$(cmake --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+' | head -1 || echo "0.0")
CMAKE_OK=$(python3 -c "
v = '$CMAKE_INSTALLED'.split('.')
m = '$CMAKE_MIN'.split('.')
print('yes' if (int(v[0]), int(v[1])) >= (int(m[0]), int(m[1])) else 'no')
" 2>/dev/null || echo "no")

if [ "$CMAKE_OK" = "yes" ]; then
    print_ok "CMake $CMAKE_INSTALLED già installato"
else
    print_warn "CMake $CMAKE_INSTALLED troppo vecchio, installo via Kitware APT..."

    # Kitware APT repository (ufficiale, supporta aarch64)
    wget -qO - https://apt.kitware.com/keys/kitware-archive-latest.asc \
        | sudo gpg --dearmor -o /usr/share/keyrings/kitware-archive-keyring.gpg

    # Rileva Ubuntu codename (focal=20.04, jammy=22.04, noble=24.04)
    UBUNTU_CODENAME=$(. /etc/os-release && echo "$UBUNTU_CODENAME")
    echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] \
https://apt.kitware.com/ubuntu/ $UBUNTU_CODENAME main" \
        | sudo tee /etc/apt/sources.list.d/kitware.list > /dev/null

    sudo apt-get update -y -qq
    sudo apt-get install -y -qq cmake

    CMAKE_NEW=$(cmake --version | head -1 | grep -oP '\d+\.\d+\.\d+' | head -1)
    print_ok "CMake $CMAKE_NEW installato"
fi

# ── 4. Qt 6 per aarch64 ──────────────────────────────────
print_section "4/5 — Qt $QT_VERSION per aarch64"

if [ -f "$QT_ROOT/bin/qt-cmake" ]; then
    print_ok "Qt $QT_VERSION già installato in $QT_ROOT"
else
    print_warn "Installazione Qt $QT_VERSION (può richiedere alcuni minuti)..."

    # Installa aqtinstall
    sudo pip3 install -q aqtinstall

    # Qt per Linux aarch64
    # host=linux_arm64  arch=linux_gcc_arm64  (confermato dal CI di QGC)
    sudo mkdir -p "$QT_PATH"
    sudo chmod 777 "$QT_PATH"

    python3 -m aqt install-qt linux desktop "$QT_VERSION" linux_gcc_arm64 \
        -O "$QT_PATH" \
        -m $QT_MODULES

    if [ ! -f "$QT_ROOT/bin/qt-cmake" ]; then
        print_err "Installazione Qt fallita!"
        print_err "Prova manualmente:"
        print_err "  python3 -m aqt install-qt linux desktop $QT_VERSION linux_gcc_arm64 -O $QT_PATH -m $QT_MODULES"
        exit 1
    fi

    print_ok "Qt $QT_VERSION installato in $QT_ROOT"
fi

# ── 5. Variabili d'ambiente ───────────────────────────────
print_section "5/5 — Variabili d'ambiente"

BASHRC="$HOME/.bashrc"
MARKER="# SVP GCS — Qt environment"

if grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
    print_warn "Variabili già presenti in ~/.bashrc (skip)"
else
    cat >> "$BASHRC" << ENVBLOCK

$MARKER
export QT_DIR="$QT_ROOT"
export PATH="\$QT_DIR/bin:\$PATH"
export LD_LIBRARY_PATH="\$QT_DIR/lib:\${LD_LIBRARY_PATH:-}"
export QT_PLUGIN_PATH="\$QT_DIR/plugins"
export QML2_IMPORT_PATH="\$QT_DIR/qml"
ENVBLOCK
    print_ok "Variabili aggiunte a ~/.bashrc"
fi

# Esporta anche per questa sessione
export QT_DIR="$QT_ROOT"
export PATH="$QT_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$QT_DIR/lib:${LD_LIBRARY_PATH:-}"

# ── Riepilogo finale ─────────────────────────────────────
print_section "Setup completato!"

echo ""
echo "  CMake:  $(cmake --version | head -1)"
echo "  Qt:     $(cat "$QT_ROOT/mkspecs/qconfig.pri" 2>/dev/null | grep "^QT_VERSION" | head -1 || echo "$QT_VERSION")"
echo "  Qt dir: $QT_ROOT"
echo ""

if [ -d "$QGC_DIR" ]; then
    print_ok "Repository trovato in $QGC_DIR"
    echo ""
    echo "  Per compilare SVP GCS:"
    echo "    cd $HOME && ./build_qgc.sh --release --appimage"
else
    print_warn "Repository non trovato in $QGC_DIR"
    echo ""
    echo "  Copia il repo dal tuo PC:"
    echo "    rsync -avz ~/qgroundcontrol/ $(whoami)@$(hostname -I | awk '{print $1}'):~/qgroundcontrol/"
    echo "    rsync -avz ~/build_qgc.sh   $(whoami)@$(hostname -I | awk '{print $1}'):~/"
    echo ""
    echo "  Poi compila:"
    echo "    ./build_qgc.sh --release --appimage"
fi

echo ""
print_warn "Ricarica la shell per applicare le variabili d'ambiente:"
echo "    source ~/.bashrc"
echo ""
