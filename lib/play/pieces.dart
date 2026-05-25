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
///   pawn   — single isolated round head, narrow stem, flared base
///   knight — asymmetric horse profile with eye-notch in face
///   bishop — cleft mitre (visible gap at tip) + 1-pixel-wide neck
///   rook   — multi-turret battlement + dead-straight column body
///   queen  — multi-spike crown + curving shoulders flaring outward
///   king   — wide cross-bar wider than its body (▄▄█▄▄ family)
///
/// Sizes (cell dimensions = sprite + 2 cols horizontal padding):
///   xlarge   : 7 cols × 12 px (renders 7×6 chars) — huge terminals
///   extended : 5 cols × 8 px  (renders 5×4 chars) — full density
///   compact  : 5 cols × 6 px  (renders 5×3 chars) — compact density
///   small    : 5 cols × 4 px  (renders 5×2 chars) — small density
///   mini     : 1 unicode glyph                    — mini density
class PieceSprite {
  const PieceSprite({
    required this.xlarge,
    required this.extended,
    required this.compact,
    required this.small,
    required this.mini,
  });

  final List<String> xlarge;
  final List<String> extended;
  final List<String> compact;
  final List<String> small;
  final String mini;

  static const Map<Role, PieceSprite> _glyphs = {
    // PAWN — isolated round head, narrow stem, wide flat base. Only
    // piece whose head sits ABOVE empty pixels (the airspace makes it
    // read as "small").
    Role.pawn: PieceSprite(
      // 7×12 xlarge — full Staunton pawn silhouette.
      // Renders 6 char rows: arc, head, neck-top, neck-bot, hip, base.
      xlarge: [
        '.......',
        '..###..',
        '.#####.',
        '.#####.',
        '..###..',
        '...#...',
        '...#...',
        '..###..',
        '.#####.',
        '.#####.',
        '#######',
        '#######',
      ],
      // 5×8 extended.
      extended: [
        '.....',
        '..#..',
        '.###.',
        '.###.',
        '..#..',
        '.###.',
        '#####',
        '#####',
      ],
      // 5×6 compact.
      compact: [
        '.....',
        '..#..',
        '.###.',
        '..#..',
        '.###.',
        '#####',
      ],
      // 5×4 small.
      small: [
        '.....',
        '..#..',
        '.###.',
        '#####',
      ],
      mini: '♟',
    ),

    // KNIGHT — asymmetric horse profile facing left. Ear top-left,
    // mass sloping bottom-right, eye-notch in face row. Only piece
    // with no bilateral symmetry.
    Role.knight: PieceSprite(
      // 7×12 xlarge — ear, mane, head, eye notch, neck angled right,
      // chest, base.
      xlarge: [
        '.......',
        '..##...',
        '.####..',
        '######.',
        '##.####',
        '#######',
        '.######',
        '..#####',
        '...####',
        '..#####',
        '.######',
        '#######',
      ],
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
      compact: [
        '.##..',
        '####.',
        '##.##',
        '.####',
        '..###',
        '#####',
      ],
      // Small — keep asymmetry as the identifier.
      small: [
        '.##..',
        '####.',
        '.####',
        '#####',
      ],
      mini: '♞',
    ),

    // BISHOP — cleft mitre with visible GAP at tip + uniquely thin
    // 1-pixel-wide neck. The visible cleft (column 3 = empty) splits
    // the mitre into two ears — no other piece has a hole in its body.
    Role.bishop: PieceSprite(
      // 7×12 xlarge — tip, cleft (with REAL gap), mitre, thin neck,
      // shoulder, base.
      xlarge: [
        '.......',
        '...#...',
        '..#.#..',
        '.##.##.',
        '.#####.',
        '.#####.',
        '...#...',
        '...#...',
        '...#...',
        '..###..',
        '.#####.',
        '#######',
      ],
      // 5×8 extended — cleft top, mitre body, 1-px-wide neck, base.
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
      compact: [
        '.#.#.',
        '..#..',
        '..#..',
        '..#..',
        '.###.',
        '#####',
      ],
      // 5×4 small — cleft at top, base.
      small: [
        '.#.#.',
        '..#..',
        '.###.',
        '#####',
      ],
      mini: '♝',
    ),

    // ROOK — multi-turret battlement, dead-straight column body, flat
    // wide base. Only piece with truly straight sides through entire
    // body (no curves anywhere).
    Role.rook: PieceSprite(
      // 7×12 xlarge — 4 tall turrets, battlement, tower column, base.
      xlarge: [
        '#.#.#.#',
        '#######',
        '#######',
        '.#####.',
        '.#####.',
        '.#####.',
        '.#####.',
        '.#####.',
        '.#####.',
        '#######',
        '#######',
        '#######',
      ],
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
      // 5×4 small — turret tops + battlement, flared base.
      small: [
        '#.#.#',
        '#####',
        '.###.',
        '#####',
      ],
      mini: '♜',
    ),

    // QUEEN — multi-spike crown + curving shoulders that flare wider
    // at the top of every row pair. Only piece whose body silhouette
    // CURVES (▀███▀ vs rook's ` ███ ` straight).
    Role.queen: PieceSprite(
      // 7×12 xlarge — 4-spike crown, curving body, base.
      xlarge: [
        '.......',
        '#.#.#.#',
        '.#.#.#.',
        '#######',
        '.#####.',
        '#######',
        '.#####.',
        '.#####.',
        '.#####.',
        '.#####.',
        '#######',
        '#######',
      ],
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
        '.###.',
        '#####',
        '.###.',
        '#####',
        '#####',
      ],
      // 5×4 small — 3-spike crown + solid wide base (distinct from
      // rook's flared 5-spike).
      small: [
        '#.#.#',
        '.###.',
        '#####',
        '#####',
      ],
      mini: '♛',
    ),

    // KING — wide horizontal cross-bar wider than the body below it.
    // The crossbar (`▄▄█▄▄` family) is the ONLY top pattern with a
    // wide horizontal stripe.
    Role.king: PieceSprite(
      // 7×12 xlarge — cross tip, wide crossbar, crown, base.
      xlarge: [
        '.......',
        '...#...',
        '#######',
        '...#...',
        '...#...',
        '#######',
        '.#####.',
        '.#####.',
        '.#####.',
        '.#####.',
        '#######',
        '#######',
      ],
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
      compact: [
        '..#..',
        '#####',
        '..#..',
        '.###.',
        '.###.',
        '#####',
      ],
      // 5×4 small — wide cross top, flared base.
      small: [
        '..#..',
        '#####',
        '.###.',
        '#####',
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
  /// Results are cached by source identity — each board redraw calls
  /// this 32 times (one per piece), so memoizing the encoded rows
  /// removes per-cell string allocation from the hot path.
  static final Map<List<String>, List<String>> _renderCache =
      <List<String>, List<String>>{};

  static List<String> halfBlockRows(List<String> pixels) {
    final cached = _renderCache[pixels];
    if (cached != null) return cached;
    assert(pixels.length.isEven, 'sprite must have even row count');
    final rows = <String>[];
    for (var i = 0; i < pixels.length; i += 2) {
      rows.add(pair(pixels[i], pixels[i + 1]));
    }
    final immutable = List<String>.unmodifiable(rows);
    _renderCache[pixels] = immutable;
    return immutable;
  }
}
