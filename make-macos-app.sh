#!/bin/bash
#
# make-macos-app.sh — one-shot build & install of GNU Backgammon as a native
# macOS app (2D GTK3 build).
#
# Given a Mac with Homebrew installed, this script:
#   1. installs the required dependencies (gtk+3, libepoxy, pkg-config),
#   2. configures the source for the GTK3 GUI with 2D boards,
#   3. builds gnubg,
#   4. assembles a clickable "GNU Backgammon.app" bundle under ./dist, and
#   5. copies it to /Applications.
#
# The bundle is self-contained for DATA (weights, bearoff databases,
# match-equity tables, fonts, pixmaps, sounds, ...): everything lives inside
# Contents/Resources and is passed to gnubg via --datadir. It still depends on
# the Homebrew GTK3 stack at runtime (the binary links the dylibs via absolute
# paths), so it is a launcher bundle, not a fully relocatable redistributable.
#
# 3D boards are intentionally not built: GtkGLArea is non-functional on GTK3's
# macOS/Quartz backend (see CHANGES.md). The app uses 2D boards.
#
# Usage:  ./make-macos-app.sh
#
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
APPNAME="GNU Backgammon"
OUTDIR="$SRC/dist"
APP="$OUTDIR/$APPNAME.app"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

# ---------------------------------------------------------------------------
# 0. Preflight: Xcode Command Line Tools and Homebrew
# ---------------------------------------------------------------------------
if ! xcode-select -p >/dev/null 2>&1; then
    echo "!! Xcode Command Line Tools are required. Install them with:" >&2
    echo "       xcode-select --install" >&2
    exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
    echo "!! Homebrew is required but was not found." >&2
    echo "       Install it from https://brew.sh and re-run this script." >&2
    exit 1
fi

BREW_PREFIX="$(brew --prefix)"

# ---------------------------------------------------------------------------
# 1. Dependencies
# ---------------------------------------------------------------------------
echo ">> Installing dependencies via Homebrew (gtk+3, libepoxy, pkg-config)..."
brew install gtk+3 libepoxy pkg-config

export PKG_CONFIG_PATH="$BREW_PREFIX/lib/pkgconfig:$BREW_PREFIX/share/pkgconfig:${PKG_CONFIG_PATH:-}"
export CPPFLAGS="-I$BREW_PREFIX/include ${CPPFLAGS:-}"
export LDFLAGS="-L$BREW_PREFIX/lib ${LDFLAGS:-}"

# ---------------------------------------------------------------------------
# 2. Configure (GTK3 GUI, 2D boards, no 3D)
# ---------------------------------------------------------------------------
cd "$SRC"
# Mark the generated autotools files as up to date so a fresh checkout doesn't
# trigger "maintainer mode" regeneration (which would need autoconf/automake).
touch aclocal.m4 configure config.h.in Makefile.in 2>/dev/null || true

echo ">> Configuring..."
./configure --with-gtk3 --without-board3d

# ---------------------------------------------------------------------------
# 3. Build
# ---------------------------------------------------------------------------
echo ">> Building gnubg..."
make -j"$(sysctl -n hw.ncpu)"

# ---------------------------------------------------------------------------
# 4. Assemble the .app bundle
# ---------------------------------------------------------------------------
echo ">> Staging a clean install to collect the data tree..."
make install DESTDIR="$STAGE" >/dev/null
PREFIX="$STAGE/usr/local"

if [ ! -x "$PREFIX/bin/gnubg" ]; then
    echo "!! gnubg was not built/installed correctly." >&2
    exit 1
fi

echo ">> Laying out $APP ..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/share"
cp "$PREFIX/bin/gnubg" "$APP/Contents/MacOS/gnubg"
cp -R "$PREFIX/share/gnubg" "$APP/Contents/Resources/share/"
[ -d "$PREFIX/share/locale" ] && cp -R "$PREFIX/share/locale" "$APP/Contents/Resources/share/" || true

echo ">> Writing launcher..."
cat > "$APP/Contents/MacOS/launcher" <<'LAUNCH'
#!/bin/bash
# Resolve the bundle's Resources/share and hand it to gnubg as the data dir.
DIR="$(cd "$(dirname "$0")" && pwd)"
RES="$(cd "$DIR/../Resources" && pwd)"
exec "$DIR/gnubg" --datadir "$RES/share" "$@"
LAUNCH
chmod +x "$APP/Contents/MacOS/launcher"

echo ">> Building icon..."
ICONSET="$STAGE/gnubg.iconset"
mkdir -p "$ICONSET"
# Pad the (non-square) logo onto a square white canvas, then emit the
# canonical iconset sizes.
sips --padToHeightWidth 512 512 --padColor FFFFFF \
     "$SRC/pixmaps/gnubg-big.png" --out "$STAGE/sq.png" >/dev/null
gen() { sips -z "$2" "$2" "$STAGE/sq.png" --out "$ICONSET/$1" >/dev/null; }
gen icon_16x16.png        16
gen icon_16x16@2x.png     32
gen icon_32x32.png        32
gen icon_32x32@2x.png     64
gen icon_128x128.png      128
gen icon_128x128@2x.png   256
gen icon_256x256.png      256
gen icon_256x256@2x.png   512
gen icon_512x512.png      512
gen icon_512x512@2x.png   1024
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/gnubg.icns"

echo ">> Writing Info.plist..."
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>GNU Backgammon</string>
    <key>CFBundleDisplayName</key>     <string>GNU Backgammon</string>
    <key>CFBundleIdentifier</key>      <string>org.gnu.gnubg</string>
    <key>CFBundleVersion</key>         <string>1.08.003</string>
    <key>CFBundleShortVersionString</key><string>1.08.003</string>
    <key>CFBundleExecutable</key>      <string>launcher</string>
    <key>CFBundleIconFile</key>        <string>gnubg.icns</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleSignature</key>       <string>????</string>
    <key>NSPrincipalClass</key>        <string>NSApplication</string>
    <key>NSHighResolutionCapable</key> <true/>
    <key>LSMinimumSystemVersion</key>  <string>11.0</string>
</dict>
</plist>
PLIST

printf 'APPL????' > "$APP/Contents/PkgInfo"
touch "$APP"

# ---------------------------------------------------------------------------
# 5. Install to /Applications
# ---------------------------------------------------------------------------
echo ">> Installing to /Applications/$APPNAME.app ..."
rm -rf "/Applications/$APPNAME.app"
cp -R "$APP" "/Applications/"
touch "/Applications/$APPNAME.app"   # nudge Finder to refresh the icon

echo ""
echo ">> Done. Launch it from Launchpad/Spotlight, or with:"
echo "       open \"/Applications/$APPNAME.app\""
