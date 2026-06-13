import 'package:bloc_test/bloc_test.dart';
import 'package:chess_app/features/tactics/bloc/tactics_bloc.dart';
import 'package:chess_app/infrastructure/persistence/tactics_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TacticsRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = TacticsRepository(prefs);
  });

  group('TacticsBloc', () {
    blocTest<TacticsBloc, TacticsState>(
      'loads puzzles',
      build: () => TacticsBloc(repository: repo),
      act: (bloc) => bloc.add(const TacticsLoadRequested()),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.loading, isFalse);
        expect(bloc.state.puzzles.length, greaterThanOrEqualTo(10));
      },
    );

    blocTest<TacticsBloc, TacticsState>(
      'practice queue starts with 10 puzzles',
      build: () => TacticsBloc(repository: repo),
      act: (bloc) async {
        bloc.add(const TacticsLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const TacticsPracticeStarted());
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.phase, TacticsPhase.solving);
        expect(bloc.state.queue.length, 10);
        expect(bloc.state.currentPuzzle, isNotNull);
      },
    );
  });
}
