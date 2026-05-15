import 'package:chessever_tui/theme/colors.dart';
import 'package:nocterm/nocterm.dart';

/// Shell sidebar routes. We ship Play first; the rest are stubs that mirror
/// the desktop sidebar so the visual identity matches.
enum SidebarRoute {
  play('Play', '♞'),
  tournaments('Tournaments', '♛'),
  library('Library', '☰'),
  favorites('Favorites', '★'),
  players('Players', '☺'),
  calendar('Calendar', '▣'),
  settings('Settings', '⚙');

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
      width: 22,
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

  // 5×9 pixel rendition of the Chessever mark — four cyan corner-blocks framing
  // a hollow plus, with the brand's king silhouette anchored in the center.
  static const _logoRows = <String>[
    '███   ███',
    '██▌   ▐██',
    '   ▟█▙   ',
    '██▌▝█▘▐██',
    '███   ███',
  ];

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _logoRows.length; i++)
            Text(
              _logoRows[i],
              style: TextStyle(
                color: i == 2
                    ? ChesseverColors.white
                    : ChesseverColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 1),
          Text(
            'CHESSEVER',
            style: TextStyle(
              color: ChesseverColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'tui edition',
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
            '←→↑↓ cursor',
            style: TextStyle(color: ChesseverColors.tertiaryText),
          ),
          Text(
            'space  select/move',
            style: TextStyle(color: ChesseverColors.tertiaryText),
          ),
          Text(
            'q       quit',
            style: TextStyle(color: ChesseverColors.tertiaryText),
          ),
        ],
      ),
    );
  }
}
