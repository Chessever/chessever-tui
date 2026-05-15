import 'package:nocterm/nocterm.dart';

/// Chessever brand palette ported to TUI 24-bit color.
/// Source: chessever_frontend_desktop/lib/theme/app_theme.dart
class ChesseverColors {
  static const primary = Color.fromRGB(0x0F, 0xB4, 0xE5);
  static const darkBlue = Color.fromRGB(0x17, 0xAA, 0xD6);
  static const background = Color.fromRGB(0x0C, 0x0C, 0x0E);
  static const black = Color.fromRGB(0x00, 0x00, 0x00);
  static const popup = Color.fromRGB(0x11, 0x11, 0x11);
  static const black2 = Color.fromRGB(0x1A, 0x1A, 0x1C);
  static const black3 = Color.fromRGB(0x25, 0x25, 0x27);
  static const divider = Color.fromRGB(0x2C, 0x2C, 0x2E);
  static const white = Color.fromRGB(0xFF, 0xFF, 0xFF);
  static const white70 = Color.fromRGB(0xB3, 0xB3, 0xB3);
  static const lightYellow = Color.fromRGB(0xE9, 0xED, 0xCC);
  static const green = Color.fromRGB(0x00, 0x9C, 0x42);
  static const green2 = Color.fromRGB(0x45, 0xC8, 0x6E);
  static const red = Color.fromRGB(0xF5, 0x45, 0x3A);
  static const lightGrey = Color.fromRGB(0x66, 0x66, 0x66);
  static const darkGrey = Color.fromRGB(0x26, 0x26, 0x26);
  static const secondaryText = Color.fromRGB(0x8E, 0x8E, 0x93);
  static const tertiaryText = Color.fromRGB(0x63, 0x63, 0x66);
  static const placeholder = Color.fromRGB(0x48, 0x48, 0x4A);
  static const inactiveTab = Color.fromRGB(0x66, 0x66, 0x66);
  static const activeCalendar = Color.fromRGB(0x68, 0xD3, 0xFF);
  static const lastMoveLight = Color.fromRGB(0xAD, 0xB9, 0xCF);
  static const lastMoveDark = Color.fromRGB(0x9D, 0xAA, 0xC2);

  // Board (default Chessever "blue-slate" theme).
  static const boardLight = Color.fromRGB(0xD1, 0xE9, 0xE9);
  static const boardDark = Color.fromRGB(0x6B, 0x93, 0x9F);

  // Cursor + selection accents — built on top of brand primary.
  static const cursorRing = Color.fromRGB(0x0F, 0xB4, 0xE5);
  static const legalDot = Color.fromRGB(0x45, 0xC8, 0x6E);
  static const captureRing = Color.fromRGB(0xF5, 0x45, 0x3A);
  static const checkGlow = Color.fromRGB(0xFF, 0x8A, 0x65);
}
