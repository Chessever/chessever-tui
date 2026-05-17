# CLAUDE.md

Project guidance for Claude Code working on **chessever-tui**.

Canonical docs live in [`AGENTS.md`](./AGENTS.md) — read that first. It
covers project layout, build, release flow, and code conventions.

## Claude-specific notes

- **Always run `dart analyze --fatal-infos`** before claiming a change is
  done. CI gates on it; PRs fail otherwise.
- **No Flutter.** This is pure Dart compiled via `dart compile exe`.
  Adding `flutter/*` deps will break the release matrix and balloon the
  binary.
- **TUI cannot be smoke-tested non-interactively.** When you change
  rendering, drag handling, or sizing, say so explicitly in the summary
  rather than claiming visual verification you can't perform.
- **Version is split across two files** — `pubspec.yaml` `version:` *and*
  `const _version` in `bin/chessever_tui.dart`. Bump both, or `chessever
  --version` lies.
- **`main` pushes auto-release.** Any merge to `main` republishes the
  `tui-latest` GitHub Release within minutes. Treat `main` like a release
  branch; don't push WIP.
- **Worktrees under `.claude/worktrees/`** are AI session worktrees.
  Inspect commits with `git log main..<branch>` before merging — many
  end up empty.
- **Release URLs are public contracts.** Asset names
  (`chessever-tui-<os>-<arch>.tar.gz|zip`) are consumed by
  `tui.chessever.com/install.sh` and the in-app Update tab. Renaming
  them silently breaks installs.

## Common workflows

| Goal                               | Steps                                            |
|------------------------------------|--------------------------------------------------|
| Add a feature                      | branch → code → `dart analyze` → PR              |
| Cut a versioned release            | bump `pubspec.yaml` + `_version` → tag `v*` → push |
| Republish latest without a tag     | merge to `main`                                  |
| Smoke-test a change                | `dart compile exe bin/chessever_tui.dart -o /tmp/chesst && /tmp/chesst` |
| Diagnose CI failure                | `gh run list --workflow=release.yml`             |

See `AGENTS.md` for the full picture.
