import 'package:bloc_test/bloc_test.dart';
import 'package:chess_app/features/openings/bloc/openings_bloc.dart';
import 'package:chess_app/infrastructure/persistence/openings_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OpeningsRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = OpeningsRepository(prefs);
  });

  group('OpeningsBloc', () {
    blocTest<OpeningsBloc, OpeningsState>(
      'loads opening lines',
      build: () => OpeningsBloc(repository: repo),
      act: (bloc) => bloc.add(const OpeningsLoadRequested()),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.loading, isFalse);
        expect(bloc.state.lines, isNotEmpty);
      },
    );

    blocTest<OpeningsBloc, OpeningsState>(
      'starts drill and auto-plays opponent move',
      build: () => OpeningsBloc(repository: repo),
      seed: () => const OpeningsState(loading: false),
      act: (bloc) async {
        bloc.add(const OpeningsLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final whiteLine = bloc.state.lines.firstWhere((l) => l.isUserWhite);
        bloc.add(OpeningDrillStarted(whiteLine.id));
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.phase, OpeningsPhase.drilling);
        expect(bloc.state.moveIndex, 0);
        expect(bloc.state.message, contains('Your move'));
      },
    );
  });
}
