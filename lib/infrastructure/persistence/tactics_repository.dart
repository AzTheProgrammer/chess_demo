import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PuzzleAttempt {
  const PuzzleAttempt({
    required this.puzzleId,
    required this.solved,
    required this.attemptedAt,
    this.timeMs = 0,
  });

  final String puzzleId;
  final bool solved;
  final DateTime attemptedAt;
  final int timeMs;

  Map<String, dynamic> toJson() => {
        'puzzleId': puzzleId,
        'solved': solved,
        'attemptedAt': attemptedAt.toIso8601String(),
        'timeMs': timeMs,
      };

  factory PuzzleAttempt.fromJson(Map<String, dynamic> json) => PuzzleAttempt(
        puzzleId: json['puzzleId'] as String,
        solved: json['solved'] as bool? ?? false,
        attemptedAt: DateTime.parse(json['attemptedAt'] as String),
        timeMs: json['timeMs'] as int? ?? 0,
      );
}

class TacticsStats {
  const TacticsStats({
    this.totalAttempts = 0,
    this.totalSolved = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.localRating = 800,
    this.lastDailyPuzzleDate,
    this.lastDailyPuzzleId,
  });

  final int totalAttempts;
  final int totalSolved;
  final int currentStreak;
  final int bestStreak;
  final int localRating;
  final String? lastDailyPuzzleDate;
  final String? lastDailyPuzzleId;

  double get accuracy =>
      totalAttempts == 0 ? 0 : totalSolved / totalAttempts * 100;

  TacticsStats copyWith({
    int? totalAttempts,
    int? totalSolved,
    int? currentStreak,
    int? bestStreak,
    int? localRating,
    String? lastDailyPuzzleDate,
    String? lastDailyPuzzleId,
  }) {
    return TacticsStats(
      totalAttempts: totalAttempts ?? this.totalAttempts,
      totalSolved: totalSolved ?? this.totalSolved,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      localRating: localRating ?? this.localRating,
      lastDailyPuzzleDate: lastDailyPuzzleDate ?? this.lastDailyPuzzleDate,
      lastDailyPuzzleId: lastDailyPuzzleId ?? this.lastDailyPuzzleId,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalAttempts': totalAttempts,
        'totalSolved': totalSolved,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'localRating': localRating,
        'lastDailyPuzzleDate': lastDailyPuzzleDate,
        'lastDailyPuzzleId': lastDailyPuzzleId,
      };

  factory TacticsStats.fromJson(Map<String, dynamic> json) => TacticsStats(
        totalAttempts: json['totalAttempts'] as int? ?? 0,
        totalSolved: json['totalSolved'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        bestStreak: json['bestStreak'] as int? ?? 0,
        localRating: json['localRating'] as int? ?? 800,
        lastDailyPuzzleDate: json['lastDailyPuzzleDate'] as String?,
        lastDailyPuzzleId: json['lastDailyPuzzleId'] as String?,
      );
}

class TacticsRepository {
  TacticsRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _statsKey = 'tactics_stats';
  static const _attemptsKey = 'tactics_attempts';

  TacticsStats loadStats() {
    final raw = _prefs.getString(_statsKey);
    if (raw == null) return const TacticsStats();
    return TacticsStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveStats(TacticsStats stats) async {
    await _prefs.setString(_statsKey, jsonEncode(stats.toJson()));
  }

  List<PuzzleAttempt> loadAttempts() {
    final raw = _prefs.getString(_attemptsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PuzzleAttempt.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> recordAttempt(PuzzleAttempt attempt) async {
    final attempts = loadAttempts()..add(attempt);
    // Keep last 200 attempts
    final trimmed = attempts.length > 200
        ? attempts.sublist(attempts.length - 200)
        : attempts;
    await _prefs.setString(
      _attemptsKey,
      jsonEncode(trimmed.map((a) => a.toJson()).toList()),
    );
  }

  String todayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
