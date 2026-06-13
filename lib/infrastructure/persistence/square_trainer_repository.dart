import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SquareTrainerStats {
  const SquareTrainerStats({
    this.bestStreak = 0,
    this.bestTimedScore = 0,
    this.totalCorrect = 0,
    this.totalAttempts = 0,
  });

  final int bestStreak;
  final int bestTimedScore;
  final int totalCorrect;
  final int totalAttempts;

  double get accuracy =>
      totalAttempts == 0 ? 0 : totalCorrect / totalAttempts * 100;

  SquareTrainerStats copyWith({
    int? bestStreak,
    int? bestTimedScore,
    int? totalCorrect,
    int? totalAttempts,
  }) {
    return SquareTrainerStats(
      bestStreak: bestStreak ?? this.bestStreak,
      bestTimedScore: bestTimedScore ?? this.bestTimedScore,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      totalAttempts: totalAttempts ?? this.totalAttempts,
    );
  }

  Map<String, dynamic> toJson() => {
        'bestStreak': bestStreak,
        'bestTimedScore': bestTimedScore,
        'totalCorrect': totalCorrect,
        'totalAttempts': totalAttempts,
      };

  factory SquareTrainerStats.fromJson(Map<String, dynamic> json) =>
      SquareTrainerStats(
        bestStreak: json['bestStreak'] as int? ?? 0,
        bestTimedScore: json['bestTimedScore'] as int? ?? 0,
        totalCorrect: json['totalCorrect'] as int? ?? 0,
        totalAttempts: json['totalAttempts'] as int? ?? 0,
      );
}

class SquareTrainerRepository {
  SquareTrainerRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _statsKey = 'square_trainer_stats';

  SquareTrainerStats load() {
    final raw = _prefs.getString(_statsKey);
    if (raw == null) return const SquareTrainerStats();
    return SquareTrainerStats.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> save(SquareTrainerStats stats) async {
    await _prefs.setString(_statsKey, jsonEncode(stats.toJson()));
  }
}
