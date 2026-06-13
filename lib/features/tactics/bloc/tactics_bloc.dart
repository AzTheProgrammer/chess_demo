import 'package:chess/chess.dart' as chess;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../infrastructure/chess/tactic_puzzle.dart';
import '../../../infrastructure/chess/training_catalog.dart';
import '../../../infrastructure/persistence/tactics_repository.dart';

part 'tactics_event.dart';
part 'tactics_state.dart';

class TacticsBloc extends Bloc<TacticsEvent, TacticsState> {
  TacticsBloc({required TacticsRepository repository})
      : _repository = repository,
        super(TacticsState(todayKey: repository.todayKey(DateTime.now()))) {
    on<TacticsLoadRequested>(_onLoad);
    on<TacticsDailyStarted>(_onDailyStarted);
    on<TacticsPracticeStarted>(_onPracticeStarted);
    on<TacticsUserMoved>(_onUserMoved);
    on<TacticsNextPuzzle>(_onNextPuzzle);
    on<TacticsShowSolution>(_onShowSolution);
    on<TacticsSessionEnded>(_onSessionEnded);
  }

  final TacticsRepository _repository;

  Future<void> _onLoad(
    TacticsLoadRequested event,
    Emitter<TacticsState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    final puzzles = await TrainingCatalog.loadPuzzles();
    emit(state.copyWith(
      loading: false,
      puzzles: puzzles,
      stats: _repository.loadStats(),
      todayKey: _repository.todayKey(DateTime.now()),
    ));
  }

  void _onDailyStarted(TacticsDailyStarted event, Emitter<TacticsState> emit) {
    final puzzle = state.dailyPuzzle;
    if (puzzle == null) return;
    _startPuzzle(
      emit,
      puzzle: puzzle,
      mode: TacticsMode.daily,
      queue: [puzzle],
      queueIndex: 0,
    );
  }

  void _onPracticeStarted(
    TacticsPracticeStarted event,
    Emitter<TacticsState> emit,
  ) {
    if (state.puzzles.isEmpty) return;
    final queue = state.puzzles.take(10).toList();
    _startPuzzle(
      emit,
      puzzle: queue.first,
      mode: TacticsMode.practice,
      queue: queue,
      queueIndex: 0,
    );
  }

  void _startPuzzle(
    Emitter<TacticsState> emit, {
    required TacticPuzzle puzzle,
    required TacticsMode mode,
    required List<TacticPuzzle> queue,
    required int queueIndex,
  }) {
    emit(state.copyWith(
      mode: mode,
      phase: TacticsPhase.solving,
      queue: queue,
      queueIndex: queueIndex,
      currentPuzzle: puzzle,
      fen: puzzle.fen,
      solutionIndex: 0,
      showSolution: false,
      sessionStart: DateTime.now(),
      message: puzzle.theme.isNotEmpty ? puzzle.theme : 'Find the best move',
      clearMessage: false,
    ));
  }

  Future<void> _onUserMoved(
    TacticsUserMoved event,
    Emitter<TacticsState> emit,
  ) async {
    final puzzle = state.currentPuzzle;
    if (puzzle == null || state.phase != TacticsPhase.solving) return;
    if (state.solutionIndex >= puzzle.solution.length) return;

    final expectedSan = puzzle.solution[state.solutionIndex];
    final game = chess.Chess.fromFEN(state.fen!);
    final moved = game.move({
      'from': event.from,
      'to': event.to,
      'promotion': event.promotion,
    });
    if (moved != true) return;

    final playedSan = game.san_moves().last ?? '';
    if (normalizeSan(playedSan) != normalizeSan(expectedSan)) {
      await _recordAttempt(puzzle, solved: false);
      emit(state.copyWith(
        phase: TacticsPhase.feedback,
        message: 'Incorrect — tap Show solution or Next',
        showSolution: false,
        stats: _repository.loadStats(),
      ));
      return;
    }

    var fen = game.fen;
    var nextIndex = state.solutionIndex + 1;

    // Auto-play one forced opponent reply when the solution continues.
    if (nextIndex < puzzle.solution.length) {
      final reply = applySan(fen, puzzle.solution[nextIndex]);
      if (reply == null) {
        emit(state.copyWith(message: 'Puzzle data error'));
        return;
      }
      fen = reply;
      nextIndex++;
    }

    if (nextIndex >= puzzle.solution.length) {
      await _recordAttempt(puzzle, solved: true);
      final stats = _repository.loadStats();
      if (state.mode == TacticsMode.daily) {
        final today = _repository.todayKey(DateTime.now());
        await _repository.saveStats(stats.copyWith(
          lastDailyPuzzleDate: today,
          lastDailyPuzzleId: puzzle.id,
        ));
      }
      emit(state.copyWith(
        fen: fen,
        solutionIndex: nextIndex,
        phase: TacticsPhase.feedback,
        message: 'Correct!',
        stats: _repository.loadStats(),
      ));
      return;
    }

    emit(state.copyWith(
      fen: fen,
      solutionIndex: nextIndex,
      message: 'Keep going…',
    ));
  }

  Future<void> _recordAttempt(TacticPuzzle puzzle, {required bool solved}) async {
    final stats = _repository.loadStats();
    final streak = solved ? stats.currentStreak + 1 : 0;
    final ratingDelta = solved ? 15 : -10;
    final newRating = (stats.localRating + ratingDelta).clamp(400, 2800);
    await _repository.saveStats(stats.copyWith(
      totalAttempts: stats.totalAttempts + 1,
      totalSolved: stats.totalSolved + (solved ? 1 : 0),
      currentStreak: streak,
      bestStreak: streak > stats.bestStreak ? streak : stats.bestStreak,
      localRating: newRating,
    ));
    final elapsed = state.sessionStart != null
        ? DateTime.now().difference(state.sessionStart!).inMilliseconds
        : 0;
    await _repository.recordAttempt(PuzzleAttempt(
      puzzleId: puzzle.id,
      solved: solved,
      attemptedAt: DateTime.now(),
      timeMs: elapsed,
    ));
  }

  void _onNextPuzzle(TacticsNextPuzzle event, Emitter<TacticsState> emit) {
    if (state.mode == TacticsMode.daily) {
      emit(state.copyWith(
        phase: TacticsPhase.idle,
        clearPuzzle: true,
        clearMessage: true,
        showSolution: false,
        stats: _repository.loadStats(),
      ));
      return;
    }

    final nextIndex = state.queueIndex + 1;
    if (nextIndex >= state.queue.length) {
      emit(state.copyWith(
        phase: TacticsPhase.queueComplete,
        clearPuzzle: true,
        message: 'Practice queue complete!',
        showSolution: false,
        stats: _repository.loadStats(),
      ));
      return;
    }

    _startPuzzle(
      emit,
      puzzle: state.queue[nextIndex],
      mode: state.mode,
      queue: state.queue,
      queueIndex: nextIndex,
    );
  }

  void _onShowSolution(TacticsShowSolution event, Emitter<TacticsState> emit) {
    emit(state.copyWith(
      showSolution: true,
      message: 'Solution: ${state.currentPuzzle?.solution.join(' ')}',
    ));
  }

  void _onSessionEnded(TacticsSessionEnded event, Emitter<TacticsState> emit) {
    emit(state.copyWith(
      phase: TacticsPhase.idle,
      clearPuzzle: true,
      clearMessage: true,
      showSolution: false,
      queue: const [],
      queueIndex: 0,
    ));
  }
}
