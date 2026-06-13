import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedGame {
  const SavedGame({
    required this.id,
    required this.pgn,
    required this.result,
    required this.playedAt,
    required this.difficulty,
  });

  final String id;
  final String pgn;
  final String result;
  final DateTime playedAt;
  final String difficulty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'pgn': pgn,
        'result': result,
        'playedAt': playedAt.toIso8601String(),
        'difficulty': difficulty,
      };

  factory SavedGame.fromJson(Map<String, dynamic> json) => SavedGame(
        id: json['id'] as String,
        pgn: json['pgn'] as String,
        result: json['result'] as String,
        playedAt: DateTime.parse(json['playedAt'] as String),
        difficulty: json['difficulty'] as String,
      );
}

class GameRepository {
  GameRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _gamesKey = 'saved_games';

  List<SavedGame> loadAll() {
    final raw = _prefs.getString(_gamesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => SavedGame.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt));
  }

  Future<void> save(SavedGame game) async {
    final games = loadAll();
    games.removeWhere((g) => g.id == game.id);
    games.insert(0, game);
    await _prefs.setString(
      _gamesKey,
      jsonEncode(games.map((g) => g.toJson()).toList()),
    );
  }
}
