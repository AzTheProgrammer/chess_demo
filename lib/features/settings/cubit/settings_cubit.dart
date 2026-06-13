import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../infrastructure/persistence/settings_repository.dart';

class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(this._repository) : super(const AppSettings());

  final SettingsRepository _repository;
  SettingsRepository get repository => _repository;

  void load() {
    emit(_repository.load());
  }

  Future<void> setDifficulty(BotDifficulty difficulty) async {
    final next = state.copyWith(difficulty: difficulty);
    emit(next);
    await _repository.save(next);
  }

  Future<void> setBoardTheme(BoardTheme theme) async {
    final next = state.copyWith(boardTheme: theme);
    emit(next);
    await _repository.save(next);
  }

  Future<void> setShowCoordinates(bool value) async {
    final next = state.copyWith(showCoordinates: value);
    emit(next);
    await _repository.save(next);
  }
}
