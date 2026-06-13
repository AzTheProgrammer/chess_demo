import 'package:chess_app/main.dart';
import 'package:chess_app/infrastructure/import/game_import_service.dart';
import 'package:chess_app/infrastructure/persistence/game_repository.dart';
import 'package:chess_app/infrastructure/persistence/settings_repository.dart';
import 'package:chess_app/infrastructure/persistence/openings_repository.dart';
import 'package:chess_app/infrastructure/persistence/tactics_repository.dart';
import 'package:chess_app/infrastructure/persistence/square_trainer_repository.dart';
import 'package:chess_app/features/settings/cubit/settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app smoke test — home screen loads', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settingsCubit = SettingsCubit(SettingsRepository(prefs))..load();

    await tester.pumpWidget(ChessApp(
      settingsCubit: settingsCubit,
      gameRepository: GameRepository(prefs),
      trainerRepository: SquareTrainerRepository(prefs),
      openingsRepository: OpeningsRepository(prefs),
      tacticsRepository: TacticsRepository(prefs),
      importService: GameImportService(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Chess'), findsOneWidget);
    expect(find.text('Play vs Bot'), findsOneWidget);
    expect(find.text('Openings, tactics & square drills'), findsOneWidget);
  });
}
