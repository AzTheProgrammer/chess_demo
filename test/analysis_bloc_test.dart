import 'package:bloc_test/bloc_test.dart';
import 'package:chess_app/features/analysis/bloc/analysis_bloc.dart';
import 'package:chess_app/infrastructure/chess/game_record.dart';
import 'package:chess_app/infrastructure/import/game_import_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeImportService extends GameImportService {
  _FakeImportService(this.record);

  final GameRecord record;

  @override
  GameRecord importPgn(String rawPgn, {GameSource source = GameSource.paste}) {
    return record;
  }
}

void main() {
  const pgn = '''
[Event "Test"]
[White "A"]
[Black "B"]
[Result "*"]

1. e4 e5 2. Nf3 *
''';

  late GameRecord record;

  setUp(() {
    record = GameImportService().importPgn(pgn);
  });

  blocTest<AnalysisBloc, AnalysisState>(
    'loads pasted pgn into ready state',
    build: () => AnalysisBloc(imports: _FakeImportService(record)),
    act: (bloc) async {
      bloc.add(const AnalysisImportPasted(pgn));
      await bloc.stream.firstWhere((s) => s.status == AnalysisStatus.ready);
    },
    verify: (bloc) {
      expect(bloc.state.game?.moveSans.first, 'e4');
      expect(bloc.state.halfMoveIndex, 0);
    },
  );

  blocTest<AnalysisBloc, AnalysisState>(
    'steps forward through loaded game',
    build: () => AnalysisBloc(imports: _FakeImportService(record)),
    seed: () => AnalysisState(status: AnalysisStatus.ready, game: record),
    act: (bloc) {
      bloc.add(const AnalysisStepForward());
      bloc.add(const AnalysisStepForward());
    },
    verify: (bloc) {
      expect(bloc.state.halfMoveIndex, 2);
    },
  );

  blocTest<AnalysisBloc, AnalysisState>(
    'flip board toggles orientation',
    build: () => AnalysisBloc(imports: _FakeImportService(record)),
    seed: () => AnalysisState(
      status: AnalysisStatus.ready,
      game: record,
      halfMoveIndex: 1,
    ),
    act: (bloc) => bloc.add(const AnalysisFlipBoard()),
    expect: () => [
      isA<AnalysisState>().having(
        (s) => s.orientation.name,
        'orientation',
        'black',
      ),
    ],
  );
}
