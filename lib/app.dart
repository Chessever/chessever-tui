import 'package:chessever_tui/shell/shell.dart';
import 'package:chessever_tui/play/play_config.dart';
import 'package:nocterm/nocterm.dart';

class ChesseverTuiApp extends StatelessComponent {
  const ChesseverTuiApp({super.key, this.initialConfig});

  final PlayConfig? initialConfig;

  @override
  Component build(BuildContext context) =>
      ChesseverShell(initialConfig: initialConfig);
}
