import 'package:dartchess/dartchess.dart';

/// Pieces are rendered with the real Unicode chess glyphs at the core
/// (♟♞♝♜♛♚) framed by piece-specific outline strokes. The chess glyph is
/// instantly recognizable to anyone who has seen a chess board; the strokes
/// (battlements, mitre apex, crown spikes, royal brackets, knight ear, …)
/// add a distinct silhouette so pieces remain readable even when the glyph
/// itself doesn't render with full detail in some terminal fonts.
///
///   full    = 5×3 (column gutter on each side of a 7-wide cell)
///   compact = 3×2 (single-column gutter inside a 5-wide cell)
///   mini    = 1×1 (single glyph; tight density fallback)
class PieceSprite {
  const PieceSprite(this.rows, this.compactRows, this.mini);
  final List<String> rows; // 3 strings × 5 cols
  final List<String> compactRows; // 2 strings × 3 cols
  final String mini; // single grapheme

  static const Map<Role, PieceSprite> _glyphs = {
    Role.pawn: PieceSprite(
      [
        '     ',
        '  ♟  ',
        '  ─  ',
      ],
      [
        ' ♟ ',
        ' ─ ',
      ],
      '♟',
    ),
    Role.knight: PieceSprite(
      [
        ' ╱▘  ',
        ' ♞▕  ',
        '  ─  ',
      ],
      [
        '╱♞ ',
        ' ─ ',
      ],
      '♞',
    ),
    Role.bishop: PieceSprite(
      [
        '  ╱╲ ',
        '  ♝  ',
        ' └─┘ ',
      ],
      [
        ' ▲ ',
        ' ♝ ',
      ],
      '♝',
    ),
    Role.rook: PieceSprite(
      [
        ' ┌┬┐ ',
        ' │♜│ ',
        ' └─┘ ',
      ],
      [
        '┌┐ ',
        '│♜│',
      ],
      '♜',
    ),
    Role.queen: PieceSprite(
      [
        ' ▴▴▴ ',
        ' (♛) ',
        ' └─┘ ',
      ],
      [
        '▴▴▴',
        ' ♛ ',
      ],
      '♛',
    ),
    Role.king: PieceSprite(
      [
        '  ✚  ',
        ' [♚] ',
        ' └─┘ ',
      ],
      [
        ' ✚ ',
        ' ♚ ',
      ],
      '♚',
    ),
  };

  static PieceSprite forRole(Role role) => _glyphs[role]!;
}
