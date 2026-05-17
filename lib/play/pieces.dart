import 'package:dartchess/dartchess.dart';

/// Block-art piece sprites adapted from the chess-tui (Rust, MIT) preset.
/// https://github.com/thomas-mauran/chess-tui — src/pieces/*.rs
///
/// Same silhouettes for white and black — color (foreground) carries the
/// side distinction. Four density tiers so the board still reads on
/// anything from a maximized terminal down to a tmux split:
///
///   full    = 5×4 (chess-tui Extended), inside a 7×4 cell
///   compact = 5×3 (chess-tui Compact),  inside a 7×3 cell
///   small   = 3×2 tight variant,        inside a 5×2 cell
///   mini    = 1×1 Unicode glyph,        inside a 3×1 cell
class PieceSprite {
  const PieceSprite({
    required this.extended,
    required this.compact,
    required this.small,
    required this.mini,
  });
  final List<String> extended; // 4 rows × 5 cols
  final List<String> compact; // 3 rows × 5 cols
  final List<String> small; // 2 rows × 3 cols
  final String mini;

  static const Map<Role, PieceSprite> _glyphs = {
    Role.pawn: PieceSprite(
      extended: [
        '     ',
        ' ▝█▘ ',
        ' ▟█▙ ',
        ' ▔▔▔ ',
      ],
      compact: [
        '  ▂  ',
        ' ▆█▆ ',
        ' ▔▔▔ ',
      ],
      small: [
        '▆█▆',
        '▔▔▔',
      ],
      mini: '♟',
    ),
    Role.knight: PieceSprite(
      extended: [
        '  ▖▗ ',
        '▗▇▟█▌',
        ' ▟█▛ ',
        '▝▀▀▀▘',
      ],
      compact: [
        ' ▄▟▟▖',
        ' ▂█▛▘',
        '▝▀▀▀▘',
      ],
      small: [
        '▟█▛',
        '▔▔▔',
      ],
      mini: '♞',
    ),
    Role.bishop: PieceSprite(
      extended: [
        ' ▄▁▗ ',
        ' ██▟ ',
        ' ▟█▙ ',
        '▝▀▀▀▘',
      ],
      compact: [
        ' ▆▖▆ ',
        ' ▐▙▌ ',
        ' ▀▀▀ ',
      ],
      small: [
        '▐▙▌',
        '▔▔▔',
      ],
      mini: '♝',
    ),
    Role.rook: PieceSprite(
      extended: [
        '▄ ▄ ▄',
        '█████',
        ' ███ ',
        '▀▀▀▀▀',
      ],
      compact: [
        ' ▅ ▅ ',
        ' ███ ',
        '▝▀▀▀▘',
      ],
      small: [
        '▅▅▅',
        '███',
      ],
      mini: '♜',
    ),
    Role.queen: PieceSprite(
      extended: [
        '▂ ▄ ▂',
        '▜▙█▟▛',
        ' ▜█▛ ',
        '▝▀▀▀▘',
      ],
      compact: [
        ' ▆▄▆ ',
        ' ▗█▖ ',
        ' ▀▀▀ ',
      ],
      small: [
        '▆▄▆',
        '▗█▖',
      ],
      mini: '♛',
    ),
    Role.king: PieceSprite(
      extended: [
        ' ▂╋▂ ',
        '▜███▛',
        ' ▜█▛ ',
        '▝▀▀▀▘',
      ],
      compact: [
        '▗▂╋▂▖',
        ' ▀█▀ ',
        ' ▀▀▀ ',
      ],
      small: [
        '╋█╋',
        '▀█▀',
      ],
      mini: '♚',
    ),
  };

  static PieceSprite forRole(Role role) => _glyphs[role]!;
}
