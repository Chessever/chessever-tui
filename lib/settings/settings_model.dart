import 'package:chessever_tui/theme/colors.dart';
import 'package:nocterm/nocterm.dart';

enum BoardStyle {
  chesseverPixel('Chessever pixel board');

  const BoardStyle(this.label);
  final String label;
}

enum PieceStyle {
  chesseverPixel('Chessever pixel pieces');

  const PieceStyle(this.label);
  final String label;
}

enum PlayerFlag {
  cyan('cyan', ChesseverColors.primary),
  red('red', ChesseverColors.red),
  green('green', ChesseverColors.green2),
  gold('gold', ChesseverColors.lightYellow),
  white('white', ChesseverColors.white);

  const PlayerFlag(this.label, this.color);
  final String label;
  final Color color;
}

class ChesseverSettings {
  const ChesseverSettings({
    required this.boardStyle,
    required this.pieceStyle,
    required this.playerFlag,
  });

  static const defaults = ChesseverSettings(
    boardStyle: BoardStyle.chesseverPixel,
    pieceStyle: PieceStyle.chesseverPixel,
    playerFlag: PlayerFlag.cyan,
  );

  final BoardStyle boardStyle;
  final PieceStyle pieceStyle;
  final PlayerFlag playerFlag;

  ChesseverSettings copyWith({
    BoardStyle? boardStyle,
    PieceStyle? pieceStyle,
    PlayerFlag? playerFlag,
  }) {
    return ChesseverSettings(
      boardStyle: boardStyle ?? this.boardStyle,
      pieceStyle: pieceStyle ?? this.pieceStyle,
      playerFlag: playerFlag ?? this.playerFlag,
    );
  }
}

class PixelFlag extends StatelessComponent {
  const PixelFlag({
    super.key,
    required this.color,
    this.pirate = false,
  });

  final Color color;
  final bool pirate;

  @override
  Component build(BuildContext context) {
    final rows = pirate
        ? const ['▛▀▀▜', '▌☠ ▐', '▙▄▄▟']
        : const ['▛▀▀▜', '▌██▐', '▙▄▄▟'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows) Text(row, style: TextStyle(color: color)),
      ],
    );
  }
}
