import 'dart:io';

import 'package:chessever_tui/play/play_pane.dart';
import 'package:chessever_tui/shell/sidebar.dart';
import 'package:chessever_tui/theme/colors.dart';
import 'package:nocterm/nocterm.dart';

class ChesseverShell extends StatefulComponent {
  const ChesseverShell({super.key});

  @override
  State<ChesseverShell> createState() => _ChesseverShellState();
}

class _ChesseverShellState extends State<ChesseverShell> {
  SidebarRoute _route = SidebarRoute.play;

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        final ch = event.character;
        if (ch == 'q' || ch == 'Q') {
          exit(0);
        }
        return false;
      },
      child: Container(
        color: ChesseverColors.background,
        child: Row(
          children: [
            Sidebar(
              selected: _route,
              onSelect: (r) => setState(() => _route = r),
            ),
            Expanded(child: _routeBody()),
          ],
        ),
      ),
    );
  }

  Component _routeBody() {
    switch (_route) {
      case SidebarRoute.play:
        return const PlayPane();
      default:
        return _ComingSoon(label: _route.label);
    }
  }
}

class _ComingSoon extends StatelessComponent {
  const _ComingSoon({required this.label});
  final String label;

  @override
  Component build(BuildContext context) {
    return Container(
      color: ChesseverColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: ChesseverColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'coming soon to the terminal.',
              style: TextStyle(color: ChesseverColors.tertiaryText),
            ),
          ],
        ),
      ),
    );
  }
}
