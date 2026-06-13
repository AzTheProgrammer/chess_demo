import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OpeningProgress {
  const OpeningProgress({
    this.masteryScore = 0,
    this.lastPracticed,
    this.successfulDrills = 0,
    this.totalDrills = 0,
  });

  final int masteryScore;
  final DateTime? lastPracticed;
  final int successfulDrills;
  final int totalDrills;

  OpeningProgress copyWith({
    int? masteryScore,
    DateTime? lastPracticed,
    int? successfulDrills,
    int? totalDrills,
  }) {
    return OpeningProgress(
      masteryScore: masteryScore ?? this.masteryScore,
      lastPracticed: lastPracticed ?? this.lastPracticed,
      successfulDrills: successfulDrills ?? this.successfulDrills,
      totalDrills: totalDrills ?? this.totalDrills,
    );
  }

  Map<String, dynamic> toJson() => {
        'masteryScore': masteryScore,
        'lastPracticed': lastPracticed?.toIso8601String(),
        'successfulDrills': successfulDrills,
        'totalDrills': totalDrills,
      };

  factory OpeningProgress.fromJson(Map<String, dynamic> json) {
    final last = json['lastPracticed'] as String?;
    return OpeningProgress(
      masteryScore: json['masteryScore'] as int? ?? 0,
      lastPracticed: last != null ? DateTime.tryParse(last) : null,
      successfulDrills: json['successfulDrills'] as int? ?? 0,
      totalDrills: json['totalDrills'] as int? ?? 0,
    );
  }
}

class OpeningsRepository {
  OpeningsRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _progressKey = 'opening_progress';

  Map<String, OpeningProgress> loadAllProgress() {
    final raw = _prefs.getString(_progressKey);
    if (raw == null) return {};
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return json.map(
      (key, value) => MapEntry(
        key,
        OpeningProgress.fromJson(value as Map<String, dynamic>),
      ),
    );
  }

  OpeningProgress progressFor(String lineId) {
    return loadAllProgress()[lineId] ?? const OpeningProgress();
  }

  Future<void> saveProgress(String lineId, OpeningProgress progress) async {
    final all = loadAllProgress();
    all[lineId] = progress;
    await _prefs.setString(
      _progressKey,
      jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  /// Spaced-repetition lite: lines with lower mastery or older practice rank first.
  int compareForReview(String aId, String bId) {
    final all = loadAllProgress();
    final a = all[aId] ?? const OpeningProgress();
    final b = all[bId] ?? const OpeningProgress();
    if (a.masteryScore != b.masteryScore) {
      return a.masteryScore.compareTo(b.masteryScore);
    }
    final aTime = a.lastPracticed?.millisecondsSinceEpoch ?? 0;
    final bTime = b.lastPracticed?.millisecondsSinceEpoch ?? 0;
    return aTime.compareTo(bTime);
  }
}
