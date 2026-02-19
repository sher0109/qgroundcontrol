#!/bin/bash
#============================================
# SVP GCS Build Script
# Uso: ./build_qgc.sh [opzioni]
#============================================

# ── Configurazione ────────────────────────
QGC_DIR="$HOME/qgroundcontrol"
BUILD_DIR="$QGC_DIR/build"
BUILD_TYPE="Debug"
APP_NAME="SVPGCS"

# Rileva architettura automaticamente
ARCH=$(uname -m)   # x86_64  oppure  aarch64 (Jetson)

case "$ARCH" in
    x86_64)
        QT_DIR="${QT_DIR:-$HOME/Qt/6.10.1/gcc_64}"
        APPIMAGE_TOOL="$HOME/appimagetool-x86_64.AppImage"
        APPIMAGE_ARCH="x86_64"
        APPIMAGE_OUT="$HOME/${APP_NAME}-x86_64.AppImage"
        ;;
    aarch64)
        # Su Jetson: installa Qt con ./tools/setup/install-qt-debian.sh
        # oppure imposta QT_DIR manualmente prima di lanciare lo script
        QT_DIR="${QT_DIR:-$HOME/Qt/6.10.1/gcc_arm64}"
        APPIMAGE_TOOL="$HOME/appimagetool-aarch64.AppImage"
        APPIMAGE_ARCH="aarch64"
        APPIMAGE_OUT="$HOME/${APP_NAME}-jetson-aarch64.AppImage"
        ;;
    *)
        echo "[ERRORE] Architettura non supportata: $ARCH"
        exit 1
        ;;
esac

# ── Colori ───────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
print_err()  { echo -e "${RED}[ERRORE]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[INFO]${NC} $1"; }

# ── Help ──────────────────────────────────
show_help() {
    echo ""
    echo "Uso: ./build_qgc.sh [opzione]"
    echo ""
    echo "Opzioni:"
    echo "  --clean       Cancella la build e riconfigura da zero"
    echo "  --release     Compila in modalità Release"
    echo "  --run         Compila e lancia"
    echo "  --rebuild     Ricompila tutto (senza riconfigurare)"
    echo "  --appimage    Compila in Release e crea AppImage portabile"
    echo "  --help        Mostra questo messaggio"
    echo ""
    echo "Architettura rilevata: $ARCH"
    echo "Qt directory:          $QT_DIR"
    echo ""
}

# ── Parse argomenti ───────────────────────
CLEAN=false
RUN=false
REBUILD=false
APPIMAGE=false

for arg in "$@"; do
    case $arg in
        --clean)    CLEAN=true ;;
        --release)  BUILD_TYPE="Release" ;;
        --run)      RUN=true ;;
        --rebuild)  REBUILD=true ;;
        --appimage) APPIMAGE=true; BUILD_TYPE="Release" ;;
        --help)     show_help; exit 0 ;;
        *)          echo "Opzione sconosciuta: $arg"; show_help; exit 1 ;;
    esac
done

# ── Controlli prerequisiti ────────────────
if [ ! -d "$QGC_DIR" ]; then
    print_err "Directory QGC non trovata: $QGC_DIR"
    exit 1
fi

if [ ! -d "$QT_DIR" ]; then
    print_err "Directory Qt non trovata: $QT_DIR"
    print_err "Imposta QT_DIR manualmente: QT_DIR=/percorso/qt ./build_qgc.sh"
    exit 1
fi

# Verifica che la cartella custom/ esista (build SVP)
if [ ! -d "$QGC_DIR/custom" ]; then
    print_err "Cartella custom/ non trovata in $QGC_DIR — il custom build SVP non è presente!"
    exit 1
fi

cd "$QGC_DIR" || exit 1

echo ""
echo "============================================"
echo "  SVP GCS Build"
echo "  Architettura : $ARCH"
echo "  Tipo         : $BUILD_TYPE"
echo "  Qt           : $QT_DIR"
[ "$APPIMAGE" = true ] && echo "  Output       : $APPIMAGE_OUT"
echo "============================================"
echo ""

# ── Clean ────────────────────────────────
if [ "$CLEAN" = true ]; then
    print_warn "Pulizia build precedente..."
    rm -rf "$BUILD_DIR"
    print_ok "Build pulita"
fi

# ── Configura CMake ───────────────────────
if [ ! -f "$BUILD_DIR/build.ninja" ]; then
    print_warn "Configurazione CMake..."
    "$QT_DIR/bin/qt-cmake" \
        -B "$BUILD_DIR" \
        -G Ninja \
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
        -DQGC_BUILD_TESTING=OFF

    if [ $? -ne 0 ]; then
        print_err "Configurazione CMake fallita!"
        exit 1
    fi
    print_ok "Configurazione completata"
fi

# ── Compila ───────────────────────────────
if [ "$REBUILD" = true ]; then
    print_warn "Rebuild completo..."
    cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" --clean-first --parallel "$(nproc)"
else
    print_warn "Compilazione incrementale..."
    cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" --parallel "$(nproc)"
fi

if [ $? -ne 0 ]; then
    echo ""
    print_err "BUILD FALLITA!"
    exit 1
fi

echo ""
print_ok "BUILD COMPLETATA!"

# ── Trova eseguibile ──────────────────────
QGC_EXE=$(find "$BUILD_DIR" -maxdepth 4 -type f -executable -name "$APP_NAME" 2>/dev/null | head -1)

if [ -z "$QGC_EXE" ]; then
    QGC_EXE="$BUILD_DIR/$BUILD_TYPE/$APP_NAME"
fi

if [ -f "$QGC_EXE" ]; then
    print_ok "Eseguibile: $QGC_EXE"
else
    print_err "Eseguibile non trovato: $QGC_EXE"
    exit 1
fi

#============================================
# AppImage
#============================================
if [ "$APPIMAGE" = true ]; then
    echo ""
    echo "============================================"
    echo "  Creazione AppImage ($APPIMAGE_ARCH)"
    echo "============================================"
    echo ""

    APPDIR="$HOME/${APP_NAME}.AppDir"

    # Scarica appimagetool se non presente
    if [ ! -f "$APPIMAGE_TOOL" ]; then
        print_warn "Scarico appimagetool per $APPIMAGE_ARCH..."
        wget -q --show-progress -O "$APPIMAGE_TOOL" \
            "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-${APPIMAGE_ARCH}.AppImage"
        chmod +x "$APPIMAGE_TOOL"
        print_ok "appimagetool scaricato"
    fi

    # Crea struttura AppDir
    rm -rf "$APPDIR"
    mkdir -p "$APPDIR/usr/"{bin,lib,plugins,qml,share/applications,"share/icons/hicolor/256x256/apps"}

    # Copia eseguibile
    cp "$QGC_EXE" "$APPDIR/usr/bin/$APP_NAME"
    print_ok "Eseguibile copiato"

    # Librerie Qt
    print_warn "Copia librerie Qt..."
    cp -a "$QT_DIR/lib"/libQt6*.so*  "$APPDIR/usr/lib/" 2>/dev/null
    cp -a "$QT_DIR/lib"/libicu*.so*  "$APPDIR/usr/lib/" 2>/dev/null
    print_ok "Librerie copiate"

    # Plugin e QML
    print_warn "Copia plugin e moduli QML..."
    cp -r "$QT_DIR/plugins/"* "$APPDIR/usr/plugins/" 2>/dev/null
    cp -r "$QT_DIR/qml/"*     "$APPDIR/usr/qml/"     2>/dev/null
    print_ok "Plugin e QML copiati"

    # Icona
    ICON_SRC=$(find "$QGC_DIR/custom/res" "$QGC_DIR/resources/icons" \
        -name "*.png" 2>/dev/null | head -1)
    if [ -n "$ICON_SRC" ]; then
        cp "$ICON_SRC" "$APPDIR/usr/share/icons/hicolor/256x256/apps/${APP_NAME}.png"
        cp "$ICON_SRC" "$APPDIR/${APP_NAME}.png"
        print_ok "Icona copiata"
    else
        print_warn "Nessuna icona PNG trovata — AppImage creata senza icona"
    fi

    # File .desktop
    cat > "$APPDIR/${APP_NAME}.desktop" << DESKTOP
[Desktop Entry]
Name=SVP GCS
Exec=${APP_NAME}
Icon=${APP_NAME}
Type=Application
Categories=Utility;
DESKTOP
    cp "$APPDIR/${APP_NAME}.desktop" "$APPDIR/usr/share/applications/"

    # AppRun
    cat > "$APPDIR/AppRun" << APPRUN
#!/bin/bash
DIR="\$(dirname "\$(readlink -f "\$0")")"
export LD_LIBRARY_PATH="\$DIR/usr/lib:\$LD_LIBRARY_PATH"
export QT_PLUGIN_PATH="\$DIR/usr/plugins"
export QML_IMPORT_PATH="\$DIR/usr/qml"
export QML2_IMPORT_PATH="\$DIR/usr/qml"
exec "\$DIR/usr/bin/${APP_NAME}" "\$@"
APPRUN
    chmod +x "$APPDIR/AppRun"

    # Genera AppImage
    print_warn "Generazione AppImage..."
    cd "$HOME"
    ARCH="$APPIMAGE_ARCH" "$APPIMAGE_TOOL" "$APPDIR" "$APPIMAGE_OUT" 2>/dev/null \
    || ARCH="$APPIMAGE_ARCH" "$APPIMAGE_TOOL" --appimage-extract-and-run "$APPDIR" "$APPIMAGE_OUT"

    if [ $? -ne 0 ]; then
        print_err "Creazione AppImage fallita!"
        rm -rf "$APPDIR"
        exit 1
    fi

    rm -rf "$APPDIR"

    echo ""
    print_ok "AppImage creata: $APPIMAGE_OUT"
    print_ok "Dimensione: $(du -sh "$APPIMAGE_OUT" | cut -f1)"
    echo ""
    if [ "$ARCH" = "x86_64" ]; then
        echo "  Copia su Desktop Windows:"
        echo "    cp $APPIMAGE_OUT /mnt/c/Users/$(whoami)/Desktop/"
    else
        echo "  Copia su altro dispositivo Jetson:"
        echo "    scp $APPIMAGE_OUT user@jetson:~/"
    fi
    echo ""
fi

# ── Lancia ───────────────────────────────
if [ "$RUN" = true ]; then
    echo ""
    print_warn "Lancio $APP_NAME..."
    "$QGC_EXE"
fi
