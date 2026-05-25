import 'package:dartchess/dartchess.dart';

/// Pixel-art chess pieces rendered via half-block characters (▀ ▄ █).
///
/// Each sprite is a binary pixel matrix: `'#'` = inked (piece color),
/// `'.'` = transparent (shows square background). Two pixel rows pack
/// into one terminal row via [pair]; the resulting char carries one
/// foreground (piece color) and one background (square color) per cell.
///
/// Identity is locked by silhouette, not detail. Each role has a
/// unique top-row pattern AND a unique body shape so the eye separates
/// pieces at a glance:
///
///   pawn   — single-pixel head, no neighbors, smallest
///   knight — asymmetric, eye-notch in face, only non-symmetric piece
///   bishop — cleft mitre + 1-px-wide neck (no other piece has thin neck)
///   rook   — straight castellated 3-turret + dead-straight columns
///   queen  — multi-spike crown + curving shoulders (▀███▀)
///   king   — wide horizontal cross-bar (▄▄█▄▄), wider than body
///
/// Sizes:
///   extended : 5 cols × 8 px (renders 5×4 chars) — full density
///   compact  : 5 cols × 6 px (renders 5×3 chars) — compact density
///   small    : 3 cols × 4 px (renders 3×2 chars) — small density
///   mini     : 1 unicode glyph                    — mini density
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
    // Pawn — tiny isolated head, narrow stem, wide flat base.
    // Renders as:
    //     ▄
    //    ▀█▀
    //    ▄█▄
    //   █████
    Role.pawn: PieceSprite(
      extended: [
        '.....',
        '..#..',
        '.###.',
        '..#..',
        '..#..',
        '.###.',
        '#####',
        '#####',
      ],
      // Compact:
      //    ▄
      //   ▀█▀
      //   ▄███▄
      compact: [
        '.....',
        '..#..',
        '.###.',
        '..#..',
        '.###.',
        '#####',
      ],
      // Small:
      //   ▄
      //  ███
      small: [
        '...',
        '.#.',
        '###',
        '###',
      ],
      mini: '♟',
    ),

    // Knight — asymmetric horse profile facing left. Ear top-left, mass
    // sloping bottom-right, eye-notch in face row. Only piece with no
    // bilateral symmetry — instantly readable.
    // Renders as:
    //   ▄██▄
    //   ██▀██
    //    ▀███
    //   ▄████
    Role.knight: PieceSprite(
      extended: [
        '.##..',
        '####.',
        '#####',
        '##.##',
        '.####',
        '..###',
        '.####',
        '#####',
      ],
      // Compact:
      //   ▄██▄
      //   ▀█▄██
      //   ▄▄███
      compact: [
        '.##..',
        '####.',
        '##.##',
        '.####',
        '..###',
        '#####',
      ],
      // Small:
      //   ██▄
      //   ▄██
      small: [
        '##.',
        '###',
        '.##',
        '###',
      ],
      mini: '♞',
    ),

    // Bishop — cleft mitre on top + uniquely thin 1-pixel neck. The
    // cleft (split point) makes top read as TWO ears with a valley
    // between. The hair-thin neck `  █  ` is the bishop's body
    // signature — no other piece narrows that far.
    // Renders as:
    //    ▀▄▀
    //    ███
    //     █
    //   ▄███▄
    Role.bishop: PieceSprite(
      extended: [
        '.#.#.',
        '..#..',
        '.###.',
        '.###.',
        '..#..',
        '..#..',
        '.###.',
        '#####',
      ],
      // Compact:
      //    ▀▄▀
      //     █
      //   ▄███▄
      compact: [
        '.#.#.',
        '..#..',
        '..#..',
        '..#..',
        '.###.',
        '#####',
      ],
      // Small — uniform thin column, only piece with no shoulder.
      //    █
      //   ▄█▄
      small: [
        '.#.',
        '.#.',
        '.#.',
        '###',
      ],
      mini: '♝',
    ),

    // Rook — straight castellated 3-turret battlement, dead-straight
    // column body, flat-flat base. NO curves anywhere. Counterpoint to
    // the queen's wavy silhouette.
    // Renders as:
    //   █▄█▄█
    //    ███
    //    ███
    //   █████
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
      // Compact:
      //   █▄█▄█
      //    ███
      //   █████
      compact: [
        '#.#.#',
        '#####',
        '.###.',
        '.###.',
        '#####',
        '#####',
      ],
      // Small — 2 turrets, thin column, flat base.
      //   █▄█
      //   ▄█▄
      small: [
        '#.#',
        '###',
        '.#.',
        '###',
      ],
      mini: '♜',
    ),

    // Queen — multi-spike crown (4 spikes + center peak) + curving
    // shoulders that flare wider at top of each row pair. The wavy
    // `▀███▀` pattern is unique to queen — counterpoint to rook's
    // straight column.
    // Renders as:
    //   ▀▄█▄▀
    //   ▀███▀
    //   ▀███▀
    //   ▄███▄
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
      // Compact — 5-spike crown (different from rook's 3 in same width).
      //   ▄█▄█▄
      //   ▄███▄
      //   ▄███▄
      compact: [
        '.#.#.',
        '#####',
        '.###.',
        '#####',
        '.###.',
        '#####',
      ],
      // Small — only piece that's a SOLID FULL BLOCK at this size.
      //   ███
      //   ███
      small: [
        '###',
        '###',
        '###',
        '###',
      ],
      mini: '♛',
    ),

    // King — wide horizontal cross-bar that's LITERALLY wider than the
    // body below it (▄▄█▄▄ spans 5 cols with center peak). Only piece
    // whose top is wider than its body. The cross is unmistakable.
    // Renders as:
    //   ▄▄█▄▄
    //    ▄█▄
    //    ███
    //   ▄███▄
    Role.king: PieceSprite(
      extended: [
        '..#..',
        '#####',
        '..#..',
        '.###.',
        '.###.',
        '.###.',
        '.###.',
        '#####',
      ],
      // Compact:
      //   ▄▄█▄▄
      //    ▄█▄
      //   ▄███▄
      compact: [
        '..#..',
        '#####',
        '..#..',
        '.###.',
        '.###.',
        '#####',
      ],
      // Small — small point top + WIDE body (thicker than rook/bishop).
      //   ▄█▄
      //   ███
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
