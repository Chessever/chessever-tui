import 'package:dartchess/dartchess.dart';

/// Pixel-art glyphs for chess pieces. Each sprite is 4 rows × 5 cols, designed
/// to read as a chiseled silhouette when stacked in a 7×4 board cell with a
/// one-column gutter on each side. Block characters carry the entire shape so
/// a single foreground color (piece color) plus the underlying square fill
/// produce a clean two-tone result without per-character styling.
class PieceSprite {
  const PieceSprite(this.rows, this.compactRows);
  final List<String> rows; // exactly 4 strings of length 5
  final List<String> compactRows; // exactly 2 strings of length 3

  static const Map<Role, PieceSprite> _glyphs = {
    Role.pawn: PieceSprite([
      '  ▄  ',
      ' ▟█▙ ',
      '  █  ',
      '▟███▙',
    ], [
      ' ▄ ',
      '▟█▙',
    ]),
    Role.knight: PieceSprite([
      ' ▄▛▙ ',
      '▟██▀ ',
      ' ▐██▙',
      '▟███▙',
    ], [
      '▟▛ ',
      '▐█▙',
    ]),
    Role.bishop: PieceSprite([
      '  ▄  ',
      ' ▟█▙ ',
      ' ▝█▘ ',
      '▟███▙',
    ], [
      '▟█▙',
      ' █ ',
    ]),
    Role.rook: PieceSprite([
      '▟▀█▀▙',
      ' ███ ',
      ' ███ ',
      '▟███▙',
    ], [
      '▙█▟',
      '███',
    ]),
    Role.queen: PieceSprite([
      '▙▄█▄▟',
      '▟███▙',
      ' ███ ',
      '▟███▙',
    ], [
      '▙█▟',
      '███',
    ]),
    Role.king: PieceSprite([
      ' ▄█▄ ',
      '  █  ',
      ' ▟█▙ ',
      '▟███▙',
    ], [
      '▄█▄',
      '▟█▙',
    ]),
  };

  static PieceSprite forRole(Role role) => _glyphs[role]!;
}
