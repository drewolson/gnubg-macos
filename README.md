# GNU Backgammon — macOS App (Apple Silicon & Intel)

A macOS fork of [GNU Backgammon](https://www.gnu.org/software/gnubg/) 1.08.003
that builds and runs as a clickable native app, with a graphical **2D board**
for playing and analysing games against the engine.

> **Boards:** 2D only. 3D boards are not built — `GtkGLArea` is non-functional on
> GTK3's macOS/Quartz backend (details in [`CHANGES.md`](CHANGES.md)).
> **Sound:** works (played via the built-in `afplay`).

## Quick install

From a checkout of this repository, run:

```sh
./make-macos-app.sh
```

That single command does everything:

1. Installs the required Homebrew packages (`gtk+3`, `libepoxy`, `pkg-config`).
2. Configures the source for the GTK3 GUI with 2D boards.
3. Builds `gnubg`.
4. Assembles **`GNU Backgammon.app`** in `./dist`.
5. Copies it to **`/Applications`**.

When it finishes, launch **GNU Backgammon** from Launchpad or Spotlight — or:

```sh
open "/Applications/GNU Backgammon.app"
```

## Prerequisites

- macOS on Apple Silicon or Intel.
- **Xcode Command Line Tools** — install with `xcode-select --install`.
- **Homebrew** — install from <https://brew.sh>.

The script checks for both and stops with instructions if either is missing.
It installs the remaining dependencies itself.

## How to play

Start a game with **Game → New → Game**, then play against the computer. A few
notes:

- **Undo** a move with **Ctrl+Z** (note: Control, not ⌘), or the Undo toolbar
  button.
- Sound effects are on by default; toggle them under the Settings/Sound options.
- There is also a command-line interface — run the binary inside the bundle with
  `-t`, or build and run `./gnubg -t`.

## Building manually

If you'd rather build by hand instead of using the script (Homebrew prefix shown
for Apple Silicon; on Intel use `/usr/local`):

```sh
brew install gtk+3 libepoxy pkg-config
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:/opt/homebrew/share/pkgconfig"
export CPPFLAGS="-I/opt/homebrew/include" LDFLAGS="-L/opt/homebrew/lib"
./configure --with-gtk3 --without-board3d
make -j"$(sysctl -n hw.ncpu)"
./gnubg          # run the GUI directly from the build directory
```

## Notes & limitations

- **The app needs the Homebrew GTK3 stack installed to run.** The binary links
  the Homebrew dylibs by absolute path, so the bundle is a convenient launcher
  rather than a standalone, fully relocatable redistributable. The app *is*
  self-contained for its data (neural-net weights, bearoff databases,
  match-equity tables, fonts, pixmaps, sounds), which live inside the bundle.
- **2D boards only** — see above.
- The app is unsigned. macOS Gatekeeper may require right-click → **Open** the
  first time, or allowing it under System Settings → Privacy & Security.

## More information

- [`CHANGES.md`](CHANGES.md) — everything this fork changes from upstream, and why.
- [`FORK.md`](FORK.md) — fork purpose and maintenance.
- [`README`](README) — the upstream GNU Backgammon readme.
- Upstream project: <https://www.gnu.org/software/gnubg/>

## License

GNU General Public License v3.0 or later, the same as upstream GNU Backgammon.
See [`COPYING`](COPYING).
