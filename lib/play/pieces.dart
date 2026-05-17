import 'package:dartchess/dartchess.dart';

/// Block-art piece sprites adapted from the chess-tui (Rust) preset:
/// https://github.com/thomas-mauran/chess-tui  (MIT, src/pieces/*.rs)
///
/// Same silhouettes for white and black — color (foreground) provides the
/// side distinction. Three density tiers so the board scales down for
/// tiny terminals:
///
///   full    = 5×3 (7-wide cell, 1-col gutter each side)
///   compact = 3×2 (5-wide cell, 1-col gutter each side)
///   mini    = 1×1 (Unicode chess glyph, last-resort)
class PieceSprite {
  const PieceSprite(this.rows, this.compactRows, this.mini);
  final List<String> rows; // 3 strings × 5 cols
  final List<String> compactRows; // 2 strings × 3 cols
  final String mini;

  static const Map<Role, PieceSprite> _glyphs = {
    Role.pawn: PieceSprite(
      [
        '  ▂  ',
        ' ▆█▆ ',
        ' ▔▔▔ ',
      ],
      [
        '▆█▆',
        '▔▔▔',
      ],
      '♟',
    ),
    Role.knight: PieceSprite(
      [
        ' ▄▟▟▖',
        ' ▂█▛▘',
        '▝▀▀▀▘',
      ],
      [
        '▟█▛',
        '▔▔▔',
      ],
      '♞',
    ),
    Role.bishop: PieceSprite(
      [
        ' ▆▖▆ ',
        ' ▐▙▌ ',
        ' ▀▀▀ ',
      ],
      [
        '▐▙▌',
        '▔▔▔',
      ],
      '♝',
    ),
    Role.rook: PieceSprite(
      [
        ' ▅ ▅ ',
        ' ███ ',
        '▝▀▀▀▘',
      ],
      [
        '▅▅▅',
        '███',
      ],
      '♜',
    ),
    Role.queen: PieceSprite(
      [
        ' ▆▄▆ ',
        ' ▗█▖ ',
        ' ▀▀▀ ',
      ],
      [
        '▆▄▆',
        '▗█▖',
      ],
      '♛',
    ),
    Role.king: PieceSprite(
      [
        '▗▂╋▂▖',
        ' ▀█▀ ',
        ' ▀▀▀ ',
      ],
      [
        '╋█╋',
        '▀█▀',
      ],
      '♚',
    ),
  };

  static PieceSprite forRole(Role role) => _glyphs[role]!;
}
