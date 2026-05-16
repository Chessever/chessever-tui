import 'package:chessever_tui/play/pieces.dart';
import 'package:chessever_tui/theme/colors.dart';
import 'package:dartchess/dartchess.dart';
import 'package:nocterm/nocterm.dart' hide Position;

enum BoardDensity { full, compact }

/// Pixel-art chess board. 7×4 cells, 5-wide sprites with a one-column gutter
/// on each side, board-tinted last-move and selection highlights, plus a
/// cursor halo that surrounds the active square without obscuring the piece.
class BoardView extends StatelessComponent {
  const BoardView({
    super.key,
    required this.position,
    required this.cursor,
    required this.selected,
    required this.legalTargets,
    required this.lastMoveFrom,
    required this.lastMoveTo,
    required this.flipped,
    required this.checkSquare,
    this.density = BoardDensity.full,
    required this.onCellTap,
    this.moveFlash = 0,
    this.checkPulse = 0,
    this.selectPulse = 0,
  });

  final Position position;
  final Square cursor;
  final Square? selected;
  final Set<Square> legalTargets;
  final Square? lastMoveFrom;
  final Square? lastMoveTo;
  final Square? checkSquare;
  final bool flipped;
  final BoardDensity density;
  final ValueChanged<Square> onCellTap;
  final double moveFlash;
  final double checkPulse;
  final double selectPulse;

  int get _cellWidth => density == BoardDensity.full ? 7 : 5;
  int get _cellHeight => density == BoardDensity.full ? 4 : 2;
  int get _spriteWidth => density == BoardDensity.full ? 5 : 3;

  @override
  Component build(BuildContext context) {
    final children = <Component>[
      _topBorder(),
    ];
    for (var i = 0; i < 8; i++) {
      final rank = flipped ? i : 7 - i;
      children.add(_rankRow(rank));
    }
    children.add(_bottomBorder());
    children.add(_fileLabels());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Component _topBorder() {
    return Row(
      children: [
        const SizedBox(width: 2),
        Text(
          '╭${'─' * (8 * _cellWidth)}╮',
          style: TextStyle(color: ChesseverColors.divider),
        ),
      ],
    );
  }

  Component _bottomBorder() {
    return Row(
      children: [
        const SizedBox(width: 2),
        Text(
          '╰${'─' * (8 * _cellWidth)}╯',
          style: TextStyle(color: ChesseverColors.divider),
        ),
      ],
    );
  }

  Component _rankRow(int rank) {
    final cells = <Component>[];
    cells.add(_rankLabel(rank));
    cells.add(Text('│', style: TextStyle(color: ChesseverColors.divider)));
    for (var fi = 0; fi < 8; fi++) {
      final file = flipped ? 7 - fi : fi;
      final sq = Square.fromCoords(File(file), Rank(rank));
      cells.add(_cell(sq));
    }
    cells.add(Text('│', style: TextStyle(color: ChesseverColors.divider)));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: cells,
    );
  }

  Component _rankLabel(int rank) {
    return Container(
      width: 2,
      height: _cellHeight.toDouble(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            ' ${rank + 1}',
            style: TextStyle(color: ChesseverColors.tertiaryText),
          ),
        ],
      ),
    );
  }

  Component _fileLabels() {
    final labels = <Component>[
      const SizedBox(width: 3),
    ];
    for (var fi = 0; fi < 8; fi++) {
      final file = flipped ? 7 - fi : fi;
      final char = String.fromCharCode('a'.codeUnitAt(0) + file);
      labels.add(
        Container(
          width: _cellWidth.toDouble(),
          height: 1,
          child: Text(
            density == BoardDensity.full ? '   $char   ' : '  $char  ',
            style: TextStyle(color: ChesseverColors.tertiaryText),
          ),
        ),
      );
    }
    return Row(children: labels);
  }

  Component _cell(Square sq) {
    final piece = position.board.pieceAt(sq);
    final isLight = ((sq.file + sq.rank) % 2) == 1;
    final baseBg =
        isLight ? ChesseverColors.boardLight : ChesseverColors.boardDark;

    Color bg = baseBg;
    if (sq == lastMoveFrom || sq == lastMoveTo) {
      final lastBg = isLight
          ? ChesseverColors.lastMoveLight
          : ChesseverColors.lastMoveDark;
      if (sq == lastMoveTo && moveFlash > 0) {
        bg = _lerp(lastBg, ChesseverColors.primary, moveFlash * 0.75);
      } else {
        bg = lastBg;
      }
    }
    if (sq == selected) {
      bg = _lerp(
        ChesseverColors.primary,
        ChesseverColors.activeCalendar,
        selectPulse,
      );
    }
    if (sq == checkSquare) {
      bg = _lerp(
        ChesseverColors.checkGlow,
        ChesseverColors.red,
        checkPulse,
      );
    }

    final isCursor = sq == cursor;
    final isLegalTarget = legalTargets.contains(sq);
    final isCaptureTarget = isLegalTarget && piece != null;

    final emptyFg = isLight
        ? ChesseverColors.boardLightPixel
        : ChesseverColors.boardDarkPixel;

    Color baseFg = piece == null
        ? emptyFg
        : (piece.color == Side.white
            ? ChesseverColors.white
            : ChesseverColors.blackPiece);

    final spriteRows = piece == null
        ? (isLight ? _emptyRows('░') : _emptyRows('▒'))
        : (density == BoardDensity.full
            ? PieceSprite.forRole(piece.role).rows
            : PieceSprite.forRole(piece.role).compactRows);

    // Apply markers onto the sprite rows.
    final rows = List<String>.from(spriteRows);
    if (isLegalTarget && piece == null) {
      rows[density == BoardDensity.full ? 2 : 1] =
          _stamp(' ' * _spriteWidth, _spriteWidth ~/ 2, '•');
      baseFg = ChesseverColors.legalDot;
    }

    final lines = <Component>[];
    for (var i = 0; i < _cellHeight; i++) {
      // Cursor halo: chevrons in top-corners of row 0 and bottom-corners of
      // row 3. Pads to 7 chars so cell width is exact.
      var line = ' ${rows[i]} ';
      if (isCursor) {
        if (i == 0) {
          line = _stamp(_stamp(line, 0, '▟'), _cellWidth - 1, '▙');
        }
        if (i == _cellHeight - 1) {
          line = _stamp(_stamp(line, 0, '▜'), _cellWidth - 1, '▛');
        }
      }
      Color fg = baseFg;
      if (isCursor && (i == 0 || i == _cellHeight - 1)) {
        fg = ChesseverColors.cursorRing;
      }
      if (isCaptureTarget && i == 0) {
        line = _stamp(line, 0, '▟');
        line = _stamp(line, _cellWidth - 1, '▙');
        fg = ChesseverColors.captureRing;
      }
      if (isCaptureTarget && i == _cellHeight - 1) {
        line = _stamp(line, 0, '▜');
        line = _stamp(line, _cellWidth - 1, '▛');
        fg = ChesseverColors.captureRing;
      }
      lines.add(Text(
        line,
        style: TextStyle(color: fg, backgroundColor: bg),
      ));
    }

    return GestureDetector(
      onTap: () => onCellTap(sq),
      child: Container(
        width: _cellWidth.toDouble(),
        height: _cellHeight.toDouble(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines,
        ),
      ),
    );
  }

  Color _lerp(Color a, Color b, double t) {
    final tt = t.clamp(0.0, 1.0);
    int mix(int x, int y) => (x + (y - x) * tt).round().clamp(0, 255);
    return Color.fromRGB(
      mix(a.red, b.red),
      mix(a.green, b.green),
      mix(a.blue, b.blue),
    );
  }

  String _stamp(String line, int index, String char) {
    final units = line.runes.toList();
    if (index >= units.length) return line;
    final chRunes = char.runes.toList();
    if (chRunes.isEmpty) return line;
    units[index] = chRunes.first;
    return String.fromCharCodes(units);
  }

  List<String> _emptyRows(String pixel) {
    if (density == BoardDensity.full) {
      return ['$pixel   $pixel', '     ', '  $pixel  ', '     '];
    }
    return ['$pixel $pixel', ' $pixel '];
  }
}
