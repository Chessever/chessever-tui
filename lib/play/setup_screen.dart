import 'package:chessever_tui/play/play_config.dart';
import 'package:chessever_tui/theme/colors.dart';
import 'package:dartchess/dartchess.dart';
import 'package:nocterm/nocterm.dart' hide Position;

class PlaySetupScreen extends StatefulComponent {
  const PlaySetupScreen({super.key, required this.onStart});
  final ValueChanged<PlayConfig> onStart;

  @override
  State<PlaySetupScreen> createState() => _PlaySetupScreenState();
}

class _PlaySetupScreenState extends State<PlaySetupScreen> {
  Side _side = Side.white;
  int _elo = 1500;
  TimeControl _timeControl = TimeControl.blitz;
  int _focus = 0; // 0 side, 1 elo, 2 clock, 3 start
  String _typedElo = '';

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: _onKey,
      child: Center(
        child: Container(
          width: 56,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: ChesseverColors.black2,
            border: BoxBorder.all(
              color: ChesseverColors.divider,
              style: BoxBorderStyle.rounded,
            ),
            title: BorderTitle(
              text: ' new game · vs Maia ',
              alignment: TitleAlignment.center,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('play as'),
              _sideRow(),
              const SizedBox(height: 1),
              _label('opponent strength (Maia ELO)'),
              _eloRow(),
              const SizedBox(height: 1),
              _label('clock'),
              _clockRow(),
              const SizedBox(height: 1),
              _startButton(),
              const SizedBox(height: 1),
              _legend(),
            ],
          ),
        ),
      ),
    );
  }

  bool _onKey(KeyboardEvent event) {
    if (event.logicalKey == LogicalKey.tab) {
      setState(() => _focus = (_focus + 1) % 4);
      return true;
    }
    if (event.logicalKey == LogicalKey.arrowDown) {
      setState(() => _focus = (_focus + 1) % 4);
      return true;
    }
    if (event.logicalKey == LogicalKey.arrowUp) {
      setState(() => _focus = (_focus + 3) % 4);
      return true;
    }
    if (_focus == 0 &&
        (event.logicalKey == LogicalKey.arrowLeft ||
            event.logicalKey == LogicalKey.arrowRight)) {
      setState(() => _side = _side == Side.white ? Side.black : Side.white);
      return true;
    }
    if (_focus == 1) {
      if (event.logicalKey == LogicalKey.arrowLeft) {
        setState(() => _setElo(_elo - 50));
        return true;
      }
      if (event.logicalKey == LogicalKey.arrowRight) {
        setState(() => _setElo(_elo + 50));
        return true;
      }
      if (event.logicalKey == LogicalKey.backspace) {
        setState(() {
          if (_typedElo.isNotEmpty) {
            _typedElo = _typedElo.substring(0, _typedElo.length - 1);
            _elo = _typedElo.isEmpty ? 1500 : _normalizeElo(_typedElo);
          }
        });
        return true;
      }
      final digit = event.character;
      if (digit != null && RegExp(r'^\d$').hasMatch(digit)) {
        setState(() {
          _typedElo = (_typedElo + digit);
          if (_typedElo.length > 4) _typedElo = digit;
          _elo = _normalizeElo(_typedElo);
        });
        return true;
      }
    }
    if (_focus == 2 &&
        (event.logicalKey == LogicalKey.arrowLeft ||
            event.logicalKey == LogicalKey.arrowRight)) {
      setState(() => _timeControl = _cycleClock(
            event.logicalKey == LogicalKey.arrowLeft ? -1 : 1,
          ));
      return true;
    }
    if (event.logicalKey == LogicalKey.enter || event.character == ' ') {
      if (_focus == 3) {
        component.onStart(
          PlayConfig(humanSide: _side, elo: _elo, timeControl: _timeControl),
        );
        return true;
      }
      if (_focus == 0) {
        setState(() => _side = _side == Side.white ? Side.black : Side.white);
        return true;
      }
    }
    return false;
  }

  void _setElo(int elo) {
    _elo = elo.clamp(100, 3000);
    _typedElo = '';
  }

  int _normalizeElo(String value) {
    final parsed = int.tryParse(value) ?? 1500;
    return parsed.clamp(100, 3000);
  }

  TimeControl _cycleClock(int delta) {
    final values = TimeControl.values;
    final i = values.indexOf(_timeControl);
    return values[(i + delta + values.length) % values.length];
  }

  Component _label(String text) => Text(
        text,
        style: TextStyle(color: ChesseverColors.secondaryText),
      );

  Component _sideRow() {
    return Row(
      children: [
        _pill('white', _side == Side.white, _focus == 0),
        const SizedBox(width: 2),
        _pill('black', _side == Side.black, _focus == 0),
      ],
    );
  }

  Component _eloRow() {
    return Row(
      children: [
        _pill('$_elo', true, _focus == 1),
        const SizedBox(width: 2),
        Text(
          _focus == 1 ? 'type digits or ←→ by 50' : '100..3000',
          style: TextStyle(color: ChesseverColors.tertiaryText),
        ),
      ],
    );
  }

  Component _clockRow() {
    return Row(
      children: [
        for (final value in TimeControl.values) ...[
          _pill(value.label, _timeControl == value, _focus == 2),
          const SizedBox(width: 1),
        ],
      ],
    );
  }

  Component _pill(String label, bool selected, bool focusedGroup) {
    final bg = selected ? ChesseverColors.primary : ChesseverColors.black3;
    final fg = selected ? ChesseverColors.black : ChesseverColors.white70;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: bg,
        border: BoxBorder.all(
          color: focusedGroup && selected
              ? ChesseverColors.white
              : ChesseverColors.divider,
        ),
      ),
      child: Text(
        ' $label ',
        style: TextStyle(
          color: fg,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Component _startButton() {
    final focused = _focus == 3;
    return GestureDetector(
      onTap: () => component.onStart(
        PlayConfig(humanSide: _side, elo: _elo, timeControl: _timeControl),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: focused ? ChesseverColors.primary : ChesseverColors.black3,
          border: BoxBorder.all(
            color: focused ? ChesseverColors.white : ChesseverColors.divider,
          ),
        ),
        child: Text(
          '  ▶  start game  ',
          style: TextStyle(
            color: focused ? ChesseverColors.black : ChesseverColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Component _legend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '↑↓/tab   move focus',
          style: TextStyle(color: ChesseverColors.tertiaryText),
        ),
        Text(
          '←→       change value',
          style: TextStyle(color: ChesseverColors.tertiaryText),
        ),
        Text(
          'enter    confirm / start',
          style: TextStyle(color: ChesseverColors.tertiaryText),
        ),
      ],
    );
  }
}
