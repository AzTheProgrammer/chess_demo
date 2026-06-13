import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/settings/cubit/settings_cubit.dart';
import 'infrastructure/import/game_import_service.dart';
import 'infrastructure/persistence/game_repository.dart';
import 'infrastructure/persistence/settings_repository.dart';
import 'infrastructure/persistence/openings_repository.dart';
import 'infrastructure/persistence/tactics_repository.dart';
import 'infrastructure/persistence/square_trainer_repository.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final settingsRepo = SettingsRepository(prefs);
  final gameRepo = GameRepository(prefs);
  final trainerRepo = SquareTrainerRepository(prefs);
  final openingsRepo = OpeningsRepository(prefs);
  final tacticsRepo = TacticsRepository(prefs);
  final importService = GameImportService();
  final settingsCubit = SettingsCubit(settingsRepo)..load();

  runApp(ChessApp(
    settingsCubit: settingsCubit,
    gameRepository: gameRepo,
    trainerRepository: trainerRepo,
    openingsRepository: openingsRepo,
    tacticsRepository: tacticsRepo,
    importService: importService,
  ));
}

class ChessApp extends StatelessWidget {
  const ChessApp({
    super.key,
    required this.settingsCubit,
    required this.gameRepository,
    required this.trainerRepository,
    required this.openingsRepository,
    required this.tacticsRepository,
    required this.importService,
  });

  final SettingsCubit settingsCubit;
  final GameRepository gameRepository;
  final SquareTrainerRepository trainerRepository;
  final OpeningsRepository openingsRepository;
  final TacticsRepository tacticsRepository;
  final GameImportService importService;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: gameRepository),
        RepositoryProvider.value(value: trainerRepository),
        RepositoryProvider.value(value: openingsRepository),
        RepositoryProvider.value(value: tacticsRepository),
        RepositoryProvider.value(value: importService),
        RepositoryProvider.value(value: settingsCubit.repository),
      ],
      child: BlocProvider.value(
        value: settingsCubit,
        child: MaterialApp.router(
          title: 'Chess App',
          theme: AppTheme.dark(),
          routerConfig: createRouter(),
        ),
      ),
    );
  }
}
