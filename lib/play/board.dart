import 'package:chessever_tui/play/pieces.dart';
import 'package:chessever_tui/theme/colors.dart';
import 'package:dartchess/dartchess.dart';
import 'package:nocterm/nocterm.dart' hide Position;

enum BoardDensity { full, compact, mini }

typedef CellMouseCallback = void Function(Square sq, MouseEvent event);

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
    required this.onCellMouse,
    this.dragOrigin,
    this.dragOver,
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
  final CellMouseCallback onCellMouse;
  final Square? dragOrigin;
  final Square? dragOver;
  final double moveFlash;
  final double checkPulse;
  final double selectPulse;

  int get _cellWidth => switch (density) {
        BoardDensity.full => 7,
        BoardDensity.compact => 5,
        BoardDensity.mini => 3,
      };

  int get _cellHeight => switch (density) {
        BoardDensity.full => 3,
        BoardDensity.compact => 2,
        BoardDensity.mini => 1,
      };

  int get _spriteWidth => switch (density) {
        BoardDensity.full => 5,
        BoardDensity.compact => 3,
        BoardDensity.mini => 1,
      };

  @override
  Component build(BuildContext context) {
    final children = <Component>[_topBorder()];
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

  Component _topBorder() => Row(
        children: [
          const SizedBox(width: 2),
          Text(
            '╭${'─' * (8 * _cellWidth)}╮',
            style: TextStyle(color: ChesseverColors.divider),
          ),
        ],
      );

  Component _bottomBorder() => Row(
        children: [
          const SizedBox(width: 2),
          Text(
            '╰${'─' * (8 * _cellWidth)}╯',
            style: TextStyle(color: ChesseverColors.divider),
          ),
        ],
      );

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

  Component _rankLabel(int rank) => Container(
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

  Component _fileLabels() {
    final labels = <Component>[const SizedBox(width: 3)];
    for (var fi = 0; fi < 8; fi++) {
      final file = flipped ? 7 - fi : fi;
      final char = String.fromCharCode('a'.codeUnitAt(0) + file);
      String label;
      switch (density) {
        case BoardDensity.full:
          label = '   $char   ';
          break;
        case BoardDensity.compact:
          label = '  $char  ';
          break;
        case BoardDensity.mini:
          label = ' $char ';
          break;
      }
      labels.add(
        Container(
          width: _cellWidth.toDouble(),
          height: 1,
          child: Text(
            label,
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
    if (sq == selected || sq == dragOrigin) {
      bg = _lerp(
        ChesseverColors.primary,
        ChesseverColors.activeCalendar,
        selectPulse,
      );
    }
    if (sq == dragOver && dragOrigin != null && sq != dragOrigin) {
      bg = _lerp(bg, ChesseverColors.activeCalendar, 0.65);
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
    final isDragSource = sq == dragOrigin;

    if (isCaptureTarget) {
      bg = _lerp(bg, ChesseverColors.captureRing, 0.4);
    }
    if (isCursor) {
      bg = _lerp(bg, ChesseverColors.cursorRing, 0.45);
    }

    Color baseFg = piece == null
        ? bg
        : (piece.color == Side.white
            ? ChesseverColors.white
            : ChesseverColors.blackPiece);

    if (isDragSource) {
      baseFg = _lerp(baseFg, bg, 0.45);
    }

    final spriteRows = _pieceRows(piece);

    final rows = List<String>.from(spriteRows);
    if (isLegalTarget && piece == null) {
      final markerRow = _cellHeight ~/ 2;
      if (markerRow < rows.length) {
        rows[markerRow] =
            _stamp(' ' * _spriteWidth, _spriteWidth ~/ 2, '•');
      }
      baseFg = ChesseverColors.legalDot;
    }

    final lines = <Component>[];
    for (var i = 0; i < _cellHeight; i++) {
      final line = density == BoardDensity.mini ? rows[i] : ' ${rows[i]} ';
      lines.add(Text(
        line,
        style: TextStyle(color: baseFg, backgroundColor: bg),
      ));
    }

    return MouseRegion(
      opaque: false,
      onEnter: (e) => onCellMouse(sq, e),
      onHover: (e) => onCellMouse(sq, e),
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

  List<String> _pieceRows(Piece? piece) {
    if (piece == null) {
      switch (density) {
        case BoardDensity.full:
          return _emptyRowsFull();
        case BoardDensity.compact:
          return _emptyRowsCompact();
        case BoardDensity.mini:
          return [' '];
      }
    }
    final sprite = PieceSprite.forRole(piece.role);
    switch (density) {
      case BoardDensity.full:
        return sprite.rows;
      case BoardDensity.compact:
        return sprite.compactRows;
      case BoardDensity.mini:
        return [sprite.mini];
    }
  }

  List<String> _emptyRowsFull() => const ['     ', '     ', '     '];

  List<String> _emptyRowsCompact() => const ['   ', '   '];

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
}
