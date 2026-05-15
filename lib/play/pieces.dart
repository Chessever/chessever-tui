import 'package:dartchess/dartchess.dart';

/// Pixel-art glyphs for chess pieces. Each sprite is 4 rows × 5 cols, designed
/// to read as a chiseled silhouette inside a 7×4 board cell (one column of
/// gutter on each side). Every role has a distinct "crown" so pieces can be
/// told apart at a glance: dot pawn, asymmetric knight, gem-topped bishop,
/// crenelated rook, multi-spike queen, cross-topped king. The shared `' ███ '`
/// body keeps a stable silhouette so the top row carries identity.
class PieceSprite {
  const PieceSprite(this.rows);
  final List<String> rows; // exactly 4 strings of length 5

  static const Map<Role, PieceSprite> _glyphs = {
    Role.pawn: PieceSprite([
      '     ',
      '  ●  ',
      ' ▟█▙ ',
      ' ███ ',
    ]),
    Role.knight: PieceSprite([
      ' ▟▀▙ ',
      '▟██▙ ',
      ' ▝██▖',
      ' ███ ',
    ]),
    Role.bishop: PieceSprite([
      '  ◆  ',
      ' ▟█▙ ',
      '  █  ',
      ' ███ ',
    ]),
    Role.rook: PieceSprite([
      '█▄█▄█',
      ' ███ ',
      ' ███ ',
      ' ███ ',
    ]),
    Role.queen: PieceSprite([
      '▙▄█▄▟',
      ' ███ ',
      ' ███ ',
      ' ███ ',
    ]),
    Role.king: PieceSprite([
      '  ╋  ',
      ' ▟█▙ ',
      ' ███ ',
      ' ███ ',
    ]),
  };

  static PieceSprite forRole(Role role) => _glyphs[role]!;
}
