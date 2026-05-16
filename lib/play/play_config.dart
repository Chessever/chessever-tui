import 'package:dartchess/dartchess.dart';

class TimeControl {
  const TimeControl({
    required this.name,
    required this.initial,
    required this.increment,
  });

  final String name;
  final Duration initial;
  final Duration increment;

  int get initialMinutes => initial.inMinutes;
  int get incrementSeconds => increment.inSeconds;

  String get label => '$initialMinutes+$incrementSeconds';

  static const bullet = TimeControl(
    name: 'bullet',
    initial: Duration(minutes: 1),
    increment: Duration.zero,
  );

  static const blitz = TimeControl(
    name: 'blitz',
    initial: Duration(minutes: 3),
    increment: Duration.zero,
  );

  static const rapid = TimeControl(
    name: 'rapid',
    initial: Duration(minutes: 10),
    increment: Duration.zero,
  );

  static const values = [bullet, blitz, rapid];

  static TimeControl? tryParse(String token) {
    final normalized = token.toLowerCase().trim();
    for (final value in values) {
      if (value.name == normalized || value.label == normalized) return value;
    }

    final match = RegExp(r'^(\d{1,2})\+(\d{1,2})$').firstMatch(normalized);
    if (match == null) return null;
    final minutes = int.tryParse(match.group(1)!);
    final increment = int.tryParse(match.group(2)!);
    if (minutes == null || increment == null || minutes <= 0) return null;
    return TimeControl(
      name: '$minutes+$increment',
      initial: Duration(minutes: minutes),
      increment: Duration(seconds: increment),
    );
  }
}

class PlayConfig {
  const PlayConfig({
    required this.humanSide,
    required this.elo,
    required this.timeControl,
  });

  final Side humanSide;
  final int elo;
  final TimeControl timeControl;

  static const defaultGame = PlayConfig(
    humanSide: Side.white,
    elo: 1500,
    timeControl: TimeControl.blitz,
  );

  PlayConfig copyWith({
    Side? humanSide,
    int? elo,
    TimeControl? timeControl,
  }) {
    return PlayConfig(
      humanSide: humanSide ?? this.humanSide,
      elo: elo ?? this.elo,
      timeControl: timeControl ?? this.timeControl,
    );
  }
}

const maiaElos = [1100, 1300, 1500, 1700, 1900];
