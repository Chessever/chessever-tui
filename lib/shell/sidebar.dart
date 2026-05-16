import 'package:chessever_tui/theme/colors.dart';
import 'package:nocterm/nocterm.dart';

enum SidebarRoute {
  play('Play', '♞'),
  settings('Settings', '⚙'),
  update('Update', '⇧');

  const SidebarRoute(this.label, this.glyph);
  final String label;
  final String glyph;
}

class Sidebar extends StatelessComponent {
  const Sidebar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final SidebarRoute selected;
  final ValueChanged<SidebarRoute> onSelect;

  @override
  Component build(BuildContext context) {
    return Container(
      width: 16,
      decoration: BoxDecoration(
        color: ChesseverColors.black2,
        border: BoxBorder(
          right: BorderSide(color: ChesseverColors.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Brand(),
          const SizedBox(height: 1),
          for (final route in SidebarRoute.values)
            _SidebarItem(
              route: route,
              active: route == selected,
              onTap: () => onSelect(route),
            ),
          const Spacer(),
          const _FooterHint(),
        ],
      ),
    );
  }
}

class _Brand extends StatelessComponent {
  const _Brand();

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHESSEVER',
            style: TextStyle(
              color: ChesseverColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'bot only',
            style: TextStyle(color: ChesseverColors.tertiaryText),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessComponent {
  const _SidebarItem({
    required this.route,
    required this.active,
    required this.onTap,
  });

  final SidebarRoute route;
  final bool active;
  final VoidCallback onTap;

  @override
  Component build(BuildContext context) {
    final fg = active ? ChesseverColors.primary : ChesseverColors.white70;
    final bg = active ? ChesseverColors.black3 : null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 1,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: bg == null ? null : BoxDecoration(color: bg),
        child: Row(
          children: [
            Text(
              active ? '┃ ' : '  ',
              style: TextStyle(color: ChesseverColors.primary),
            ),
            Text(
              route.glyph,
              style: TextStyle(color: fg),
            ),
            Text(
              '  ${route.label}',
              style: TextStyle(
                color: fg,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterHint extends StatelessComponent {
  const _FooterHint();

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'p play',
            style: TextStyle(color: ChesseverColors.tertiaryText),
          ),
          Text(
            's settings',
            style: TextStyle(color: ChesseverColors.tertiaryText),
          ),
          Text(
            'u update',
            style: TextStyle(color: ChesseverColors.tertiaryText),
          ),
        ],
      ),
    );
  }
}
