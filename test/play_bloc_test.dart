import 'package:bloc_test/bloc_test.dart';
import 'package:chess/chess.dart' as chess;
import 'package:chess_app/features/play/bloc/play_bloc.dart';
import 'package:chess_app/infrastructure/bot/bot_service.dart';
import 'package:chess_app/infrastructure/persistence/game_repository.dart';
import 'package:chess_app/infrastructure/persistence/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayBloc', () {
    late GameRepository games;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      games = GameRepository(prefs);
    });

    blocTest<PlayBloc, PlayState>(
      'starts in playing state after PlayStarted',
      build: () => PlayBloc(
        bot: BotService(),
        games: games,
        difficulty: BotDifficulty.beginner,
      ),
      act: (bloc) => bloc.add(const PlayStarted()),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<PlayState>().having((s) => s.status, 'status', PlayStatus.loading),
        isA<PlayState>().having((s) => s.status, 'status', PlayStatus.playing),
      ],
    );

    blocTest<PlayBloc, PlayState>(
      'applies legal player move e2-e4',
      build: () => PlayBloc(
        bot: BotService(),
        games: games,
        difficulty: BotDifficulty.beginner,
      ),
      seed: () => PlayState.initial(difficulty: BotDifficulty.beginner).copyWith(
        status: PlayStatus.playing,
      ),
      act: (bloc) => bloc.add(const PlayerMoved(from: 'e2', to: 'e4')),
      wait: const Duration(seconds: 2),
      verify: (bloc) {
        expect(bloc.state.fen, isNot(chess.Chess.DEFAULT_POSITION));
        expect(bloc.state.moveSans, isNotEmpty);
      },
    );
  });
}
