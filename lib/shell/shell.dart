import 'dart:io';

import 'package:chessever_tui/play/play_config.dart';
import 'package:chessever_tui/play/play_pane.dart';
import 'package:chessever_tui/settings/settings_model.dart';
import 'package:chessever_tui/settings/settings_pane.dart';
import 'package:chessever_tui/shell/sidebar.dart';
import 'package:chessever_tui/theme/colors.dart';
import 'package:chessever_tui/update/update_pane.dart';
import 'package:chessever_tui/watch/watch_pane.dart';
import 'package:nocterm/nocterm.dart';

class ChesseverShell extends StatefulComponent {
  const ChesseverShell({super.key, this.initialConfig});

  final PlayConfig? initialConfig;

  @override
  State<ChesseverShell> createState() => _ChesseverShellState();
}

class _ChesseverShellState extends State<ChesseverShell> {
  SidebarRoute _route = SidebarRoute.play;
  ChesseverSettings _settings = ChesseverSettings.defaults;

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        final ch = event.character;
        if (ch == 'q' || ch == 'Q') {
          exit(0);
        }
        if (ch == 'p' || ch == 'P') {
          setState(() => _route = SidebarRoute.play);
          return true;
        }
        if (ch == 'w' || ch == 'W') {
          setState(() => _route = SidebarRoute.watch);
          return true;
        }
        if (ch == 's' || ch == 'S') {
          setState(() => _route = SidebarRoute.settings);
          return true;
        }
        if (ch == 'u' || ch == 'U') {
          setState(() => _route = SidebarRoute.update);
          return true;
        }
        return false;
      },
      child: Container(
        color: ChesseverColors.background,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 72;
            if (compact) {
              return Column(
                children: [
                  _TopNav(
                    selected: _route,
                    onSelect: (r) => setState(() => _route = r),
                  ),
                  Expanded(child: _routeBody()),
                ],
              );
            }
            return Row(
              children: [
                Sidebar(
                  selected: _route,
                  onSelect: (r) => setState(() => _route = r),
                ),
                Expanded(child: _routeBody()),
              ],
            );
          },
        ),
      ),
    );
  }

  Component _routeBody() {
    switch (_route) {
      case SidebarRoute.play:
        return PlayPane(
          initialConfig: component.initialConfig ?? PlayConfig.defaultGame,
          settings: _settings,
        );
      case SidebarRoute.watch:
        return const WatchPane();
      case SidebarRoute.settings:
        return SettingsPane(
          settings: _settings,
          onChanged: (settings) => setState(() => _settings = settings),
        );
      case SidebarRoute.update:
        return const UpdatePane();
    }
  }
}

class _TopNav extends StatelessComponent {
  const _TopNav({required this.selected, required this.onSelect});

  final SidebarRoute selected;
  final ValueChanged<SidebarRoute> onSelect;

  @override
  Component build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        color: ChesseverColors.black2,
        border: BoxBorder(bottom: BorderSide(color: ChesseverColors.divider)),
      ),
      child: Row(
        children: [
          Text(' CHESSEVER ', style: TextStyle(color: ChesseverColors.primary)),
          for (final route in SidebarRoute.values)
            GestureDetector(
              onTap: () => onSelect(route),
              child: Text(
                route == selected
                    ? ' ${route.glyph} ${route.label.toUpperCase()} '
                    : ' ${route.glyph} ${route.label} ',
                style: TextStyle(
                  color: route == selected
                      ? ChesseverColors.primary
                      : ChesseverColors.white70,
                  fontWeight:
                      route == selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          const Spacer(),
          Text(' q quit ',
              style: TextStyle(color: ChesseverColors.tertiaryText)),
        ],
      ),
    );
  }
}
