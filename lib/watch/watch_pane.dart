import 'dart:async';

import 'package:chessever_tui/theme/colors.dart';
import 'package:chessever_tui/watch/broadcasts_repository.dart';
import 'package:chessever_tui/watch/models.dart';
import 'package:chessever_tui/watch/round_viewer.dart';
import 'package:nocterm/nocterm.dart';

class WatchPane extends StatefulComponent {
  const WatchPane({super.key});

  @override
  State<WatchPane> createState() => _WatchPaneState();
}

class _WatchPaneState extends State<WatchPane> {
  late final BroadcastsRepository _repo;
  List<BroadcastCard> _cards = const [];
  Set<String> _liveIds = const {};
  int _focus = 0;
  bool _loading = true;
  String? _error;
  BroadcastCard? _opened;
  StreamSubscription<List<String>>? _liveSub;

  @override
  void initState() {
    super.initState();
    _repo = BroadcastsRepository();
    _load();
    _liveSub = _repo.subscribeLiveGroupBroadcastIds().listen(
      (ids) {
        if (!mounted) return;
        setState(() {
          _liveIds = ids.toSet();
          _cards = _recategorize(_cards.map((c) => c.broadcast).toList());
        });
      },
      onError: (_) {/* tolerate transient stream errors */},
    );
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await _repo.fetchCurrent();
      if (!mounted) return;
      setState(() {
        _cards = _recategorize(list);
        _loading = false;
        _error = null;
        if (_focus >= _cards.length) _focus = 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<BroadcastCard> _recategorize(List<GroupBroadcast> source) {
    final now = DateTime.now();
    final cards = source
        .map((b) => BroadcastCard(
              broadcast: b,
              category: BroadcastCard.categorize(b, _liveIds, now),
            ))
        .toList();
    cards.sort((a, b) {
      // live first, then ongoing, then upcoming, then completed
      int rank(TourEventCategory c) => switch (c) {
            TourEventCategory.live => 0,
            TourEventCategory.ongoing => 1,
            TourEventCategory.upcoming => 2,
            TourEventCategory.completed => 3,
          };
      final byCat = rank(a.category).compareTo(rank(b.category));
      if (byCat != 0) return byCat;
      final ae = a.maxAvgElo ?? 0;
      final be = b.maxAvgElo ?? 0;
      return be.compareTo(ae);
    });
    return cards;
  }

  bool _onKey(KeyboardEvent event) {
    if (_opened != null) return false; // child pane has focus
    if (_cards.isEmpty) return false;
    final key = event.logicalKey;
    final ch = event.character;
    if (key == LogicalKey.arrowDown || ch == 'j') {
      setState(() => _focus = (_focus + 1) % _cards.length);
      return true;
    }
    if (key == LogicalKey.arrowUp || ch == 'k') {
      setState(() => _focus = (_focus + _cards.length - 1) % _cards.length);
      return true;
    }
    if (key == LogicalKey.enter || ch == ' ') {
      setState(() => _opened = _cards[_focus]);
      return true;
    }
    if (ch == 'r' || ch == 'R') {
      _load();
      return true;
    }
    return false;
  }

  @override
  Component build(BuildContext context) {
    if (_opened != null) {
      return RoundViewer(
        repo: _repo,
        card: _opened!,
        onBack: () => setState(() => _opened = null),
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
            const _WatchHeader(),
            Expanded(child: _body()),
            const _FooterHint(),
          ],
        ),
      ),
    );
  }

  Component _body() {
    if (_loading) {
      return _centerMessage('loading broadcasts…');
    }
    if (_error != null) {
      return _centerMessage(
        'feed offline.\n${_error!}\npress r to retry.',
        isError: true,
      );
    }
    if (_cards.isEmpty) {
      return _centerMessage('no live or current broadcasts.');
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _cards.length; i++)
            _BroadcastRow(
              card: _cards[i],
              active: i == _focus,
            ),
        ],
      ),
    );
  }

  Component _centerMessage(String message, {bool isError = false}) {
    return Container(
      padding: const EdgeInsets.all(2),
      child: Text(
        message,
        style: TextStyle(
          color: isError ? ChesseverColors.red : ChesseverColors.secondaryText,
        ),
      ),
    );
  }
}

class _WatchHeader extends StatelessComponent {
  const _WatchHeader();

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
          Text('◉  ', style: TextStyle(color: ChesseverColors.red)),
          Text(
            'WATCH',
            style: TextStyle(
              color: ChesseverColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            'live tournaments — broadcast by chessever',
            style: TextStyle(color: ChesseverColors.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _FooterHint extends StatelessComponent {
  const _FooterHint();

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        '↑↓/jk move   enter open   r refresh   esc/back returns',
        style: TextStyle(color: ChesseverColors.tertiaryText),
      ),
    );
  }
}

class _BroadcastRow extends StatelessComponent {
  const _BroadcastRow({required this.card, required this.active});

  final BroadcastCard card;
  final bool active;

  @override
  Component build(BuildContext context) {
    final bg = active ? ChesseverColors.black3 : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: bg == null ? null : BoxDecoration(color: bg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                active ? '┃ ' : '  ',
                style: TextStyle(color: ChesseverColors.primary),
              ),
              _CategoryBadge(category: card.category),
              const SizedBox(width: 1),
              Expanded(
                child: Text(
                  card.title,
                  style: TextStyle(
                    color: ChesseverColors.white,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Text(
                  _metaLine(card),
                  style: TextStyle(color: ChesseverColors.secondaryText),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _metaLine(BroadcastCard c) {
    final parts = <String>[];
    if (c.maxAvgElo != null) parts.add('≤${c.maxAvgElo} elo');
    if (c.timeControl != null) parts.add(c.timeControl!);
    final dates = _dateRange(c.start, c.end);
    if (dates.isNotEmpty) parts.add(dates);
    return parts.join('   ');
  }

  static String _dateRange(DateTime? s, DateTime? e) {
    if (s == null && e == null) return '';
    if (s != null && e != null) return '${_d(s)} → ${_d(e)}';
    return _d(s ?? e!);
  }

  static String _d(DateTime t) =>
      '${t.year}-${_pad(t.month)}-${_pad(t.day)}';

  static String _pad(int n) => n < 10 ? '0$n' : '$n';
}

class _CategoryBadge extends StatelessComponent {
  const _CategoryBadge({required this.category});

  final TourEventCategory category;

  @override
  Component build(BuildContext context) {
    final (label, color) = switch (category) {
      TourEventCategory.live => (' LIVE ', ChesseverColors.red),
      TourEventCategory.ongoing => ('  ●   ', ChesseverColors.green),
      TourEventCategory.upcoming => ('  ◌   ', ChesseverColors.lightYellow),
      TourEventCategory.completed =>
        ('  ✓   ', ChesseverColors.secondaryText),
    };
    return Container(
      child: Text(
        label,
        style: TextStyle(
          color: ChesseverColors.black,
          backgroundColor: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
