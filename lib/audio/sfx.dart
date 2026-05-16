import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Tiny audio helper that fires WAV samples through the platform's stock CLI
/// player (afplay/paplay/aplay/powershell). Failures are swallowed so the UI
/// never blocks or crashes on a headless box or missing binary.
enum Sfx {
  move('piece_move.wav'),
  capture('piece_takeover.wav'),
  castle('piece_castling.wav'),
  check('piece_check.wav'),
  checkmate('piece_checkmate.wav'),
  draw('piece_draw.wav'),
  promotion('piece_promotion.wav');

  const Sfx(this.file);
  final String file;
}

class SfxPlayer {
  SfxPlayer._();
  static final instance = SfxPlayer._();

  bool enabled = true;
  String? _assetsRoot;
  String? _binary;
  List<String>? _binaryArgs;

  void preload() {
    _resolveAssetsRoot();
    _resolveBinary();
  }

  Future<void> play(Sfx sfx) async {
    if (!enabled) return;
    final binary = _resolveBinary();
    if (binary == null) return;
    final root = _resolveAssetsRoot();
    if (root == null) return;
    final path = p.join(root, 'assets', 'sfx', sfx.file);
    if (!File(path).existsSync()) return;
    try {
      await Process.start(
        binary,
        [...?_binaryArgs, path],
        mode: ProcessStartMode.detached,
        runInShell: false,
      );
    } catch (_) {
      // Headless / missing binary / sandbox — silently degrade.
    }
  }

  String? _resolveAssetsRoot() {
    if (_assetsRoot != null) return _assetsRoot;
    // Walk up from the running script until we find a pubspec.yaml.
    Directory? dir;
    try {
      dir = Directory.fromUri(Platform.script).parent;
    } catch (_) {
      dir = Directory.current;
    }
    for (var i = 0; i < 6; i++) {
      final pub = File(p.join(dir!.path, 'pubspec.yaml'));
      final assets = Directory(p.join(dir.path, 'assets'));
      if (pub.existsSync() && assets.existsSync()) {
        _assetsRoot = dir.path;
        return _assetsRoot;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    // Fallback: cwd.
    if (Directory(p.join(Directory.current.path, 'assets')).existsSync()) {
      _assetsRoot = Directory.current.path;
    }
    return _assetsRoot;
  }

  String? _resolveBinary() {
    if (_binary != null) return _binary;
    final candidates = <(String, List<String>)>[
      if (Platform.isMacOS) ('afplay', const <String>[]),
      if (Platform.isLinux) ...const [
        ('paplay', <String>[]),
        ('aplay', <String>['-q']),
        ('play', <String>['-q']),
      ],
      if (Platform.isWindows)
        (
          'powershell',
          const ['-NoProfile', '-Command', '\$p=[Console]::In.ReadLine();(New-Object Media.SoundPlayer \$p).PlaySync()']
        ),
    ];
    for (final (name, args) in candidates) {
      final result = _which(name);
      if (result != null) {
        _binary = result;
        _binaryArgs = args;
        return _binary;
      }
    }
    return null;
  }

  String? _which(String name) {
    try {
      final result = Process.runSync(
        Platform.isWindows ? 'where' : 'which',
        [name],
        runInShell: false,
      );
      if (result.exitCode == 0) {
        final out = (result.stdout as String).trim().split('\n').first.trim();
        if (out.isNotEmpty) return out;
      }
    } catch (_) {}
    return null;
  }
}
