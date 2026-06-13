part of 'analysis_bloc.dart';

enum AnalysisStatus { idle, loading, ready, error }

class AnalysisState extends Equatable {
  const AnalysisState({
    this.status = AnalysisStatus.idle,
    this.game,
    this.halfMoveIndex = 0,
    this.orientation = BoardOrientation.white,
    this.evaluation,
    this.evalLoading = false,
    this.engineAvailable = false,
    this.message,
  });

  final AnalysisStatus status;
  final GameRecord? game;
  final int halfMoveIndex;
  final BoardOrientation orientation;
  final EngineEvaluation? evaluation;
  final bool evalLoading;
  final bool engineAvailable;
  final String? message;

  String get currentFen =>
      game?.fenAt(halfMoveIndex) ?? chess.Chess.DEFAULT_POSITION;

  ({String from, String to})? get lastMove => game?.lastMoveAt(halfMoveIndex);

  bool get canStepBack => halfMoveIndex > 0;
  bool get canStepForward =>
      game != null && halfMoveIndex < game!.moveCount;

  AnalysisState copyWith({
    AnalysisStatus? status,
    GameRecord? game,
    int? halfMoveIndex,
    BoardOrientation? orientation,
    EngineEvaluation? evaluation,
    bool clearEvaluation = false,
    bool? evalLoading,
    bool? engineAvailable,
    String? message,
    bool clearMessage = false,
  }) {
    return AnalysisState(
      status: status ?? this.status,
      game: game ?? this.game,
      halfMoveIndex: halfMoveIndex ?? this.halfMoveIndex,
      orientation: orientation ?? this.orientation,
      evaluation: clearEvaluation ? null : (evaluation ?? this.evaluation),
      evalLoading: evalLoading ?? this.evalLoading,
      engineAvailable: engineAvailable ?? this.engineAvailable,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
        status,
        game,
        halfMoveIndex,
        orientation,
        evaluation,
        evalLoading,
        engineAvailable,
        message,
      ];
}
