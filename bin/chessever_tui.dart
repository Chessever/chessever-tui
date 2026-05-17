import 'dart:io';
import 'dart:io' as io show File;

import 'package:chessever_tui/app.dart';
import 'package:chessever_tui/play/play_config.dart';
import 'package:chessever_tui/update/updater.dart';
import 'package:dartchess/dartchess.dart';
import 'package:nocterm/nocterm.dart';

final String _version = _resolveVersion();

/// Resolves the package version.
///
/// 1. Compile-time `--define=chessever.version=X.Y.Z` (set by CI before
///    `dart compile exe`).
/// 2. `pubspec.yaml` near the running script — works for `dart run`
///    from a source checkout.
/// 3. `'dev'` as a last-resort fallback.
String _resolveVersion() {
  const compiled = String.fromEnvironment('chessever.version');
  if (compiled.isNotEmpty) return compiled;

  for (final candidate in _pubspecCandidates()) {
    try {
      if (!candidate.existsSync()) continue;
      final match = RegExp(r'^version:\s*(\S+)', multiLine: true)
          .firstMatch(candidate.readAsStringSync());
      if (match != null) return match.group(1)!;
    } catch (_) {
      // Ignore IO/regex failures and try the next candidate.
    }
  }
  return 'dev';
}

Iterable<io.File> _pubspecCandidates() sync* {
  yield io.File('pubspec.yaml');
  try {
    final scriptDir = io.File.fromUri(Platform.script).parent.path;
    yield io.File('$scriptDir/pubspec.yaml');
    yield io.File('$scriptDir/../pubspec.yaml');
  } catch (_) {
    // Platform.script may be unusable (compiled exe); skip.
  }
}

Future<void> main(List<String> args) async {
  final cli = await _handleCli(args);
  if (cli.exitCode != null) {
    exitCode = cli.exitCode!;
    return;
  }
  await runApp(ChesseverTuiApp(initialConfig: cli.initialConfig));
}

Future<_CliDecision> _handleCli(List<String> args) async {
  if (args.isEmpty) return const _CliDecision.launch();

  switch (args.first) {
    case '-h':
    case '--help':
    case 'help':
      _printHelp();
      return const _CliDecision.exit(0);
    case '-v':
    case '--version':
    case 'version':
      stdout.writeln('chessever $_version');
      return const _CliDecision.exit(0);
    case 'upgrade':
    case 'update':
      return _CliDecision.exit(await const UpgradeRunner().runForeground());
    case 'play':
      return _parseShortcut(args.skip(1).toList());
  }

  return _parseShortcut(args);
}

void _printHelp() {
  stdout.writeln('''
Chessever TUI

Usage:
  chessever              Play Maia 1500 blitz in your terminal
  chessever 1900 blitz   Start Maia 1900 with a 3+0 clock
  chessever 1500 rapid   Start Maia 1500 with a 10+0 clock
  chessever play black   Start from the setup/play command path
  chessever update       Upgrade to the latest release
  chessever --version    Print the installed version
  chessever help         Show this help
''');
}

_CliDecision _parseShortcut(List<String> args) {
  if (args.isEmpty) return const _CliDecision.launch();

  var config = PlayConfig.defaultGame;
  for (final raw in args) {
    final token = raw.toLowerCase().trim();
    final elo = int.tryParse(token);
    if (elo != null) {
      config = config.copyWith(elo: elo.clamp(100, 3000));
      continue;
    }

    final timeControl = TimeControl.tryParse(token);
    if (timeControl != null) {
      config = config.copyWith(timeControl: timeControl);
      continue;
    }

    if (token == 'white') {
      config = config.copyWith(humanSide: Side.white);
      continue;
    }
    if (token == 'black') {
      config = config.copyWith(humanSide: Side.black);
      continue;
    }

    stderr.writeln('Unknown command option: $raw');
    _printHelp();
    return const _CliDecision.exit(64);
  }

  return _CliDecision.launch(config);
}

class _CliDecision {
  const _CliDecision.launch([this.initialConfig]) : exitCode = null;
  const _CliDecision.exit(this.exitCode) : initialConfig = null;

  final int? exitCode;
  final PlayConfig? initialConfig;
}
