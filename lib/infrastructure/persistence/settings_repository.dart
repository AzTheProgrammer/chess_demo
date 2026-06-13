import 'package:shared_preferences/shared_preferences.dart';

enum BotDifficulty { beginner, intermediate, advanced }

enum BoardTheme { classic, midnight, tournament }

class AppSettings {
  const AppSettings({
    this.difficulty = BotDifficulty.beginner,
    this.boardTheme = BoardTheme.classic,
    this.showCoordinates = true,
  });

  final BotDifficulty difficulty;
  final BoardTheme boardTheme;
  final bool showCoordinates;

  AppSettings copyWith({
    BotDifficulty? difficulty,
    BoardTheme? boardTheme,
    bool? showCoordinates,
  }) {
    return AppSettings(
      difficulty: difficulty ?? this.difficulty,
      boardTheme: boardTheme ?? this.boardTheme,
      showCoordinates: showCoordinates ?? this.showCoordinates,
    );
  }
}

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _difficultyKey = 'settings_difficulty';
  static const _boardThemeKey = 'settings_board_theme';
  static const _coordinatesKey = 'settings_show_coordinates';

  AppSettings load() {
    return AppSettings(
      difficulty: BotDifficulty.values[
          _prefs.getInt(_difficultyKey) ?? BotDifficulty.beginner.index],
      boardTheme: BoardTheme
          .values[_prefs.getInt(_boardThemeKey) ?? BoardTheme.classic.index],
      showCoordinates: _prefs.getBool(_coordinatesKey) ?? true,
    );
  }

  Future<void> save(AppSettings settings) async {
    await _prefs.setInt(_difficultyKey, settings.difficulty.index);
    await _prefs.setInt(_boardThemeKey, settings.boardTheme.index);
    await _prefs.setBool(_coordinatesKey, settings.showCoordinates);
  }
}

int depthForDifficulty(BotDifficulty difficulty) {
  return switch (difficulty) {
    BotDifficulty.beginner => 1,
    BotDifficulty.intermediate => 8,
    BotDifficulty.advanced => 14,
  };
}
