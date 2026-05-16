# chessever-tui

Terminal UI chess — play **Maia** in your terminal. Pure Dart, powered by
[nocterm](https://nocterm.dev/). Pixel-art board, mouse + keyboard, offline.

```
┌──────────────────┐    ╭────────────────────────────────────────╮
│ CHESSEVER  · tui │ 8  │   ░░░  ░░░  ░░░  ░░░  ░░░  ░░░  ░░░    │
│                  │ 7  │  ███▌ ███▌ ███▌ ███▌ ███▌ ███▌ ███▌    │
│ ▶ Play           │ 6  │                                        │
│   Settings       │ 5  │            ▟█▙                         │
│   Update         │ 4  │           ▟███▙                        │
│                  │ 3  │            ▀▘                          │
│                  │ 2  │  ███▌ ███▌ ███▌ ███▌ ███▌ ███▌ ███▌    │
│ ←→↑↓ cursor      │ 1  │   ░░░  ░░░  ░░░  ░░░  ░░░  ░░░  ░░░    │
│ space  select    │    ╰────────────────────────────────────────╯
│ q      quit      │       a    b    c    d    e    f    g    h
└──────────────────┘
```

## Run

```bash
dart pub get
dart run bin/chessever_tui.dart
```

Installed releases expose the command as `chessever`:

```bash
chessever
chessever 1900 blitz
chessever 1500 rapid
chessever update
```

`chessever-tui` remains available as a compatibility alias for older scripts.

`chessever` starts a playable Maia 1500 blitz game immediately. Shortcut
commands accept an ELO, clock preset, and optional side:

```bash
chessever 1900 blitz       # Maia 1900, 3+0
chessever 1300 bullet      # Maia 1300, 1+0
chessever 2200 5+3 black   # custom ELO/time, play black
```

## Controls

| key       | action                                  |
|-----------|-----------------------------------------|
| `←→↑↓`    | move the square cursor                  |
| `space`   | first tap selects → shows legal targets; second tap moves |
| `mouse`   | click any square to do the same thing   |
| `f`       | flip the board                          |
| `n` / `r` | new game setup                          |
| `p`       | play tab                                |
| `s`       | settings tab                            |
| `u`       | update tab                              |
| `q`       | quit                                    |

## Maia engine

The TUI drives **Maia** locally — a human-mimicking chess network published by
the [CSSLab](https://maiachess.com). We run it through `lc0` over UCI.

### One-time setup

1. Install `lc0` (or build from source):
   - macOS: `brew install lc0`
   - Linux: see <https://lczero.org/play/download/>
2. Download Maia weights:
   ```bash
   mkdir -p ~/.chessever-tui/weights
   cd ~/.chessever-tui/weights
   for elo in 1100 1300 1500 1700 1900; do
     curl -L -o maia-${elo}.pb.gz \
       https://github.com/CSSLab/maia-chess/raw/master/maia_weights/maia-${elo}.pb.gz
   done
   ```
3. (Optional) override paths via env vars:
   - `CHESSEVER_TUI_LC0=/path/to/lc0`
   - `CHESSEVER_TUI_MAIA_DIR=/path/to/weights`

If `lc0` or the requested weights are missing, the TUI falls back to a small
"vibes" engine so you can still play — the side panel will say **Vibes bot
(Maia weights missing)**.

## Design

- Color palette ported directly from `chessever_frontend_desktop/lib/theme/`.
- Pieces are 4-row × 5-col pixel sprites drawn with Unicode block characters.
- The board switches to a compact pixel density when the terminal is short.
- Pixel-art reference sheet: `assets/pixelart/chessever-pixel-art-reference.png`.
- Cursor halo and capture rings use brand primary / red.
- No dependencies on `flutter`. Pure Dart so the binary stays small.

## Updates

GitHub Actions builds release assets for macOS, Linux x64, and Windows x64.
Pushes to `main`/`master` update the moving `tui-latest` release, and version
tags `v*` publish tagged releases. The installer and in-app Update button both
pull from `https://github.com/Chessever/chessever-tui/releases/latest`, so the
next `chessever` start runs the newly installed binary.

MIT.
