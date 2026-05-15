import 'package:chessever_tui/commands/commands_repository.dart';
import 'package:chessever_tui/theme/colors.dart';
import 'package:nocterm/nocterm.dart';

class CommandsPane extends StatefulComponent {
  const CommandsPane({super.key});

  @override
  State<CommandsPane> createState() => _CommandsPaneState();
}

class _CommandsPaneState extends State<CommandsPane> {
  final _repo = CommandsRepository();
  CommandBundle _bundle = CommandBundle.empty;
  String _status = 'loading…';
  bool _loading = true;
  int _cursor = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cached = await _repo.loadCached();
    if (!mounted) return;
    setState(() {
      _bundle = cached;
      _status = cached.commands.isEmpty ? 'no cached commands' : 'cached v${cached.version}';
    });
    await _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _status = 'refreshing…';
    });
    try {
      final fresh = await _repo.fetchRemote();
      if (!mounted) return;
      setState(() {
        _bundle = fresh;
        _cursor = _cursor.clamp(0, fresh.commands.isEmpty ? 0 : fresh.commands.length - 1);
        _status = 'v${fresh.version} · ${fresh.commands.length} commands';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'offline · ${e.toString().split('\n').first}';
        _loading = false;
      });
    }
  }

  void _move(int delta) {
    if (_bundle.commands.isEmpty) return;
    setState(() {
      _cursor = (_cursor + delta).clamp(0, _bundle.commands.length - 1);
    });
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (e) {
        if (e.logicalKey == LogicalKey.arrowUp) {
          _move(-1);
          return true;
        }
        if (e.logicalKey == LogicalKey.arrowDown) {
          _move(1);
          return true;
        }
        final ch = e.character;
        if (ch == 'r' || ch == 'R') {
          _refresh();
          return true;
        }
        return false;
      },
      child: Container(
        color: ChesseverColors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(status: _status, loading: _loading),
            Expanded(child: _list()),
            _Footer(),
          ],
        ),
      ),
    );
  }

  Component _list() {
    if (_bundle.commands.isEmpty) {
      return Center(
        child: Text(
          _loading ? 'fetching commands…' : 'no commands yet — press r to refresh',
          style: TextStyle(color: ChesseverColors.tertiaryText),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 28,
          decoration: BoxDecoration(
            border: BoxBorder(right: BorderSide(color: ChesseverColors.divider)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _bundle.commands.length; i++)
                _CommandRow(
                  cmd: _bundle.commands[i],
                  active: i == _cursor,
                ),
            ],
          ),
        ),
        Expanded(child: _detail()),
      ],
    );
  }

  Component _detail() {
    final cmd = _bundle.commands[_cursor];
    return Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cmd.name,
            style: TextStyle(
              color: ChesseverColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 1),
          Text(cmd.description,
              style: TextStyle(color: ChesseverColors.white70)),
          const SizedBox(height: 1),
          Text('keys   : ${cmd.keys.isEmpty ? '—' : cmd.keys}',
              style: TextStyle(color: ChesseverColors.tertiaryText)),
          Text('action : ${cmd.action}',
              style: TextStyle(color: ChesseverColors.tertiaryText)),
          if (cmd.payload.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text('payload:', style: TextStyle(color: ChesseverColors.tertiaryText)),
            for (final entry in cmd.payload.entries)
              Text('  ${entry.key} = ${entry.value}',
                  style: TextStyle(color: ChesseverColors.white70)),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessComponent {
  const _Header({required this.status, required this.loading});
  final String status;
  final bool loading;

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        border: BoxBorder(bottom: BorderSide(color: ChesseverColors.divider)),
      ),
      child: Row(
        children: [
          Text('COMMANDS',
              style: TextStyle(
                color: ChesseverColors.primary,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(width: 2),
          Text(loading ? '· $status' : '· $status',
              style: TextStyle(color: ChesseverColors.tertiaryText)),
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
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        border: BoxBorder(top: BorderSide(color: ChesseverColors.divider)),
      ),
      child: Text(
        '↑↓ navigate    r refresh from data hub',
        style: TextStyle(color: ChesseverColors.tertiaryText),
      ),
    );
  }
}

class _CommandRow extends StatelessComponent {
  const _CommandRow({required this.cmd, required this.active});
  final TuiCommand cmd;
  final bool active;

  @override
  Component build(BuildContext context) {
    final fg = active ? ChesseverColors.primary : ChesseverColors.white70;
    return Container(
      height: 1,
      padding: const EdgeInsets.symmetric(horizontal: 1),
      decoration: active
          ? BoxDecoration(color: ChesseverColors.black3)
          : null,
      child: Row(
        children: [
          Text(active ? '┃ ' : '  ',
              style: TextStyle(color: ChesseverColors.primary)),
          Text(
            cmd.name,
            style: TextStyle(
              color: fg,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
