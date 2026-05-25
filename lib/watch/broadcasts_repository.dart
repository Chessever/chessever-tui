import 'dart:async';

import 'package:chessever_tui/watch/config.dart';
import 'package:chessever_tui/watch/models.dart';
import 'package:supabase/supabase.dart';

/// Lazy singleton Supabase client. Constructed on first watch-tab use so
/// the play and settings panes don't pay the websocket/auth init cost.
class WatchSupabase {
  WatchSupabase._(this.client);

  final SupabaseClient client;

  static WatchSupabase? _instance;
  static WatchSupabase instance() {
    final cached = _instance;
    if (cached != null) return cached;
    final client = SupabaseClient(
      WatchConfig.supabaseUrl,
      WatchConfig.supabaseAnonKey,
    );
    _instance = WatchSupabase._(client);
    return _instance!;
  }
}

class BroadcastsRepository {
  BroadcastsRepository({SupabaseClient? client})
      : _supabase = client ?? WatchSupabase.instance().client;

  final SupabaseClient _supabase;

  /// One-shot fetch of currently-running broadcasts.
  /// Mirrors `group_tour_repository.dart:getCurrentGroupBroadcasts`.
  Future<List<GroupBroadcast>> fetchCurrent({
    int limit = 50,
    String orderBy = 'max_avg_elo',
    bool ascending = false,
  }) async {
    final rows = await _supabase
        .from('group_broadcasts_current')
        .select()
        .order(orderBy, ascending: ascending)
        .limit(limit);
    return _decodeBroadcasts(rows);
  }

  Future<List<GroupBroadcast>> fetchUpcoming({int limit = 50}) async {
    final rows = await _supabase
        .from('group_broadcasts_upcoming')
        .select()
        .order('date_start', ascending: true)
        .limit(limit);
    return _decodeBroadcasts(rows);
  }

  /// Realtime stream of live broadcast IDs from `settings.live_group_broadcast_ids`.
  Stream<List<String>> subscribeLiveGroupBroadcastIds() {
    return _supabase.from('settings').stream(primaryKey: ['id']).map((rows) {
      if (rows.isEmpty) return const <String>[];
      final raw = rows.first['live_group_broadcast_ids'];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return const <String>[];
    });
  }

  /// Pull rounds for a given broadcast. Broadcasts have tours; tours have
  /// rounds. We use group_broadcasts → tours join to find tour ids first.
  Future<List<RoundLite>> fetchRoundsForBroadcast(String broadcastId) async {
    final tourRows = await _supabase
        .from('tours')
        .select('id')
        .eq('group_broadcast_id', broadcastId);
    final tourIds = (tourRows as List)
        .map((r) => (r as Map<String, dynamic>)['id'].toString())
        .toList();
    if (tourIds.isEmpty) return const <RoundLite>[];

    final roundRows = await _supabase
        .from('rounds')
        .select()
        .inFilter('tour_id', tourIds)
        .order('starts_at', ascending: false)
        .limit(40);
    return roundRows.map((r) => RoundLite.fromJson(r)).toList();
  }

  /// Realtime games for a round (FEN, clocks, last move stream live).
  Stream<List<GameSnapshot>> subscribeGamesByRound(String roundId) {
    return _supabase
        .from('games')
        .stream(primaryKey: ['id'])
        .eq('round_id', roundId)
        .order('board_nr')
        .map((rows) => rows.map(GameSnapshot.fromJson).toList());
  }

  Future<List<GameSnapshot>> fetchGamesByRound(String roundId) async {
    final rows = await _supabase
        .from('games')
        .select()
        .eq('round_id', roundId)
        .order('board_nr', ascending: true)
        .limit(40);
    return rows.map(GameSnapshot.fromJson).toList();
  }

  List<GroupBroadcast> _decodeBroadcasts(dynamic rows) {
    if (rows is! List) return const <GroupBroadcast>[];
    return rows
        .map((r) => GroupBroadcast.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
