part of 'tactics_bloc.dart';

enum TacticsMode { daily, practice }

enum TacticsPhase { idle, solving, feedback, queueComplete }

class TacticsState extends Equatable {
  const TacticsState({
    this.mode = TacticsMode.practice,
    this.phase = TacticsPhase.idle,
    this.puzzles = const [],
    this.queue = const [],
    this.queueIndex = 0,
    this.currentPuzzle,
    this.fen,
    this.solutionIndex = 0,
    this.stats = const TacticsStats(),
    this.message,
    this.showSolution = false,
    this.sessionStart,
    this.loading = true,
    this.todayKey = '',
  });

  final TacticsMode mode;
  final TacticsPhase phase;
  final List<TacticPuzzle> puzzles;
  final List<TacticPuzzle> queue;
  final int queueIndex;
  final TacticPuzzle? currentPuzzle;
  final String? fen;
  final int solutionIndex;
  final TacticsStats stats;
  final String? message;
  final bool showSolution;
  final DateTime? sessionStart;
  final bool loading;
  final String todayKey;

  TacticPuzzle? get dailyPuzzle {
    if (puzzles.isEmpty) return null;
    final idx = dailyPuzzleIndex(puzzles.length, DateTime.now());
    return puzzles[idx];
  }

  bool get dailyCompleted =>
      todayKey.isNotEmpty && stats.lastDailyPuzzleDate == todayKey;

  TacticsState copyWith({
    TacticsMode? mode,
    TacticsPhase? phase,
    List<TacticPuzzle>? puzzles,
    List<TacticPuzzle>? queue,
    int? queueIndex,
    TacticPuzzle? currentPuzzle,
    String? fen,
    int? solutionIndex,
    TacticsStats? stats,
    String? message,
    bool? showSolution,
    DateTime? sessionStart,
    bool? loading,
    String? todayKey,
    bool clearPuzzle = false,
    bool clearMessage = false,
  }) {
    return TacticsState(
      mode: mode ?? this.mode,
      phase: phase ?? this.phase,
      puzzles: puzzles ?? this.puzzles,
      queue: queue ?? this.queue,
      queueIndex: queueIndex ?? this.queueIndex,
      currentPuzzle: clearPuzzle ? null : (currentPuzzle ?? this.currentPuzzle),
      fen: clearPuzzle ? null : (fen ?? this.fen),
      solutionIndex: solutionIndex ?? this.solutionIndex,
      stats: stats ?? this.stats,
      message: clearMessage ? null : (message ?? this.message),
      showSolution: showSolution ?? this.showSolution,
      sessionStart: sessionStart ?? this.sessionStart,
      loading: loading ?? this.loading,
      todayKey: todayKey ?? this.todayKey,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        phase,
        puzzles,
        queue,
        queueIndex,
        currentPuzzle,
        fen,
        solutionIndex,
        stats,
        message,
        showSolution,
        sessionStart,
        loading,
        todayKey,
      ];
}
