import 'package:chess/chess.dart' as chess;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../infrastructure/bot/bot_service.dart';
import '../../../infrastructure/persistence/game_repository.dart';
import '../../../infrastructure/persistence/settings_repository.dart';

part 'play_event.dart';
part 'play_state.dart';

class PlayBloc extends Bloc<PlayEvent, PlayState> {
  PlayBloc({
    required BotService bot,
    required GameRepository games,
    required BotDifficulty difficulty,
  })  : _bot = bot,
        _games = games,
        super(PlayState.initial(difficulty: difficulty)) {
    on<PlayStarted>(_onStarted);
    on<PlayerMoved>(_onPlayerMoved);
    on<PlayReset>(_onReset);
  }

  final BotService _bot;
  final GameRepository _games;

  Future<void> _onStarted(PlayStarted event, Emitter<PlayState> emit) async {
    emit(state.copyWith(
      status: PlayStatus.loading,
      fen: chess.Chess.DEFAULT_POSITION,
      moveSans: const [],
      lastMove: null,
      gameOver: false,
      result: null,
      message: 'Starting engine…',
    ));
    try {
      await _bot.start();
      emit(state.copyWith(
        status: PlayStatus.playing,
        message: _bot.isEngineReady
            ? 'Your move (white)'
            : 'Your move — using fallback bot on this platform',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: PlayStatus.playing,
        message: 'Engine unavailable; using fallback bot ($error)',
      ));
    }
  }

  Future<void> _onPlayerMoved(PlayerMoved event, Emitter<PlayState> emit) async {
    if (state.status != PlayStatus.playing || state.gameOver) return;

    final game = chess.Chess.fromFEN(state.fen);
    final moved = game.move({
      'from': event.from,
      'to': event.to,
      'promotion': event.promotion,
    });
    if (moved != true) return;

    final nextFen = game.fen;
    final san = game.san_moves().last ?? '${event.from}${event.to}';
    final moveSans = [...state.moveSans, san];
    final lastMove = (from: event.from, to: event.to);

    if (_isGameOver(game)) {
      final result = gameResultLabel(game);
      await _persistGame(moveSans, result);
      emit(state.copyWith(
        fen: nextFen,
        moveSans: moveSans,
        lastMove: lastMove,
        gameOver: true,
        result: result,
        message: _resultMessage(result),
      ));
      return;
    }

    emit(state.copyWith(
      fen: nextFen,
      moveSans: moveSans,
      lastMove: lastMove,
      status: PlayStatus.botThinking,
      message: 'Bot is thinking…',
    ));

    try {
      final uci = await _bot.pickMove(fen: nextFen, difficulty: state.difficulty);
      if (uci == null) {
        emit(state.copyWith(
          status: PlayStatus.playing,
          message: 'Bot has no legal moves',
        ));
        return;
      }
      final botGame = chess.Chess.fromFEN(nextFen);
      final botFrom = uci.substring(0, 2);
      final botTo = uci.substring(2, 4);
      final botPromotion = uci.length > 4 ? uci[4] : null;
      final botMoved = botGame.move({
        'from': botFrom,
        'to': botTo,
        'promotion': botPromotion,
      });
      if (botMoved != true) {
        emit(state.copyWith(
          status: PlayStatus.playing,
          message: 'Bot returned illegal move',
        ));
        return;
      }
      final afterBot = botGame.fen;
      final botSan = botGame.san_moves().last ?? uci;
      final allMoves = [...moveSans, botSan];

      if (_isGameOver(botGame)) {
        final result = gameResultLabel(botGame);
        await _persistGame(allMoves, result);
        emit(state.copyWith(
          fen: afterBot,
          moveSans: allMoves,
          lastMove: (from: botFrom, to: botTo),
          gameOver: true,
          result: result,
          status: PlayStatus.playing,
          message: _resultMessage(result),
        ));
        return;
      }

      emit(state.copyWith(
        fen: afterBot,
        moveSans: allMoves,
        lastMove: (from: botFrom, to: botTo),
        status: PlayStatus.playing,
        message: 'Your move',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: PlayStatus.playing,
        message: 'Bot error: $error',
      ));
    }
  }

  void _onReset(PlayReset event, Emitter<PlayState> emit) {
    emit(PlayState.initial(difficulty: state.difficulty));
    add(const PlayStarted());
  }

  bool _isGameOver(chess.Chess game) {
    return game.in_checkmate || game.in_stalemate || game.in_draw;
  }

  String _resultMessage(String result) {
    return switch (result) {
      '1-0' => 'Checkmate — you win!',
      '0-1' => 'Checkmate — bot wins',
      '1/2-1/2' => 'Draw',
      _ => 'Game over',
    };
  }

  Future<void> _persistGame(List<String> moveSans, String result) async {
    final pgn = buildPgn(moveSans: moveSans, result: result);
    await _games.save(
      SavedGame(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        pgn: pgn,
        result: result,
        playedAt: DateTime.now(),
        difficulty: state.difficulty.name,
      ),
    );
  }

  @override
  Future<void> close() {
    _bot.dispose();
    return super.close();
  }
}
