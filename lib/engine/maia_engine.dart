import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:path/path.dart' as p;

/// Supported Maia strength levels (lc0 weights are published per ELO bucket).
const maiaElos = <int>[1100, 1300, 1500, 1700, 1900];

/// Engine contract used by the Play pane.
abstract class ChessEngine {
  String get label;
  Future<String?> bestMove({
    required String fen,
    required Duration moveTime,
  });
  Future<void> dispose();
}

/// Resolves the bundled / user-installed Maia engine. If `lc0` + a Maia weights
/// file is available we drive it over UCI. Otherwise we fall back to a weak
/// "vibes" engine so the TUI still plays a game.
class MaiaEngineFactory {
  static Future<ChessEngine> resolve({required int elo}) async {
    final lc0 = _resolveLc0Path();
    final weights = _resolveMaiaWeights(elo);
    if (lc0 != null && weights != null) {
      try {
        return await Lc0MaiaEngine.start(
          lc0Path: lc0,
          weightsPath: weights,
          elo: elo,
        );
      } catch (_) {
        // fall through to vibes engine
      }
    }
    return VibesEngine(elo: elo);
  }

  static String? _resolveLc0Path() {
    final override = io.Platform.environment['CHESSEVER_TUI_LC0'];
    if (override != null && io.File(override).existsSync()) return override;
    return _which('lc0');
  }

  static String? _resolveMaiaWeights(int elo) {
    final dirOverride = io.Platform.environment['CHESSEVER_TUI_MAIA_DIR'];
    final home = io.Platform.environment['HOME'] ??
        io.Platform.environment['USERPROFILE'] ??
        '.';
    final candidates = <String>[
      if (dirOverride != null) p.join(dirOverride, 'maia-$elo.pb.gz'),
      p.join(home, '.chessever-tui', 'weights', 'maia-$elo.pb.gz'),
      p.join(home, '.lc0', 'maia-$elo.pb.gz'),
    ];
    for (final path in candidates) {
      if (io.File(path).existsSync()) return path;
    }
    return null;
  }

  static String? _which(String binary) {
    try {
      final isWindows = io.Platform.isWindows;
      final result =
          io.Process.runSync(isWindows ? 'where' : 'which', [binary]);
      if (result.exitCode != 0) return null;
      final out = (result.stdout as String).split('\n').first.trim();
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }
}

/// Drives a local `lc0` subprocess over UCI using a Maia weights file.
class Lc0MaiaEngine implements ChessEngine {
  Lc0MaiaEngine._(this._process, this._lines, this.elo);

  final io.Process _process;
  final Stream<String> _lines;
  final int elo;
  bool _disposed = false;

  static Future<Lc0MaiaEngine> start({
    required String lc0Path,
    required String weightsPath,
    required int elo,
  }) async {
    final process = await io.Process.start(lc0Path, [
      '--weights=$weightsPath',
      // Maia networks: single-visit, no exploration. Mirrors maiachess.com.
      '--minibatch-size=1',
      '--max-prefetch=0',
      '--cpuct=0.0',
      '--policy-softmax-temp=1.0',
    ]);
    final lines = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();
    process.stderr.transform(utf8.decoder).listen((_) {});

    final engine = Lc0MaiaEngine._(process, lines, elo);
    process.stdin.writeln('uci');
    await engine._waitFor('uciok');
    process.stdin.writeln('isready');
    await engine._waitFor('readyok');
    return engine;
  }

  Future<String> _waitFor(String token) async {
    await for (final line in _lines) {
      if (line.contains(token)) return line;
    }
    throw StateError('lc0 closed before $token');
  }

  @override
  String get label => 'Maia $elo (lc0)';

  @override
  Future<String?> bestMove({
    required String fen,
    required Duration moveTime,
  }) async {
    if (_disposed) return null;
    _process.stdin.writeln('position fen $fen');
    _process.stdin.writeln('go nodes 1');
    await for (final line in _lines) {
      if (line.startsWith('bestmove')) {
        final parts = line.split(' ');
        if (parts.length < 2) return null;
        final move = parts[1];
        if (move == '(none)' || move == '0000') return null;
        return move;
      }
    }
    return null;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      _process.stdin.writeln('quit');
      await _process.stdin.flush();
    } catch (_) {}
    _process.kill();
  }
}

/// Fallback engine when no real Maia is available. Plays legal moves with a
/// light "be worse at lower ELO" heuristic. Clearly labels itself so the UI
/// can show a warning.
class VibesEngine implements ChessEngine {
  VibesEngine({required this.elo});
  final int elo;
  final Random _random = Random();

  @override
  String get label => 'Vibes bot (Maia weights missing)';

  @override
  Future<String?> bestMove({
    required String fen,
    required Duration moveTime,
  }) async {
    final position = Position.setupPosition(Rule.chess, Setup.parseFen(fen));
    final legal = makeLegalMoves(position);
    final candidates = <NormalMove>[];
    for (final entry in legal.entries) {
      for (final to in entry.value) {
        candidates.add(NormalMove(from: entry.key, to: to));
      }
    }
    if (candidates.isEmpty) return null;

    final ranked = <MapEntry<NormalMove, int>>[];
    for (final move in candidates) {
      var score = _random.nextInt(50);
      final target = position.board.pieceAt(move.to);
      if (target != null) score += 200 + _pieceValue(target.role);
      final after = position.playUnchecked(move);
      if (after.isCheck) score += 80;
      if (elo < 1300) score = _random.nextInt(100);
      ranked.add(MapEntry(move, score));
    }
    ranked.sort((a, b) => b.value.compareTo(a.value));
    return ranked.first.key.uci;
  }

  int _pieceValue(Role role) => switch (role) {
        Role.pawn => 100,
        Role.knight => 300,
        Role.bishop => 320,
        Role.rook => 500,
        Role.queen => 900,
        Role.king => 0,
      };

  @override
  Future<void> dispose() async {}
}
