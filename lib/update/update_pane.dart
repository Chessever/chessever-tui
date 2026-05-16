import 'package:chessever_tui/theme/colors.dart';
import 'package:chessever_tui/update/updater.dart';
import 'package:nocterm/nocterm.dart';

class UpdatePane extends StatefulComponent {
  const UpdatePane({super.key});

  @override
  State<UpdatePane> createState() => _UpdatePaneState();
}

class _UpdatePaneState extends State<UpdatePane> {
  String _status = 'ready';
  bool _running = false;

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        final ch = event.character?.toLowerCase();
        if (event.logicalKey == LogicalKey.enter || ch == 'u' || ch == ' ') {
          _startUpdate();
          return true;
        }
        return false;
      },
      child: Container(
        color: ChesseverColors.background,
        padding: const EdgeInsets.all(2),
        child: Center(
          child: Container(
            width: 58,
            decoration: BoxDecoration(
              color: ChesseverColors.black2,
              border: BoxBorder.all(
                color: ChesseverColors.divider,
                style: BoxBorderStyle.rounded,
              ),
              title: BorderTitle(
                text: ' update ',
                alignment: TitleAlignment.center,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Install the latest Chessever TUI release.',
                  style: TextStyle(color: ChesseverColors.white),
                ),
                const SizedBox(height: 1),
                Text(
                  _status,
                  style: TextStyle(
                    color: _running
                        ? ChesseverColors.activeCalendar
                        : ChesseverColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 1),
                GestureDetector(
                  onTap: _startUpdate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _running
                          ? ChesseverColors.black3
                          : ChesseverColors.primary,
                      border: BoxBorder.all(color: ChesseverColors.divider),
                    ),
                    child: Text(
                      _running ? '  updating...  ' : '  update now  ',
                      style: TextStyle(
                        color: _running
                            ? ChesseverColors.white70
                            : ChesseverColors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'After it finishes, restart by typing: chessever',
                  style: TextStyle(color: ChesseverColors.tertiaryText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startUpdate() async {
    if (_running) return;
    setState(() {
      _running = true;
      _status = 'starting detached updater...';
    });
    try {
      await const UpgradeRunner().startDetached();
      if (!mounted) return;
      setState(() {
        _running = false;
        _status = 'update started; restart chessever after it finishes';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _running = false;
        _status = 'update failed: ${e.toString().split('\n').first}';
      });
    }
  }
}
