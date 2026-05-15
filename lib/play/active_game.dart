import 'dart:async';

import 'package:chessever_tui/engine/maia_engine.dart';
import 'package:chessever_tui/play/board.dart';
import 'package:chessever_tui/play/play_pane.dart';
import 'package:chessever_tui/theme/colors.dart';
import 'package:dartchess/dartchess.dart';
import 'package:nocterm/nocterm.dart' hide Position;

class ActiveGameView extends StatefulComponent {
  const ActiveGameView({
    super.key,
    required this.config,
    required this.engine,
    required this.engineLabel,
    required this.onExit,
  });

  final PlayConfig config;
  final ChessEngine engine;
  final String engineLabel;
  final VoidCallback onExit;

  @override
  State<ActiveGameView> createState() => _ActiveGameViewState();
}

class _ActiveGameViewState extends State<ActiveGameView> {
  late Position _position;
  final List<String> _historyUci = [];
  final List<String> _historySan = [];
  final List<Piece> _capturedByWhite = [];
  final List<Piece> _capturedByBlack = [];

  Square _cursor = Square.e4;
  Square? _selected;
  Set<Square> _legalTargets = <Square>{};
  Square? _lastMoveFrom;
  Square? _lastMoveTo;
  bool _engineThinking = false;
  bool _flipped = false;
  String? _resultText;

  @override
  void initState() {
    super.initState();
    _position = Chess.initial;
    _flipped = component.config.humanSide == Side.black;
    _cursor =
        component.config.humanSide == Side.white ? Square.e2 : Square.e7;
    if (component.config.humanSide == Side.black) {
      scheduleMicrotask(_runEngine);
    }
  }

  @override
  void dispose() {
    component.engine.dispose();
    super.dispose();
  }

  bool get _humanToMove =>
      _resultText == null && _position.turn == component.config.humanSide;

  Square? _checkSquare() {
    if (!_position.isCheck) return null;
    return _position.board.kingOf(_position.turn);
  }

  Future<void> _runEngine() async {
    if (_resultText != null) return;
    setState(() => _engineThinking = true);
    final fen = _position.fen;
    final uci = await component.engine
        .bestMove(fen: fen, moveTime: const Duration(milliseconds: 800));
    if (!mounted) return;
    if (uci == null) {
      _finalize();
      return;
    }
    final move = NormalMove.fromUci(uci);
    _applyMove(move);
    setState(() => _engineThinking = false);
  }

  void _applyMove(NormalMove move) {
    final san = _position.makeSan(move).$2;
    final captured = _position.board.pieceAt(move.to);
    final after = _position.playUnchecked(move);
    setState(() {
      if (captured != null) {
        if (captured.color == Side.white) {
          _capturedByBlack.add(captured);
        } else {
          _capturedByWhite.add(captured);
        }
      }
      _position = after;
      _historyUci.add(move.uci);
      _historySan.add(san);
      _lastMoveFrom = move.from;
      _lastMoveTo = move.to;
      _selected = null;
      _legalTargets = <Square>{};
    });
    if (_position.isGameOver) {
      _finalize();
    } else if (_position.turn != component.config.humanSide) {
      unawaited(_runEngine());
    }
  }

  void _finalize() {
    final outcome = _position.outcome;
    setState(() {
      if (outcome == null) {
        _resultText = 'Game over';
      } else if (outcome.winner == null) {
        _resultText = 'Draw';
      } else {
        _resultText = outcome.winner == component.config.humanSide
            ? 'You won'
            : 'Maia won';
      }
    });
  }

  void _selectOrMove(Square sq) {
    if (!_humanToMove) return;
    if (_selected == null) {
      final piece = _position.board.pieceAt(sq);
      if (piece == null || piece.color != _position.turn) return;
      final legal = makeLegalMoves(_position)[sq];
      if (legal == null || legal.isEmpty) return;
      setState(() {
        _selected = sq;
        _legalTargets = legal.toSet();
      });
      return;
    }
    if (sq == _selected) {
      setState(() {
        _selected = null;
        _legalTargets = <Square>{};
      });
      return;
    }
    if (_legalTargets.contains(sq)) {
      final piece = _position.board.pieceAt(_selected!);
      Role? promotion;
      if (piece?.role == Role.pawn &&
          (sq.rank == Rank.first || sq.rank == Rank.eighth)) {
        promotion = Role.queen;
      }
      _applyMove(NormalMove(from: _selected!, to: sq, promotion: promotion));
      return;
    }
    final piece = _position.board.pieceAt(sq);
    if (piece != null && piece.color == _position.turn) {
      final legal = makeLegalMoves(_position)[sq];
      setState(() {
        _selected = sq;
        _legalTargets = legal?.toSet() ?? <Square>{};
      });
    }
  }

  bool _onKey(KeyboardEvent event) {
    final ch = event.character?.toLowerCase();
    if (ch == 'q') {
      component.onExit();
      return true;
    }
    if (ch == 'f') {
      setState(() => _flipped = !_flipped);
      return true;
    }
    if (ch == 'r') {
      component.onExit();
      return true;
    }
    if (event.logicalKey == LogicalKey.escape) {
      setState(() {
        _selected = null;
        _legalTargets = <Square>{};
      });
      return true;
    }
    if (event.logicalKey == LogicalKey.arrowUp) {
      _moveCursor(0, _flipped ? -1 : 1);
      return true;
    }
    if (event.logicalKey == LogicalKey.arrowDown) {
      _moveCursor(0, _flipped ? 1 : -1);
      return true;
    }
    if (event.logicalKey == LogicalKey.arrowLeft) {
      _moveCursor(_flipped ? 1 : -1, 0);
      return true;
    }
    if (event.logicalKey == LogicalKey.arrowRight) {
      _moveCursor(_flipped ? -1 : 1, 0);
      return true;
    }
    if (event.logicalKey == LogicalKey.space ||
        event.logicalKey == LogicalKey.enter ||
        event.character == ' ') {
      _selectOrMove(_cursor);
      return true;
    }
    return false;
  }

  void _moveCursor(int df, int dr) {
    final f = (_cursor.file + df).clamp(0, 7);
    final r = (_cursor.rank + dr).clamp(0, 7);
    setState(() {
      _cursor = Square.fromCoords(File(f), Rank(r));
    });
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: _onKey,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BoardView(
              position: _position,
              cursor: _cursor,
              selected: _selected,
              legalTargets: _legalTargets,
              lastMoveFrom: _lastMoveFrom,
              lastMoveTo: _lastMoveTo,
              flipped: _flipped,
              checkSquare: _checkSquare(),
              onCellTap: _selectOrMove,
            ),
            const SizedBox(width: 2),
            Expanded(child: _sidePanel()),
          ],
        ),
      ),
    );
  }

  Component _sidePanel() {
    return Container(
      decoration: BoxDecoration(
        color: ChesseverColors.black2,
        border: BoxBorder.all(
          color: ChesseverColors.divider,
          style: BoxBorderStyle.rounded,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 1),
          _capturesBlock(),
          const SizedBox(height: 1),
          _statusBlock(),
          const SizedBox(height: 1),
          _movesBlock(),
          const SizedBox(height: 1),
          _hints(),
        ],
      ),
    );
  }

  Component _header() {
    final side = component.config.humanSide == Side.white ? 'White' : 'Black';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('▲ ', style: TextStyle(color: ChesseverColors.primary)),
            Text('You',
                style: TextStyle(
                  color: ChesseverColors.white,
                  fontWeight: FontWeight.bold,
                )),
            Text('   $side',
                style: TextStyle(color: ChesseverColors.secondaryText)),
          ],
        ),
        Row(
          children: [
            Text('▽ ',
                style: TextStyle(color: ChesseverColors.captureRing)),
            Text('Maia ${component.config.elo}',
                style: TextStyle(
                  color: ChesseverColors.white,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
        Text(component.engineLabel,
            style: TextStyle(color: ChesseverColors.tertiaryText)),
      ],
    );
  }

  Component _capturesBlock() {
    String glyphs(List<Piece> caps) {
      const map = {
        Role.pawn: '♟',
        Role.knight: '♞',
        Role.bishop: '♝',
        Role.rook: '♜',
        Role.queen: '♛',
        Role.king: '♚',
      };
      return caps.map((p) => map[p.role]!).join(' ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('captures',
            style: TextStyle(color: ChesseverColors.secondaryText)),
        Row(children: [
          Text('▲ ', style: TextStyle(color: ChesseverColors.primary)),
          Text(
            glyphs(_capturedByWhite).isEmpty ? '—' : glyphs(_capturedByWhite),
            style: TextStyle(color: ChesseverColors.white),
          ),
        ]),
        Row(children: [
          Text('▽ ',
              style: TextStyle(color: ChesseverColors.captureRing)),
          Text(
            glyphs(_capturedByBlack).isEmpty ? '—' : glyphs(_capturedByBlack),
            style: TextStyle(color: ChesseverColors.white),
          ),
        ]),
      ],
    );
  }

  Component _statusBlock() {
    String status;
    Color color;
    if (_resultText != null) {
      status = _resultText!;
      color = ChesseverColors.lightYellow;
    } else if (_engineThinking) {
      status = 'Maia is thinking…';
      color = ChesseverColors.activeCalendar;
    } else if (_position.isCheck) {
      status = 'Check!';
      color = ChesseverColors.checkGlow;
    } else if (_humanToMove) {
      status = 'Your move';
      color = ChesseverColors.green2;
    } else {
      status = 'Waiting…';
      color = ChesseverColors.secondaryText;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: ChesseverColors.black3),
      child: Text(' $status ',
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Component _movesBlock() {
    final pairs = <String>[];
    for (var i = 0; i < _historySan.length; i += 2) {
      final moveNumber = (i ~/ 2) + 1;
      final w = _historySan[i];
      final b = (i + 1 < _historySan.length) ? _historySan[i + 1] : '';
      pairs.add('${moveNumber.toString().padLeft(2)}. ${w.padRight(7)} $b');
    }
    final tail =
        pairs.length > 8 ? pairs.sublist(pairs.length - 8) : pairs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('moves',
            style: TextStyle(color: ChesseverColors.secondaryText)),
        if (tail.isEmpty)
          Text('—', style: TextStyle(color: ChesseverColors.tertiaryText)),
        for (final line in tail)
          Text(line, style: TextStyle(color: ChesseverColors.white70)),
      ],
    );
  }

  Component _hints() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('←→↑↓  cursor',
            style: TextStyle(color: ChesseverColors.tertiaryText)),
        Text('space select / move',
            style: TextStyle(color: ChesseverColors.tertiaryText)),
        Text('f     flip board',
            style: TextStyle(color: ChesseverColors.tertiaryText)),
        Text('r     resign / new',
            style: TextStyle(color: ChesseverColors.tertiaryText)),
        Text('q     quit app',
            style: TextStyle(color: ChesseverColors.tertiaryText)),
      ],
    );
  }
}
