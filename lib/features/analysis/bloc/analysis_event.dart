part of 'analysis_bloc.dart';

sealed class AnalysisEvent extends Equatable {
  const AnalysisEvent();

  @override
  List<Object?> get props => [];
}

final class AnalysisStarted extends AnalysisEvent {
  const AnalysisStarted();
}

final class AnalysisImportPasted extends AnalysisEvent {
  const AnalysisImportPasted(this.pgn);

  final String pgn;

  @override
  List<Object?> get props => [pgn];
}

final class AnalysisImportLocal extends AnalysisEvent {
  const AnalysisImportLocal(this.game);

  final SavedGame game;

  @override
  List<Object?> get props => [game];
}

final class AnalysisImportLichess extends AnalysisEvent {
  const AnalysisImportLichess(this.gameIdOrUrl);

  final String gameIdOrUrl;

  @override
  List<Object?> get props => [gameIdOrUrl];
}

final class AnalysisImportChessCom extends AnalysisEvent {
  const AnalysisImportChessCom({
    required this.username,
    required this.year,
    required this.month,
    this.gameIndex = 0,
  });

  final String username;
  final int year;
  final int month;
  final int gameIndex;

  @override
  List<Object?> get props => [username, year, month, gameIndex];
}

final class AnalysisGoToMove extends AnalysisEvent {
  const AnalysisGoToMove(this.halfMoveIndex);

  final int halfMoveIndex;

  @override
  List<Object?> get props => [halfMoveIndex];
}

final class AnalysisStepBack extends AnalysisEvent {
  const AnalysisStepBack();
}

final class AnalysisStepForward extends AnalysisEvent {
  const AnalysisStepForward();
}

final class AnalysisFlipBoard extends AnalysisEvent {
  const AnalysisFlipBoard();
}

final class AnalysisRequestEval extends AnalysisEvent {
  const AnalysisRequestEval();
}

final class AnalysisClear extends AnalysisEvent {
  const AnalysisClear();
}
