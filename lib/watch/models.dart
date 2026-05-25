// Pure-Dart models mirroring the Chessever broadcasts schema.
// Trimmed to fields the TUI actually renders. Source of truth is
// chessever-frontend `lib/repository/supabase/**`.
import 'dart:convert';

class GroupBroadcast {
  GroupBroadcast({
    required this.id,
    required this.name,
    required this.search,
    this.maxAvgElo,
    this.dateStart,
    this.dateEnd,
    this.timeControl,
  });

  final String id;
  final String name;
  final List<String> search;
  final int? maxAvgElo;
  final DateTime? dateStart;
  final DateTime? dateEnd;
  final String? timeControl;

  factory GroupBroadcast.fromJson(Map<String, dynamic> json) => GroupBroadcast(
        id: json['id'].toString(),
        name: json['name']?.toString() ?? '(untitled)',
        search: _stringList(json['search']),
        maxAvgElo: _toInt(json['max_avg_elo']),
        dateStart: _toDate(json['date_start']),
        dateEnd: _toDate(json['date_end']),
        timeControl: json['time_control']?.toString(),
      );
}

class TourLite {
  const TourLite({required this.id, required this.slug, this.avgElo});

  final String id;
  final String slug;
  final int? avgElo;

  factory TourLite.fromJson(Map<String, dynamic> json) => TourLite(
        id: json['id'].toString(),
        slug: json['slug']?.toString() ?? '',
        avgElo: _toInt(json['avg_elo']),
      );
}

class RoundLite {
  const RoundLite({
    required this.id,
    required this.tourId,
    required this.name,
    this.startsAt,
  });

  final String id;
  final String tourId;
  final String name;
  final DateTime? startsAt;

  factory RoundLite.fromJson(Map<String, dynamic> json) => RoundLite(
        id: json['id'].toString(),
        tourId: json['tour_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        startsAt: _toDate(json['starts_at']),
      );
}

class GamePlayer {
  const GamePlayer({
    required this.name,
    required this.title,
    required this.rating,
    required this.fed,
    required this.clock,
  });

  final String name;
  final String title;
  final int rating;
  final String fed;
  final int clock; // milliseconds remaining

  factory GamePlayer.fromJson(Map<String, dynamic> json) => GamePlayer(
        name: json['name']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        rating: _toInt(json['rating']) ?? 0,
        fed: json['fed']?.toString() ?? '',
        clock: _toInt(json['clock']) ?? 0,
      );

  String get displayName => title.isEmpty ? name : '$title $name';
}

class GameSnapshot {
  GameSnapshot({
    required this.id,
    required this.roundId,
    this.fen,
    this.players,
    this.lastMove,
    this.status,
    this.pgn,
    this.lastMoveTime,
    this.lastClockWhite,
    this.lastClockBlack,
    this.openingName,
    this.eco,
  });

  final String id;
  final String roundId;
  final String? fen;
  final List<GamePlayer>? players;
  final String? lastMove;
  final String? status;
  final String? pgn;
  final DateTime? lastMoveTime;
  final int? lastClockWhite; // milliseconds
  final int? lastClockBlack;
  final String? openingName;
  final String? eco;

  GamePlayer? get white => players != null && players!.isNotEmpty
      ? players![0]
      : null;
  GamePlayer? get black => players != null && players!.length > 1
      ? players![1]
      : null;

  bool get isLive => status == '*' || status == null;

  factory GameSnapshot.fromJson(Map<String, dynamic> json) {
    List<GamePlayer>? players;
    final raw = json['players'];
    if (raw is List) {
      players = raw
          .map((e) => GamePlayer.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          players = decoded
              .map((e) => GamePlayer.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {/* tolerate malformed players blob */}
    }
    return GameSnapshot(
      id: json['id'].toString(),
      roundId: json['round_id']?.toString() ?? '',
      fen: json['fen']?.toString(),
      players: players,
      lastMove: json['last_move']?.toString(),
      status: json['status']?.toString(),
      pgn: json['pgn']?.toString(),
      lastMoveTime: _toDate(json['last_move_time']),
      lastClockWhite: _toInt(json['last_clock_white']),
      lastClockBlack: _toInt(json['last_clock_black']),
      openingName: json['opening_name']?.toString(),
      eco: json['eco']?.toString(),
    );
  }
}

enum TourEventCategory { live, ongoing, upcoming, completed }

class BroadcastCard {
  const BroadcastCard({
    required this.broadcast,
    required this.category,
  });

  final GroupBroadcast broadcast;
  final TourEventCategory category;

  String get id => broadcast.id;
  String get title => broadcast.name;
  int? get maxAvgElo => broadcast.maxAvgElo;
  DateTime? get start => broadcast.dateStart;
  DateTime? get end => broadcast.dateEnd;
  String? get timeControl => broadcast.timeControl;

  static TourEventCategory categorize(
    GroupBroadcast b,
    Set<String> liveIds,
    DateTime now,
  ) {
    if (liveIds.contains(b.id) || liveIds.contains(b.name)) {
      return TourEventCategory.live;
    }
    final start = b.dateStart;
    final end = b.dateEnd;
    if (start != null && now.isBefore(start)) return TourEventCategory.upcoming;
    if (end != null && now.isAfter(end)) return TourEventCategory.completed;
    return TourEventCategory.ongoing;
  }
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

List<String> _stringList(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  return const <String>[];
}
