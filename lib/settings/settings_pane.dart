import 'package:chessever_tui/settings/settings_model.dart';
import 'package:chessever_tui/theme/colors.dart';
import 'package:nocterm/nocterm.dart';

class SettingsPane extends StatefulComponent {
  const SettingsPane({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final ChesseverSettings settings;
  final ValueChanged<ChesseverSettings> onChanged;

  @override
  State<SettingsPane> createState() => _SettingsPaneState();
}

class _SettingsPaneState extends State<SettingsPane> {
  int _focus = 0;

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: _onKey,
      child: Container(
        color: ChesseverColors.background,
        padding: const EdgeInsets.all(2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 76;
            final content = _content(compact: compact);
            return compact ? content : Center(child: content);
          },
        ),
      ),
    );
  }

  bool _onKey(KeyboardEvent event) {
    if (event.logicalKey == LogicalKey.arrowDown ||
        event.logicalKey == LogicalKey.tab) {
      setState(() => _focus = (_focus + 1) % 3);
      return true;
    }
    if (event.logicalKey == LogicalKey.arrowUp) {
      setState(() => _focus = (_focus + 2) % 3);
      return true;
    }
    if (_focus == 2 &&
        (event.logicalKey == LogicalKey.arrowLeft ||
            event.logicalKey == LogicalKey.arrowRight ||
            event.logicalKey == LogicalKey.enter ||
            event.character == ' ')) {
      final delta = event.logicalKey == LogicalKey.arrowLeft ? -1 : 1;
      _cycleFlag(delta);
      return true;
    }
    return false;
  }

  void _cycleFlag(int delta) {
    final values = PlayerFlag.values;
    final current = values.indexOf(component.settings.playerFlag);
    final next = values[(current + delta + values.length) % values.length];
    component.onChanged(component.settings.copyWith(playerFlag: next));
  }

  Component _content({required bool compact}) {
    return Container(
      width: compact ? double.infinity : 58,
      decoration: BoxDecoration(
        color: ChesseverColors.black2,
        border: BoxBorder.all(
          color: ChesseverColors.divider,
          style: BoxBorderStyle.rounded,
        ),
        title: BorderTitle(
          text: ' settings ',
          alignment: TitleAlignment.center,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(
            index: 0,
            label: 'board',
            value: component.settings.boardStyle.label,
            locked: true,
          ),
          _row(
            index: 1,
            label: 'pieces',
            value: component.settings.pieceStyle.label,
            locked: true,
          ),
          _row(
            index: 2,
            label: 'your flag',
            value: component.settings.playerFlag.label,
          ),
          const SizedBox(height: 1),
          _preview(),
          const SizedBox(height: 1),
          Text(
            'Only the website pixel board and pieces are shipped in this build.',
            style: TextStyle(color: ChesseverColors.tertiaryText),
            maxLines: compact ? 2 : 1,
          ),
          Text(
            '↑↓ focus   ←→ change flag   p play',
            style: TextStyle(color: ChesseverColors.tertiaryText),
          ),
        ],
      ),
    );
  }

  Component _row({
    required int index,
    required String label,
    required String value,
    bool locked = false,
  }) {
    final active = _focus == index;
    return Container(
      height: 1,
      decoration: active ? BoxDecoration(color: ChesseverColors.black3) : null,
      child: Row(
        children: [
          Text(active ? '┃ ' : '  ',
              style: TextStyle(color: ChesseverColors.primary)),
          Container(
            width: 11,
            child:
                Text(label, style: TextStyle(color: ChesseverColors.white70)),
          ),
          Expanded(
            child: Text(
              locked ? '$value  selected' : value,
              style: TextStyle(
                color: active ? ChesseverColors.primary : ChesseverColors.white,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Component _preview() {
    return Row(
      children: [
        _playerPreview(
          label: 'you',
          flag: PixelFlag(color: component.settings.playerFlag.color),
        ),
        const SizedBox(width: 4),
        _playerPreview(
          label: 'bot',
          flag: const PixelFlag(color: ChesseverColors.white, pirate: true),
        ),
      ],
    );
  }

  Component _playerPreview({required String label, required Component flag}) {
    return Row(
      children: [
        flag,
        const SizedBox(width: 1),
        Text(label, style: TextStyle(color: ChesseverColors.secondaryText)),
      ],
    );
  }
}
