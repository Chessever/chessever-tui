import 'package:chessever_tui/play/pieces.dart';
import 'package:chessever_tui/theme/colors.dart';
import 'package:dartchess/dartchess.dart';
import 'package:nocterm/nocterm.dart' hide Position;

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
    required this.onCellTap,
  });

  final Position position;
  final Square cursor;
  final Square? selected;
  final Set<Square> legalTargets;
  final Square? lastMoveFrom;
  final Square? lastMoveTo;
  final Square? checkSquare;
  final bool flipped;
  final ValueChanged<Square> onCellTap;

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
          '╭${'─' * (8 * 7)}╮',
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
          '╰${'─' * (8 * 7)}╯',
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
      height: 4,
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
          width: 7,
          child: Text(
            '   $char   ',
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
      bg = isLight
          ? ChesseverColors.lastMoveLight
          : ChesseverColors.lastMoveDark;
    }
    if (sq == selected) {
      bg = ChesseverColors.primary;
    }
    if (sq == checkSquare) {
      bg = ChesseverColors.checkGlow;
    }

    final isCursor = sq == cursor;
    final isLegalTarget = legalTargets.contains(sq);
    final isCaptureTarget = isLegalTarget && piece != null;

    final pieceFg = piece == null
        ? bg
        : (piece.color == Side.white
            ? ChesseverColors.white
            : const Color.fromRGB(0x10, 0x10, 0x12));

    final spriteRows = piece == null
        ? const ['     ', '     ', '     ', '     ']
        : PieceSprite.forRole(piece.role).rows;

    // Apply markers onto the sprite rows.
    final rows = List<String>.from(spriteRows);
    if (isLegalTarget && piece == null) {
      rows[2] = _stamp(rows[2], 2, '•');
    }

    final lines = <Component>[];
    for (var i = 0; i < 4; i++) {
      // Cursor halo: chevrons in top-corners of row 0 and bottom-corners of
      // row 3. Pads to 7 chars so cell width is exact.
      var line = ' ${rows[i]} '; // 7 chars
      if (isCursor) {
        if (i == 0) line = _stamp(_stamp(line, 0, '▟'), 6, '▙');
        if (i == 3) line = _stamp(_stamp(line, 0, '▜'), 6, '▛');
      }
      Color fg = pieceFg;
      if (isCursor && (i == 0 || i == 3)) {
        fg = ChesseverColors.cursorRing;
      }
      if (isCaptureTarget && i == 0) {
        line = _stamp(line, 0, '▟');
        line = _stamp(line, 6, '▙');
        fg = ChesseverColors.captureRing;
      }
      if (isCaptureTarget && i == 3) {
        line = _stamp(line, 0, '▜');
        line = _stamp(line, 6, '▛');
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
        width: 7,
        height: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines,
        ),
      ),
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
}
