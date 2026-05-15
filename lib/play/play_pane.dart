import 'package:chessever_tui/engine/maia_engine.dart';
import 'package:chessever_tui/play/active_game.dart';
import 'package:chessever_tui/play/setup_screen.dart';
import 'package:chessever_tui/theme/colors.dart';
import 'package:dartchess/dartchess.dart';
import 'package:nocterm/nocterm.dart' hide Position;

class PlayConfig {
  const PlayConfig({required this.humanSide, required this.elo});
  final Side humanSide;
  final int elo;
}

class PlayPane extends StatefulComponent {
  const PlayPane({super.key});

  @override
  State<PlayPane> createState() => _PlayPaneState();
}

class _PlayPaneState extends State<PlayPane> {
  PlayConfig? _started;
  String? _engineLabel;
  ChessEngine? _engine;

  Future<void> _start(PlayConfig config) async {
    final engine = await MaiaEngineFactory.resolve(elo: config.elo);
    if (!mounted) {
      engine.dispose();
      return;
    }
    setState(() {
      _started = config;
      _engineLabel = engine.label;
      _engine = engine;
    });
  }

  void _exitGame() {
    _engine?.dispose();
    setState(() {
      _started = null;
      _engine = null;
      _engineLabel = null;
    });
  }

  @override
  void dispose() {
    _engine?.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return Container(
      color: ChesseverColors.background,
      child: Column(
        children: [
          _PlayHeader(active: _started != null),
          Expanded(
            child: _started == null || _engine == null
                ? PlaySetupScreen(onStart: _start)
                : ActiveGameView(
                    key: ValueKey('${_started!.humanSide}-${_started!.elo}'),
                    config: _started!,
                    engine: _engine!,
                    engineLabel: _engineLabel ?? 'engine',
                    onExit: _exitGame,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlayHeader extends StatelessComponent {
  const _PlayHeader({required this.active});
  final bool active;

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
          Text(
            '♞  ',
            style: TextStyle(color: ChesseverColors.primary),
          ),
          Text(
            'PLAY',
            style: TextStyle(
              color: ChesseverColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '   single game',
            style: TextStyle(color: ChesseverColors.secondaryText),
          ),
          const Spacer(),
          Text(
            active ? 'in progress' : 'setup',
            style: TextStyle(color: ChesseverColors.tertiaryText),
          ),
        ],
      ),
    );
  }
}
