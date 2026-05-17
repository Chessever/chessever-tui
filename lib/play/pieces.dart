import 'package:dartchess/dartchess.dart';

/// Head-only pixel-art glyphs. Each role has a distinctive crown/top so pieces
/// are recognizable at a glance even at compact density.
///
///   full   = 5×3 (column gutter on each side of a 7-wide cell)
///   compact= 3×2 (single-column gutter inside a 5-wide cell)
///   mini   = 1×1 (single glyph; tight density fallback)
class PieceSprite {
  const PieceSprite(this.rows, this.compactRows, this.mini);
  final List<String> rows; // 3 strings × 5 cols
  final List<String> compactRows; // 2 strings × 3 cols
  final String mini; // single grapheme

  static const Map<Role, PieceSprite> _glyphs = {
    Role.pawn: PieceSprite(
      [
        '     ',
        '  ●  ',
        ' ▟█▙ ',
      ],
      [
        ' ● ',
        ' █ ',
      ],
      '♟',
    ),
    Role.knight: PieceSprite(
      [
        ' ▟▀▘ ',
        '▟██▙ ',
        '  ██▖',
      ],
      [
        '▟▀▖',
        ' ██',
      ],
      '♞',
    ),
    Role.bishop: PieceSprite(
      [
        '  ▲  ',
        ' ▟▼▙ ',
        ' ▝█▘ ',
      ],
      [
        ' ▲ ',
        '▝█▘',
      ],
      '♝',
    ),
    Role.rook: PieceSprite(
      [
        '█ █ █',
        ' ███ ',
        ' ███ ',
      ],
      [
        '▌▐▌',
        '███',
      ],
      '♜',
    ),
    Role.queen: PieceSprite(
      [
        '◆ ▲ ◆',
        '▝▟█▙▘',
        ' ███ ',
      ],
      [
        '◆▲◆',
        '███',
      ],
      '♛',
    ),
    Role.king: PieceSprite(
      [
        '  ╋  ',
        ' ▟█▙ ',
        ' ███ ',
      ],
      [
        ' ╋ ',
        '███',
      ],
      '♚',
    ),
  };

  static PieceSprite forRole(Role role) => _glyphs[role]!;
}
