// Visual smoke test for pixel piece sprites. Prints the initial position
// at all five density tiers using raw ANSI 24-bit color escapes — no
// nocterm event loop, so output is captured cleanly in a regular shell.
//
//   dart run bin/preview_pieces.dart
//
// Tweak sprites in lib/play/pieces.dart and re-run to iterate.
import 'dart:io';

import 'package:chessever_tui/play/pieces.dart';
import 'package:dartchess/dartchess.dart';

const _boardLight = [0xD1, 0xE9, 0xE9];
const _boardDark = [0x6B, 0x93, 0x9F];
const _white = [0xFF, 0xFF, 0xFF];
const _black = [0x10, 0x10, 0x12];
const _label = [0x63, 0x63, 0x66];

String _fg(List<int> c) => '\x1b[38;2;${c[0]};${c[1]};${c[2]}m';
String _bg(List<int> c) => '\x1b[48;2;${c[0]};${c[1]};${c[2]}m';
const _reset = '\x1b[0m';

enum _Density { xl, full, compact, small, mini }

({int w, int h, int sw}) _dims(_Density d) => switch (d) {
      _Density.xl => (w: 9, h: 6, sw: 7),
      _Density.full => (w: 7, h: 4, sw: 5),
      _Density.compact => (w: 7, h: 3, sw: 5),
      _Density.small => (w: 7, h: 2, sw: 5),
      _Density.mini => (w: 3, h: 1, sw: 1),
    };

List<String> _pieceRows(_Density d, Piece? p) {
  if (p == null) {
    final w = _dims(d).sw;
    final h = _dims(d).h;
    return List.filled(h, ' ' * w);
  }
  final s = PieceSprite.forRole(p.role);
  switch (d) {
    case _Density.xl:
      return PieceSprite.halfBlockRows(s.xlarge);
    case _Density.full:
      return PieceSprite.halfBlockRows(s.extended);
    case _Density.compact:
      return PieceSprite.halfBlockRows(s.compact);
    case _Density.small:
      return PieceSprite.halfBlockRows(s.small);
    case _Density.mini:
      return [s.mini];
  }
}

void _render(Position pos, _Density d) {
  final dim = _dims(d);
  final out = StringBuffer();
  out
    ..write(_fg(_label))
    ..writeln('── density: ${d.name} (cell ${dim.w}×${dim.h}) ──')
    ..write(_reset);

  for (var rank = 7; rank >= 0; rank--) {
    final rowsForRank = List.generate(dim.h, (_) => StringBuffer());
    rowsForRank.first.write('${_fg(_label)} ${rank + 1} $_reset');
    for (var i = 1; i < dim.h; i++) {
      rowsForRank[i].write('   ');
    }
    for (var file = 0; file < 8; file++) {
      final sq = Square.fromCoords(File(file), Rank(rank));
      final piece = pos.board.pieceAt(sq);
      final isLight = ((file + rank) % 2) == 1;
      final bg = _bg(isLight ? _boardLight : _boardDark);
      final fg = piece == null
          ? '' // doesn't matter, no ink
          : _fg(piece.color == Side.white ? _white : _black);
      final spriteRows = _pieceRows(d, piece);
      for (var i = 0; i < dim.h; i++) {
        final inner = spriteRows[i];
        final padded = d == _Density.mini ? inner : ' $inner ';
        rowsForRank[i].write('$bg$fg$padded$_reset');
      }
    }
    for (final r in rowsForRank) {
      out.writeln(r.toString());
    }
  }
  // File labels
  final fileLabels = StringBuffer('   ');
  for (var f = 0; f < 8; f++) {
    final ch = String.fromCharCode('a'.codeUnitAt(0) + f);
    final pad = switch (d) {
      _Density.xl => '    $ch    ',
      _Density.full || _Density.compact || _Density.small => '   $ch   ',
      _Density.mini => ' $ch ',
    };
    fileLabels.write('${_fg(_label)}$pad$_reset');
  }
  out.writeln(fileLabels);
  stdout.write(out);
}

void main() {
  final start = Chess.initial;
  stdout.writeln();
  for (final d in _Density.values) {
    _render(start, d);
    stdout.writeln();
  }
  stdout.writeln(
    '${_fg(_label)}tip: resize terminal narrower to see denser tiers in real app.$_reset',
  );
}
