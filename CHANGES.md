# Fork Changes

This document tracks all modifications made to GNU Backgammon 1.08.003 in this fork.

## Format
Each entry should include:
- Date of change
- Description of what was changed
- Reason for the change
- Files affected

---

## 2025-10-14 - Initial Fork Setup

**Changes:**
- Initialized git repository
- Created FORK.md to document fork purpose and maintenance strategy
- Created this CHANGES.md file to track modifications

**Reason:**
Establishing proper version control and documentation for macOS-specific fork

**Files affected:**
- `.git/` (new)
- `FORK.md` (new)
- `CHANGES.md` (new)

---

## 2025-10-14 - macOS Readline Compatibility Fix

**Changes:**
- Modified readline initialization in gnubg.c to fix compilation on macOS
- Changed `rl_filename_quote_characters = szCommandSeparators` to only set `rl_basic_word_break_characters`
- Changed `rl_completion_entry_function = NullGenerator` to `rl_completion_entry_function = NULL`

**Reason:**
Modern macOS readline library has different function signature expectations. The `rl_filename_quote_characters` assignment was causing build issues, and `NullGenerator` should be NULL for proper readline 4.2+ compatibility on macOS.

**Files affected:**
- `gnubg.c` (line 4403, 4406)

---

## 2025-10-14 - Added cglm Graphics Library

**Changes:**
- Added complete cglm (OpenGL Mathematics) library to the project
- Includes headers for matrix operations, vectors, quaternions, affine transforms, camera operations, and other 3D math utilities
- Added Apple Silicon SIMD optimizations (applesimd.h)

**Reason:**
Required for 3D board rendering and graphics operations. The cglm library provides optimized math operations for OpenGL-based rendering, with specific support for macOS/Apple Silicon SIMD instructions.

**Files affected:**
- `cglm/` (entire directory - new, ~200+ header files)
- Includes core functionality in cglm/*.h
- SIMD optimizations in cglm/simd/
- Structured API in cglm/struct/
- Platform-specific optimizations in cglm/applesimd.h

---

## 2026-05-31 - macOS GUI (2D Boards) and Working Sound on Apple Silicon

Brought up the graphical interface so the game can be played against the computer
with a real board, and packaged it as a native macOS app.
**2D boards work and sound works. 3D boards do NOT work (see below).**

**GUI build (GTK3 + libepoxy).**
The fork previously built only the command-line binary: it was configured for the
dead GTK2 + gtkglext path, so GTK was never detected and the GUI was disabled.
Switching to GTK3 + libepoxy (the modern, maintained path), plus the
macOS-specific fixes below, produces a working GTK3 GUI. Homebrew's GTK3 uses the
native Quartz backend, so no XQuartz/X11 is required.
- `configure.ac` (darwin branch): replaced the legacy `-dylib_file .../libGL.dylib`
  linker hack -- a path that no longer exists on Apple Silicon -- with
  `-framework OpenGL`, and added `-DGL_SILENCE_DEPRECATION` to `CFLAGS`.
- `board3d/legacyGLinc.h`: include `<OpenGL/gl.h>` (not bare `<gl.h>`) under
  `USE_APPLE_OPENGL`.
- `board3d/font3dOGL.c`, `board3d/gtkcolour3d.c`: include `<OpenGL/glu.h>` (not
  `<GL/glu.h>`) under `USE_APPLE_OPENGL`.
- `board3d/font3dOGL.c`: `GLUFUN(X)` now casts callbacks to `GLvoid (*)(void)` to
  match Apple's `gluTessCallback` signature (modern clang errors on the mismatch).
- Regenerated `configure` from `configure.ac` with `autoconf`.
- Added the cglm math library earlier (see prior entry) for the 3D code paths.

**2D boards only -- 3D boards do not work.**
The shipped build is configured `--without-board3d`. `GtkGLArea` is non-functional
on this stack (Homebrew GTK 3.24, macOS Quartz / Apple Silicon): a minimal
`GtkGLArea` never emits its `render` signal (verified even with forced
`gtk_gl_area_queue_render`), so no GL is ever drawn -- the GL *context* is created
(OpenGL 4.1 Core over Metal) but GTK3's Quartz backend never dispatches rendering.
Embedding that broken GL widget blanked gnubg's entire window when `--with-board3d`
was enabled. gnubg's own 3D renderer (ShimOGL, shader-based) is fine; the blocker
is GTK3's incomplete Quartz GtkGLArea support. A real fix would mean rendering GL
offscreen (own CGL/NSOpenGL context + FBO) and blitting via cairo -- a substantial
effort, not pursued.

**Sound -- works.**
Rewrote the macOS sound backend in `sound.c` (the `HAVE_APPLE_COREAUDIO` branch):
replaced the deprecated AUGraph/AudioToolbox graph API -- which failed on Apple
Silicon and raised an error dialog for every sound event -- with the system
`/usr/bin/afplay`, spawned asynchronously via `g_spawn_async`. afplay is invoked
with an argv array (so paths containing spaces, e.g. inside `GNU Backgammon.app`,
work) and an absolute path (so it is found when launched from Finder with a
minimal PATH). gnubg's sounds are short WAVs, which afplay plays reliably.

**Native app bundle.**
Added `make-macos-app.sh`, which builds a clickable `GNU Backgammon.app` under
`dist/`. It stages a `make install`, copies `share/gnubg` (weights, bearoff DBs,
match-equity tables, fonts, pixmaps, sounds, ...) into `Contents/Resources/share`,
and a `launcher` script passes `--datadir` so gnubg finds its data regardless of
location. It generates an `.icns` from `pixmaps/gnubg-big.png` and an `Info.plist`.
The bundle is self-contained for data but still depends on the Homebrew GTK3 stack
at runtime (dylibs referenced via absolute `/opt/homebrew` paths) -- a launcher
bundle, not a fully relocatable redistributable.

**Build instructions (Apple Silicon, Homebrew):**
```
brew install gtk+3 libepoxy
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:/opt/homebrew/share/pkgconfig"
export CPPFLAGS="-I/opt/homebrew/include" LDFLAGS="-L/opt/homebrew/lib"
./configure --with-gtk3 --without-board3d
make -j8
./make-macos-app.sh        # optional: build dist/GNU Backgammon.app
```
Run with `./gnubg` for the GUI, or `./gnubg -t` for the command line.

**Files affected:**
- `configure.ac`, `configure` (regenerated)
- `board3d/legacyGLinc.h`, `board3d/font3dOGL.c`, `board3d/gtkcolour3d.c`
- `sound.c`
- `make-macos-app.sh` (new)
- `~/.gnubg/gnubgautorc` (user config, not in repo): `set sound enable yes`

**Known limitations:**
- 3D boards do not render (GtkGLArea broken on GTK3/Quartz) -- 2D boards only.
- The app requires the Homebrew GTK3 stack installed; it is not a standalone
  redistributable.

---

## Future Changes

All future modifications should be documented here with the same format:
- Date
- Description
- Reason
- Files affected
