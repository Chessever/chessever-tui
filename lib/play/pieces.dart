import 'package:dartchess/dartchess.dart';

/// Pixel-art chess pieces rendered via half-block characters (▀ ▄ █).
///
/// Each sprite is a binary pixel matrix: `'#'` = inked (piece color),
/// `'.'` = transparent (shows square background). Two pixel rows pack
/// into one terminal row via [pair]; the resulting char carries one
/// foreground (piece color) and one background (square color) per cell.
///
/// Sizes:
///   extended : 5 cols × 8 px (renders 5×4 chars) — full density
///   compact  : 5 cols × 6 px (renders 5×3 chars) — compact density
///   small    : 3 cols × 4 px (renders 3×2 chars) — small density
///   mini     : 1 unicode glyph                    — mini density
///
/// Same silhouette for both sides; side distinction comes from the
/// foreground color the caller passes to the renderer.
class PieceSprite {
  const PieceSprite({
    required this.extended,
    required this.compact,
    required this.small,
    required this.mini,
  });

  /// Pixel rows. Even count required (paired top/bottom for half-block).
  final List<String> extended;
  final List<String> compact;
  final List<String> small;
  final String mini;

  static const Map<Role, PieceSprite> _glyphs = {
    Role.pawn: PieceSprite(
      extended: [
        '.....',
        '..#..',
        '.###.',
        '.###.',
        '..#..',
        '.###.',
        '.###.',
        '#####',
      ],
      compact: [
        '..#..',
        '.###.',
        '..#..',
        '.###.',
        '.###.',
        '#####',
      ],
      small: [
        '.#.',
        '###',
        '.#.',
        '###',
      ],
      mini: '♟',
    ),
    Role.knight: PieceSprite(
      extended: [
        '..##.',
        '.####',
        '##.##',
        '#####',
        '.####',
        '..###',
        '.####',
        '#####',
      ],
      compact: [
        '.##..',
        '####.',
        '##.##',
        '.####',
        '.####',
        '#####',
      ],
      small: [
        '##.',
        '###',
        '.##',
        '###',
      ],
      mini: '♞',
    ),
    Role.bishop: PieceSprite(
      extended: [
        '..#..',
        '.#.#.',
        '.###.',
        '..#..',
        '.###.',
        '.###.',
        '.###.',
        '#####',
      ],
      compact: [
        '..#..',
        '.###.',
        '..#..',
        '.###.',
        '.###.',
        '#####',
      ],
      small: [
        '.#.',
        '###',
        '.#.',
        '###',
      ],
      mini: '♝',
    ),
    Role.rook: PieceSprite(
      extended: [
        '#.#.#',
        '#####',
        '.###.',
        '.###.',
        '.###.',
        '.###.',
        '#####',
        '#####',
      ],
      compact: [
        '#.#.#',
        '#####',
        '.###.',
        '.###.',
        '#####',
        '#####',
      ],
      small: [
        '#.#',
        '###',
        '.#.',
        '###',
      ],
      mini: '♜',
    ),
    Role.queen: PieceSprite(
      extended: [
        '#.#.#',
        '.###.',
        '#####',
        '.###.',
        '#####',
        '.###.',
        '.###.',
        '#####',
      ],
      compact: [
        '#.#.#',
        '#####',
        '.###.',
        '#####',
        '.###.',
        '#####',
      ],
      small: [
        '#.#',
        '###',
        '###',
        '###',
      ],
      mini: '♛',
    ),
    Role.king: PieceSprite(
      extended: [
        '..#..',
        '.###.',
        '..#..',
        '#####',
        '.###.',
        '.###.',
        '.###.',
        '#####',
      ],
      compact: [
        '..#..',
        '.###.',
        '#####',
        '.###.',
        '.###.',
        '#####',
      ],
      small: [
        '.#.',
        '###',
        '###',
        '###',
      ],
      mini: '♚',
    ),
  };

  static PieceSprite forRole(Role role) => _glyphs[role]!;

  /// Pack two pixel rows into one terminal row using half-blocks.
  /// `top` and `bottom` must be equal-length strings of `'#'` (ink) and
  /// `'.'` (transparent). Output uses `' '` for empty, `'▀'` for top-only,
  /// `'▄'` for bottom-only, `'█'` for both.
  static String pair(String top, String bottom) {
    assert(top.length == bottom.length);
    final out = StringBuffer();
    for (var i = 0; i < top.length; i++) {
      final t = top.codeUnitAt(i) == 0x23; // '#'
      final b = bottom.codeUnitAt(i) == 0x23;
      out.writeCharCode(
        t && b ? 0x2588 : t ? 0x2580 : b ? 0x2584 : 0x20,
      );
    }
    return out.toString();
  }

  /// Convert a pixel matrix to a list of half-block char rows.
  /// Input height must be even; output height = input ~/ 2.
  static List<String> halfBlockRows(List<String> pixels) {
    assert(pixels.length.isEven, 'sprite must have even row count');
    final rows = <String>[];
    for (var i = 0; i < pixels.length; i += 2) {
      rows.add(pair(pixels[i], pixels[i + 1]));
    }
    return rows;
  }
}
