import 'dart:async';
import 'dart:convert';
import 'dart:io';

class TuiCommand {
  const TuiCommand({
    required this.id,
    required this.name,
    required this.description,
    required this.keys,
    required this.action,
    required this.payload,
  });

  final String id;
  final String name;
  final String description;
  final String keys;
  final String action;
  final Map<String, dynamic> payload;

  factory TuiCommand.fromJson(Map<String, dynamic> j) => TuiCommand(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        keys: (j['keys'] ?? '').toString(),
        action: (j['action'] ?? 'noop').toString(),
        payload: (j['payload'] is Map)
            ? Map<String, dynamic>.from(j['payload'] as Map)
            : <String, dynamic>{},
      );
}

class CommandBundle {
  const CommandBundle({
    required this.version,
    required this.publishedAt,
    required this.commands,
  });

  final String version;
  final String publishedAt;
  final List<TuiCommand> commands;

  factory CommandBundle.fromJson(Map<String, dynamic> j) => CommandBundle(
        version: (j['version'] ?? '0').toString(),
        publishedAt: (j['publishedAt'] ?? '').toString(),
        commands: ((j['commands'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => TuiCommand.fromJson(Map<String, dynamic>.from(m)))
            .toList(growable: false),
      );

  static const empty = CommandBundle(version: '0', publishedAt: '', commands: []);
}

/// Loads command bundles from the remote update endpoint and caches the last
/// successful payload on disk so the pane is usable offline.
class CommandsRepository {
  CommandsRepository({String? endpoint, String? cacheDir})
      : endpoint = endpoint ??
            Platform.environment['CHESSEVER_TUI_COMMANDS_URL'] ??
            'https://tui.chessever.com/commands.json',
        _cachePath = _resolveCachePath(cacheDir);

  final String endpoint;
  final String _cachePath;

  static String _resolveCachePath(String? override) {
    if (override != null && override.isNotEmpty) return override;
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.systemTemp.path;
    return '$home/.chessever-tui/commands.json';
  }

  Future<CommandBundle> loadCached() async {
    try {
      final f = File(_cachePath);
      if (!await f.exists()) return CommandBundle.empty;
      final raw = await f.readAsString();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return CommandBundle.fromJson(data);
    } catch (_) {
      return CommandBundle.empty;
    }
  }

  Future<CommandBundle> fetchRemote({Duration timeout = const Duration(seconds: 6)}) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final req = await client.getUrl(Uri.parse(endpoint)).timeout(timeout);
      req.headers.set(HttpHeaders.userAgentHeader, 'chessever-tui');
      final res = await req.close().timeout(timeout);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw HttpException('HTTP ${res.statusCode}');
      }
      final body = await res.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final bundle = CommandBundle.fromJson(data);
      await _writeCache(body);
      return bundle;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _writeCache(String raw) async {
    try {
      final f = File(_cachePath);
      await f.parent.create(recursive: true);
      await f.writeAsString(raw, flush: true);
    } catch (_) {
      // Cache write failures are non-fatal.
    }
  }
}
