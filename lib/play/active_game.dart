import 'dart:async';

import 'package:chessever_tui/audio/sfx.dart';
import 'package:chessever_tui/engine/maia_engine.dart';
import 'package:chessever_tui/play/board.dart';
import 'package:chessever_tui/play/play_config.dart';
import 'package:chessever_tui/settings/settings_model.dart';
import 'package:chessever_tui/theme/colors.dart';
import 'package:dartchess/dartchess.dart';
import 'package:nocterm/nocterm.dart' hide Position;

class ActiveGameView extends StatefulComponent {
  const ActiveGameView({
    super.key,
    required this.config,
    required this.engine,
    required this.engineLabel,
    required this.settings,
    required this.onExit,
  });

  final PlayConfig config;
  final ChessEngine engine;
  final String engineLabel;
  final ChesseverSettings settings;
  final VoidCallback onExit;

  @override
  State<ActiveGameView> createState() => _ActiveGameViewState();
}

class _ActiveGameViewState extends State<ActiveGameView>
    with TickerProviderStateMixin {
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
  late Duration _whiteRemaining;
  late Duration _blackRemaining;
  Timer? _clockTimer;
  DateTime? _lastClockTick;

  bool _mouseDown = false;
  Square? _pressedAt;
  Square? _dragOver;
  bool _draggingActive = false;

  late final AnimationController _moveFlash;
  late final AnimationController _checkPulse;
  late final AnimationController _selectPulse;

  @override
  void initState() {
    super.initState();
    _position = Chess.initial;
    _whiteRemaining = component.config.timeControl.initial;
    _blackRemaining = component.config.timeControl.initial;
    _flipped = component.config.humanSide == Side.black;
    _cursor = component.config.humanSide == Side.white ? Square.e2 : Square.e7;
    _moveFlash = AnimationController(
      duration: const Duration(milliseconds: 360),
      vsync: this,
    );
    _checkPulse = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _selectPulse = AnimationController(
      duration: const Duration(milliseconds: 520),
      vsync: this,
    );
    SfxPlayer.instance.preload();
    _startClock();
    if (component.config.humanSide == Side.black) {
      scheduleMicrotask(_runEngine);
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _moveFlash.dispose();
    _checkPulse.dispose();
    _selectPulse.dispose();
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
    _syncClock();
    if (_resultText != null) return;
    final mover = _position.turn;
    final san = _position.makeSan(move).$2;
    final captured = _position.board.pieceAt(move.to);
    final moverPiece = _position.board.pieceAt(move.from);
    final isCastle = moverPiece?.role == Role.king &&
        (move.from.file - move.to.file).abs() == 2;
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
      _addIncrement(mover);
      _historyUci.add(move.uci);
      _historySan.add(san);
      _lastMoveFrom = move.from;
      _lastMoveTo = move.to;
      _selected = null;
      _legalTargets = <Square>{};
    });
    _moveFlash.forward(from: 0).whenComplete(() {
      if (mounted) _moveFlash.value = 0;
    });
    _playMoveSfx(
      captured: captured != null,
      castle: isCastle,
      promotion: move.promotion != null,
    );
    if (_position.isGameOver) {
      _finalize();
    } else {
      if (_position.isCheck) {
        _checkPulse.repeat(reverse: true, period: const Duration(milliseconds: 700));
        SfxPlayer.instance.play(Sfx.check);
      } else {
        _checkPulse.stop();
        _checkPulse.value = 0;
      }
      if (_position.turn != component.config.humanSide) {
        unawaited(_runEngine());
      }
    }
  }

  void _playMoveSfx({
    required bool captured,
    required bool castle,
    required bool promotion,
  }) {
    if (castle) {
      SfxPlayer.instance.play(Sfx.castle);
    } else if (promotion) {
      SfxPlayer.instance.play(Sfx.promotion);
    } else if (captured) {
      SfxPlayer.instance.play(Sfx.capture);
    } else {
      SfxPlayer.instance.play(Sfx.move);
    }
  }

  void _finalize() {
    _clockTimer?.cancel();
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
    _checkPulse.stop();
    if (outcome?.winner == null) {
      SfxPlayer.instance.play(Sfx.draw);
    } else {
      SfxPlayer.instance.play(Sfx.checkmate);
    }
  }

  void _startClock() {
    _lastClockTick = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted || _resultText != null) return;
      _syncClock();
    });
  }

  void _syncClock() {
    final now = DateTime.now();
    final last = _lastClockTick ?? now;
    _lastClockTick = now;
    if (_resultText != null) return;
    final elapsed = now.difference(last);
    if (elapsed <= Duration.zero) return;

    final turn = _position.turn;
    setState(() {
      if (turn == Side.white) {
        _whiteRemaining -= elapsed;
        if (_whiteRemaining <= Duration.zero) _flag(Side.white);
      } else {
        _blackRemaining -= elapsed;
        if (_blackRemaining <= Duration.zero) _flag(Side.black);
      }
    });
  }

  void _addIncrement(Side side) {
    final increment = component.config.timeControl.increment;
    if (increment == Duration.zero) return;
    if (side == Side.white) {
      _whiteRemaining += increment;
    } else {
      _blackRemaining += increment;
    }
  }

  void _flag(Side side) {
    _clockTimer?.cancel();
    final humanFlagged = side == component.config.humanSide;
    _resultText = humanFlagged ? 'You flagged' : 'Maia flagged';
    if (side == Side.white) {
      _whiteRemaining = Duration.zero;
    } else {
      _blackRemaining = Duration.zero;
    }
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
      _selectPulse.repeat(reverse: true, period: const Duration(milliseconds: 520));
      return;
    }
    if (sq == _selected) {
      setState(() {
        _selected = null;
        _legalTargets = <Square>{};
      });
      _selectPulse.stop();
      _selectPulse.value = 0;
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

  void _onCellMouse(Square sq, MouseEvent e) {
    if (!_humanToMove) return;
    final pressed = e.pressed || e.isPrimaryButtonDown;

    if (pressed && !_mouseDown) {
      _mouseDown = true;
      _pressedAt = sq;
      _draggingActive = false;
      return;
    }
    if (_mouseDown && pressed) {
      if (sq != _pressedAt && !_draggingActive) {
        final originPiece = _position.board.pieceAt(_pressedAt!);
        if (originPiece != null && originPiece.color == _position.turn) {
          _draggingActive = true;
          _enterDragMode(_pressedAt!);
        }
      }
      if (_draggingActive && _dragOver != sq) {
        setState(() => _dragOver = sq);
      }
      return;
    }
    if (_mouseDown && !pressed) {
      _mouseDown = false;
      final origin = _pressedAt;
      final wasDragging = _draggingActive;
      _pressedAt = null;
      _draggingActive = false;
      if (_dragOver != null) setState(() => _dragOver = null);
      if (origin == null) return;
      if (wasDragging) {
        _completeDrag(origin, sq);
      } else {
        _selectOrMove(origin);
      }
    }
  }

  void _enterDragMode(Square origin) {
    final piece = _position.board.pieceAt(origin);
    if (piece == null || piece.color != _position.turn) return;
    final legal = makeLegalMoves(_position)[origin];
    if (legal == null || legal.isEmpty) return;
    setState(() {
      _selected = origin;
      _legalTargets = legal.toSet();
      _dragOver = origin;
    });
    _selectPulse.repeat(
      reverse: true,
      period: const Duration(milliseconds: 520),
    );
  }

  void _completeDrag(Square origin, Square releaseSq) {
    if (_selected == origin && _legalTargets.contains(releaseSq)) {
      final piece = _position.board.pieceAt(origin);
      Role? promotion;
      if (piece?.role == Role.pawn &&
          (releaseSq.rank == Rank.first || releaseSq.rank == Rank.eighth)) {
        promotion = Role.queen;
      }
      _applyMove(NormalMove(from: origin, to: releaseSq, promotion: promotion));
    } else {
      setState(() {
        _selected = null;
        _legalTargets = <Square>{};
      });
      _selectPulse.stop();
      _selectPulse.value = 0;
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
    if (ch == 'n' || ch == 'r') {
      component.onExit();
      return true;
    }
    if (event.logicalKey == LogicalKey.escape) {
      setState(() {
        _selected = null;
        _legalTargets = <Square>{};
      });
      _selectPulse.stop();
      _selectPulse.value = 0;
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final w = constraints.maxWidth;
          // Board footprint (board only, no side panel):
          //   full    8*7 + 4 = 60 cols, 8*3 + 3 = 27 rows
          //   compact 8*5 + 4 = 44 cols, 8*2 + 3 = 19 rows
          //   mini    8*3 + 4 = 28 cols, 8*1 + 3 = 11 rows
          final BoardDensity density;
          if (h >= 28 && w >= 60) {
            density = BoardDensity.full;
          } else if (h >= 20 && w >= 44) {
            density = BoardDensity.compact;
          } else {
            density = BoardDensity.mini;
          }
          final boardW = density == BoardDensity.full
              ? 64
              : density == BoardDensity.compact
                  ? 48
                  : 32;
          final wide = w >= boardW + 26;
          final compact = density != BoardDensity.full;
          final movesRows = density == BoardDensity.full
              ? (h ~/ 4).clamp(4, 12)
              : (density == BoardDensity.compact ? 4 : 2);
          final showSidePanel = density != BoardDensity.mini || h >= 14;

          final board = AnimatedBuilder(
            animation:
                Listenable.merge([_moveFlash, _checkPulse, _selectPulse]),
            builder: (context, _) => BoardView(
              position: _position,
              cursor: _cursor,
              selected: _selected,
              legalTargets: _legalTargets,
              lastMoveFrom: _lastMoveFrom,
              lastMoveTo: _lastMoveTo,
              flipped: _flipped,
              checkSquare: _checkSquare(),
              density: density,
              dragOrigin: _draggingActive ? _pressedAt : null,
              dragOver: _draggingActive ? _dragOver : null,
              moveFlash: _moveFlash.value,
              checkPulse: _checkPulse.value,
              selectPulse: _selectPulse.value,
              onCellMouse: _onCellMouse,
            ),
          );
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      board,
                      const SizedBox(width: 1),
                      Expanded(
                          child: _sidePanel(
                              compact: compact, movesRows: movesRows)),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        board,
                        if (showSidePanel) ...[
                          const SizedBox(height: 1),
                          _sidePanel(compact: true, movesRows: movesRows),
                        ],
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Component _sidePanel({required bool compact, required int movesRows}) {
    return Container(
      decoration: BoxDecoration(
        color: ChesseverColors.black2,
        border: BoxBorder.all(
          color: ChesseverColors.divider,
          style: BoxBorderStyle.rounded,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(compact: compact),
          const SizedBox(height: 1),
          _statusBlock(),
          if (!compact) ...[
            const SizedBox(height: 1),
            _capturesBlock(),
          ],
          const SizedBox(height: 1),
          _movesBlock(maxRows: movesRows),
          const SizedBox(height: 1),
          _hints(compact: compact),
        ],
      ),
    );
  }

  Component _header({required bool compact}) {
    final side = component.config.humanSide == Side.white ? 'White' : 'Black';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PixelFlag(color: component.settings.playerFlag.color),
            const SizedBox(width: 1),
            Text('You',
                style: TextStyle(
                  color: ChesseverColors.white,
                  fontWeight: FontWeight.bold,
                )),
            Text(' $side',
                style: TextStyle(color: ChesseverColors.secondaryText)),
            const Spacer(),
            Text(_clockFor(component.config.humanSide),
                style: TextStyle(color: ChesseverColors.primary)),
          ],
        ),
        Row(
          children: [
            const PixelFlag(color: ChesseverColors.white, pirate: true),
            const SizedBox(width: 1),
            Text('Maia ${component.config.elo}',
                style: TextStyle(
                  color: ChesseverColors.white,
                  fontWeight: FontWeight.bold,
                )),
            const Spacer(),
            Text(_clockFor(component.config.humanSide.opposite),
                style: TextStyle(color: ChesseverColors.white70)),
          ],
        ),
        if (!compact)
          Text(
              '${component.config.timeControl.label} · ${component.engineLabel}',
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
          Text('▽ ', style: TextStyle(color: ChesseverColors.captureRing)),
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

  Component _movesBlock({required int maxRows}) {
    final pairs = <String>[];
    for (var i = 0; i < _historySan.length; i += 2) {
      final moveNumber = (i ~/ 2) + 1;
      final w = _historySan[i];
      final b = (i + 1 < _historySan.length) ? _historySan[i + 1] : '';
      pairs.add('${moveNumber.toString().padLeft(2)}. ${w.padRight(7)} $b');
    }
    final tail =
        pairs.length > maxRows ? pairs.sublist(pairs.length - maxRows) : pairs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('moves', style: TextStyle(color: ChesseverColors.secondaryText)),
        if (tail.isEmpty)
          Text('—', style: TextStyle(color: ChesseverColors.tertiaryText)),
        for (final line in tail)
          Text(line, style: TextStyle(color: ChesseverColors.white70)),
      ],
    );
  }

  Component _hints({required bool compact}) {
    final hints = compact
        ? const ['←→↑↓ cursor', 'space move', 'n new  q quit']
        : const [
            '←→↑↓  cursor',
            'space select / move',
            'f     flip board',
            'n     new setup',
            'q     quit game',
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final hint in hints)
          Text(hint, style: TextStyle(color: ChesseverColors.tertiaryText)),
      ],
    );
  }

  String _clockFor(Side side) {
    final duration = side == Side.white ? _whiteRemaining : _blackRemaining;
    final safe = duration.isNegative ? Duration.zero : duration;
    final minutes = safe.inMinutes.remainder(60).toString();
    final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
