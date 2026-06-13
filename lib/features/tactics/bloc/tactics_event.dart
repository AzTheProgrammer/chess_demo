part of 'tactics_bloc.dart';

sealed class TacticsEvent extends Equatable {
  const TacticsEvent();

  @override
  List<Object?> get props => [];
}

final class TacticsLoadRequested extends TacticsEvent {
  const TacticsLoadRequested();
}

final class TacticsDailyStarted extends TacticsEvent {
  const TacticsDailyStarted();
}

final class TacticsPracticeStarted extends TacticsEvent {
  const TacticsPracticeStarted();
}

final class TacticsUserMoved extends TacticsEvent {
  const TacticsUserMoved(this.from, this.to, {this.promotion});

  final String from;
  final String to;
  final String? promotion;

  @override
  List<Object?> get props => [from, to, promotion];
}

final class TacticsNextPuzzle extends TacticsEvent {
  const TacticsNextPuzzle();
}

final class TacticsShowSolution extends TacticsEvent {
  const TacticsShowSolution();
}

final class TacticsSessionEnded extends TacticsEvent {
  const TacticsSessionEnded();
}
