import 'dart:async';

import 'package:chessever_tui/theme/colors.dart';
import 'package:chessever_tui/watch/broadcasts_repository.dart';
import 'package:chessever_tui/watch/game_viewer.dart';
import 'package:chessever_tui/watch/models.dart';
import 'package:nocterm/nocterm.dart';

class RoundViewer extends StatefulComponent {
  const RoundViewer({
    super.key,
    required this.repo,
    required this.card,
    required this.onBack,
  });

  final BroadcastsRepository repo;
  final BroadcastCard card;
  final VoidCallback onBack;

  @override
  State<RoundViewer> createState() => _RoundViewerState();
}

class _RoundViewerState extends State<RoundViewer> {
  List<RoundLite> _rounds = const [];
  RoundLite? _selectedRound;
  GameSnapshot? _openedGame;
  List<GameSnapshot> _games = const [];
  StreamSubscription<List<GameSnapshot>>? _gamesSub;
  bool _loadingRounds = true;
  bool _loadingGames = false;
  String? _error;
  int _gameFocus = 0;
  int _roundFocus = 0;

  @override
  void initState() {
    super.initState();
    _loadRounds();
  }

  @override
  void dispose() {
    _gamesSub?.cancel();
    super.dispose();
  }

  Future<void> _loadRounds() async {
    try {
      final rounds = await component.repo
          .fetchRoundsForBroadcast(component.card.id);
      if (!mounted) return;
      setState(() {
        _rounds = rounds;
        _loadingRounds = false;
        _error = null;
        if (rounds.isNotEmpty) {
          _roundFocus = 0;
          _selectRound(rounds.first);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingRounds = false;
      });
    }
  }

  void _selectRound(RoundLite round) {
    _gamesSub?.cancel();
    setState(() {
      _selectedRound = round;
      _loadingGames = true;
      _games = const [];
      _gameFocus = 0;
    });
    _gamesSub = component.repo.subscribeGamesByRound(round.id).listen(
      (games) {
        if (!mounted) return;
        setState(() {
          _games = games;
          _loadingGames = false;
          if (_gameFocus >= games.length) _gameFocus = 0;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString();
          _loadingGames = false;
        });
      },
    );
  }

  bool _onKey(KeyboardEvent event) {
    if (_openedGame != null) return false;
    final key = event.logicalKey;
    final ch = event.character;
    if (key == LogicalKey.escape || ch == 'b' || ch == 'B') {
      component.onBack();
      return true;
    }
    if (_rounds.isEmpty) return false;
    if (ch == '[') {
      _cycleRound(-1);
      return true;
    }
    if (ch == ']') {
      _cycleRound(1);
      return true;
    }
    if (_games.isEmpty) return false;
    if (key == LogicalKey.arrowDown || ch == 'j') {
      setState(() => _gameFocus = (_gameFocus + 1) % _games.length);
      return true;
    }
    if (key == LogicalKey.arrowUp || ch == 'k') {
      setState(() =>
          _gameFocus = (_gameFocus + _games.length - 1) % _games.length);
      return true;
    }
    if (key == LogicalKey.enter || ch == ' ') {
      setState(() => _openedGame = _games[_gameFocus]);
      return true;
    }
    return false;
  }

  void _cycleRound(int delta) {
    if (_rounds.isEmpty) return;
    final next = (_roundFocus + delta + _rounds.length) % _rounds.length;
    setState(() => _roundFocus = next);
    _selectRound(_rounds[next]);
  }

  @override
  Component build(BuildContext context) {
    if (_openedGame != null && _selectedRound != null) {
      return GameViewer(
        repo: component.repo,
        round: _selectedRound!,
        initial: _openedGame!,
        onBack: () => setState(() => _openedGame = null),
      );
    }
    return Focusable(
      focused: true,
      onKeyEvent: _onKey,
      child: Container(
        color: ChesseverColors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(card: component.card, round: _selectedRound),
            Expanded(child: _body()),
            const _Footer(),
          ],
        ),
      ),
    );
  }

  Component _body() {
    if (_loadingRounds) return _msg('loading rounds…');
    if (_error != null) {
      return _msg('error: ${_error!}', isError: true);
    }
    if (_rounds.isEmpty) return _msg('no rounds yet for this broadcast.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _roundStrip(),
        const SizedBox(height: 1),
        Expanded(child: _gamesList()),
      ],
    );
  }

  Component _roundStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Text('rounds: ',
              style: TextStyle(color: ChesseverColors.tertiaryText)),
          for (var i = 0; i < _rounds.length && i < 12; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Text(
                _rounds[i].name.isEmpty ? '#${i + 1}' : _rounds[i].name,
                style: TextStyle(
                  color: i == _roundFocus
                      ? ChesseverColors.primary
                      : ChesseverColors.secondaryText,
                  fontWeight:
                      i == _roundFocus ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          if (_rounds.length > 12)
            Text(' +${_rounds.length - 12}',
                style: TextStyle(color: ChesseverColors.tertiaryText)),
        ],
      ),
    );
  }

  Component _gamesList() {
    if (_loadingGames) return _msg('loading games…');
    if (_games.isEmpty) return _msg('no games in this round.');
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _games.length; i++)
            _GameRow(game: _games[i], active: i == _gameFocus),
        ],
      ),
    );
  }

  Component _msg(String text, {bool isError = false}) {
    return Container(
      padding: const EdgeInsets.all(2),
      child: Text(
        text,
        style: TextStyle(
          color: isError ? ChesseverColors.red : ChesseverColors.secondaryText,
        ),
      ),
    );
  }
}

class _Header extends StatelessComponent {
  const _Header({required this.card, required this.round});

  final BroadcastCard card;
  final RoundLite? round;

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        border: BoxBorder(
          bottom: BorderSide(color: ChesseverColors.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('← ', style: TextStyle(color: ChesseverColors.tertiaryText)),
              Text('esc back   ',
                  style: TextStyle(color: ChesseverColors.tertiaryText)),
              Expanded(
                child: Text(
                  card.title,
                  style: TextStyle(
                    color: ChesseverColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (round != null)
            Text(
              'round: ${round!.name}',
              style: TextStyle(color: ChesseverColors.secondaryText),
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
        '[ ] cycle round   ↑↓/jk game   enter open   esc back',
        style: TextStyle(color: ChesseverColors.tertiaryText),
      ),
    );
  }
}

class _GameRow extends StatelessComponent {
  const _GameRow({required this.game, required this.active});

  final GameSnapshot game;
  final bool active;

  @override
  Component build(BuildContext context) {
    final bg = active ? ChesseverColors.black3 : null;
    final w = game.white;
    final b = game.black;
    final liveTint = game.isLive
        ? ChesseverColors.red
        : ChesseverColors.tertiaryText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: bg == null ? null : BoxDecoration(color: bg),
      child: Row(
        children: [
          Text(
            active ? '┃ ' : '  ',
            style: TextStyle(color: ChesseverColors.primary),
          ),
          Text(
            game.isLive ? '◉ ' : '○ ',
            style: TextStyle(color: liveTint),
          ),
          Expanded(
            child: Text(
              _line(w, b),
              style: TextStyle(
                color: ChesseverColors.white,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (game.openingName != null)
            Text(
              ' ${game.openingName!}',
              style: TextStyle(color: ChesseverColors.tertiaryText),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  static String _line(GamePlayer? w, GamePlayer? b) {
    String fmt(GamePlayer? p) {
      if (p == null) return '?';
      final rating = p.rating > 0 ? ' (${p.rating})' : '';
      return '${p.displayName}$rating';
    }
    return '${fmt(w)}   vs   ${fmt(b)}';
  }
}
