import 'package:chessever_tui/engine/maia_engine.dart';
import 'package:chessever_tui/play/play_pane.dart';
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
  int _focus = 0; // 0 side, 1 elo, 2 start

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
      setState(() => _focus = (_focus + 1) % 3);
      return true;
    }
    if (event.logicalKey == LogicalKey.arrowDown) {
      setState(() => _focus = (_focus + 1) % 3);
      return true;
    }
    if (event.logicalKey == LogicalKey.arrowUp) {
      setState(() => _focus = (_focus + 2) % 3);
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
        setState(() => _elo = _prevElo(_elo));
        return true;
      }
      if (event.logicalKey == LogicalKey.arrowRight) {
        setState(() => _elo = _nextElo(_elo));
        return true;
      }
    }
    if (event.logicalKey == LogicalKey.enter ||
        event.character == ' ') {
      if (_focus == 2) {
        component.onStart(PlayConfig(humanSide: _side, elo: _elo));
        return true;
      }
      if (_focus == 0) {
        setState(() => _side = _side == Side.white ? Side.black : Side.white);
        return true;
      }
    }
    return false;
  }

  int _nextElo(int current) {
    final i = maiaElos.indexOf(current);
    return maiaElos[(i + 1) % maiaElos.length];
  }

  int _prevElo(int current) {
    final i = maiaElos.indexOf(current);
    return maiaElos[(i - 1 + maiaElos.length) % maiaElos.length];
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
        for (final elo in maiaElos) ...[
          _pill('$elo', _elo == elo, _focus == 1),
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
    final focused = _focus == 2;
    return GestureDetector(
      onTap: () =>
          component.onStart(PlayConfig(humanSide: _side, elo: _elo)),
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
          'enter    confirm',
          style: TextStyle(color: ChesseverColors.tertiaryText),
        ),
      ],
    );
  }
}
