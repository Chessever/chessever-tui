import 'dart:async';

import 'package:chessever_tui/play/board.dart';
import 'package:chessever_tui/theme/colors.dart';
import 'package:chessever_tui/watch/broadcasts_repository.dart';
import 'package:chessever_tui/watch/models.dart';
import 'package:dartchess/dartchess.dart';
import 'package:nocterm/nocterm.dart' hide Position;

class GameViewer extends StatefulComponent {
  const GameViewer({
    super.key,
    required this.repo,
    required this.round,
    required this.initial,
    required this.onBack,
  });

  final BroadcastsRepository repo;
  final RoundLite round;
  final GameSnapshot initial;
  final VoidCallback onBack;

  @override
  State<GameViewer> createState() => _GameViewerState();
}

class _GameViewerState extends State<GameViewer> {
  late GameSnapshot _game;
  StreamSubscription<List<GameSnapshot>>? _sub;
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    _game = component.initial;
    _sub = component.repo.subscribeGamesByRound(component.round.id).listen(
      (games) {
        if (!mounted) return;
        for (final g in games) {
          if (g.id == _game.id) {
            setState(() => _game = g);
            return;
          }
        }
      },
      onError: (_) {/* stream errors are transient */},
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  bool _onKey(KeyboardEvent event) {
    final ch = event.character;
    if (event.logicalKey == LogicalKey.escape ||
        ch == 'b' ||
        ch == 'B') {
      component.onBack();
      return true;
    }
    if (ch == 'f' || ch == 'F') {
      setState(() => _flipped = !_flipped);
      return true;
    }
    return false;
  }

  Position? _parsePosition() {
    final fen = _game.fen;
    if (fen == null || fen.trim().isEmpty) return null;
    try {
      return Chess.fromSetup(Setup.parseFen(fen));
    } catch (_) {
      return null;
    }
  }

  ({Square? from, Square? to}) _parseLastMove() {
    final lm = _game.lastMove;
    if (lm == null || lm.length < 4) return (from: null, to: null);
    try {
      final from = Square.fromName(lm.substring(0, 2));
      final to = Square.fromName(lm.substring(2, 4));
      return (from: from, to: to);
    } catch (_) {
      return (from: null, to: null);
    }
  }

  @override
  Component build(BuildContext context) {
    final pos = _parsePosition();
    final lm = _parseLastMove();
    Square? checkSquare;
    if (pos != null && pos.isCheck) {
      final kingSquare = pos.board.kingOf(pos.turn);
      checkSquare = kingSquare;
    }

    return Focusable(
      focused: true,
      onKeyEvent: _onKey,
      child: Container(
        color: ChesseverColors.background,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final density = _pickDensity(constraints);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(game: _game, round: component.round),
                Expanded(
                  child: pos == null
                      ? _missingFen()
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 2, vertical: 1),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BoardView(
                                position: pos,
                                cursor: Square.a1,
                                selected: null,
                                legalTargets: const <Square>{},
                                lastMoveFrom: lm.from,
                                lastMoveTo: lm.to,
                                flipped: _flipped,
                                checkSquare: checkSquare,
                                density: density,
                                onCellMouse: (_, __) {},
                              ),
                              const SizedBox(width: 2),
                              Expanded(child: _SidePanel(game: _game)),
                            ],
                          ),
                        ),
                ),
                const _Footer(),
              ],
            );
          },
        ),
      ),
    );
  }

  Component _missingFen() => Container(
        padding: const EdgeInsets.all(2),
        child: Text(
          'waiting for first position…',
          style: TextStyle(color: ChesseverColors.secondaryText),
        ),
      );

  BoardDensity _pickDensity(BoxConstraints c) {
    final w = c.maxWidth;
    final h = c.maxHeight;
    if (w >= 80 && h >= 36) return BoardDensity.full;
    if (w >= 70 && h >= 28) return BoardDensity.compact;
    if (w >= 50 && h >= 20) return BoardDensity.small;
    return BoardDensity.mini;
  }
}

String _formatClock(int? ms) {
  if (ms == null || ms < 0) return '--:--';
  final total = ms ~/ 1000;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  String two(int n) => n < 10 ? '0$n' : '$n';
  if (h > 0) return '${two(h)}:${two(m)}:${two(s)}';
  return '${two(m)}:${two(s)}';
}

class _Header extends StatelessComponent {
  const _Header({required this.game, required this.round});
  final GameSnapshot game;
  final RoundLite round;

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        border: BoxBorder(
          bottom: BorderSide(color: ChesseverColors.divider),
        ),
      ),
      child: Row(
        children: [
          Text('esc back   ',
              style: TextStyle(color: ChesseverColors.tertiaryText)),
          Text(
            '${game.white?.displayName ?? '?'}  vs  ${game.black?.displayName ?? '?'}',
            style: TextStyle(
              color: ChesseverColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 2),
          Text(round.name,
              style: TextStyle(color: ChesseverColors.secondaryText)),
          const Spacer(),
          if (game.isLive)
            Text(
              ' ◉ LIVE ',
              style: TextStyle(
                color: ChesseverColors.white,
                backgroundColor: ChesseverColors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessComponent {
  const _Footer();

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        'f flip   esc back',
        style: TextStyle(color: ChesseverColors.tertiaryText),
      ),
    );
  }
}

class _SidePanel extends StatelessComponent {
  const _SidePanel({required this.game});
  final GameSnapshot game;

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _playerLine(game.black, isWhite: false),
          const SizedBox(height: 1),
          _meta(),
          const SizedBox(height: 1),
          _playerLine(game.white, isWhite: true),
        ],
      ),
    );
  }

  Component _playerLine(GamePlayer? p, {required bool isWhite}) {
    final clockMs = isWhite ? game.lastClockWhite : game.lastClockBlack;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
      decoration: BoxDecoration(
        color: ChesseverColors.black2,
        border: BoxBorder.all(
          color: ChesseverColors.divider,
          style: BoxBorderStyle.rounded,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isWhite ? '♔ ' : '♚ ',
                style: TextStyle(
                  color: isWhite
                      ? ChesseverColors.white
                      : ChesseverColors.blackPiece,
                ),
              ),
              Expanded(
                child: Text(
                  p?.displayName ?? '?',
                  style: TextStyle(color: ChesseverColors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (p != null && p.rating > 0)
                Text(' ${p.rating}',
                    style: TextStyle(color: ChesseverColors.secondaryText)),
              const Spacer(),
              Text(
                _formatClock(clockMs),
                style: TextStyle(
                  color: ChesseverColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Component _meta() {
    final lines = <Component>[];
    if (game.openingName != null) {
      lines.add(Text(
        game.openingName!,
        style: TextStyle(color: ChesseverColors.secondaryText),
        overflow: TextOverflow.ellipsis,
      ));
    }
    if (game.eco != null) {
      lines.add(Text(
        'eco ${game.eco!}',
        style: TextStyle(color: ChesseverColors.tertiaryText),
      ));
    }
    if (game.lastMove != null) {
      lines.add(Text(
        'last: ${game.lastMove!}',
        style: TextStyle(color: ChesseverColors.tertiaryText),
      ));
    }
    if (game.status != null && game.status != '*') {
      lines.add(Text(
        'result: ${game.status!}',
        style: TextStyle(color: ChesseverColors.lightYellow),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines,
    );
  }
}
