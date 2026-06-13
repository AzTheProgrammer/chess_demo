part of 'openings_bloc.dart';

sealed class OpeningsEvent extends Equatable {
  const OpeningsEvent();

  @override
  List<Object?> get props => [];
}

final class OpeningsLoadRequested extends OpeningsEvent {
  const OpeningsLoadRequested();
}

final class OpeningDrillStarted extends OpeningsEvent {
  const OpeningDrillStarted(this.lineId);

  final String lineId;

  @override
  List<Object?> get props => [lineId];
}

final class OpeningUserMoved extends OpeningsEvent {
  const OpeningUserMoved(this.from, this.to, {this.promotion});

  final String from;
  final String to;
  final String? promotion;

  @override
  List<Object?> get props => [from, to, promotion];
}

final class OpeningDrillExited extends OpeningsEvent {
  const OpeningDrillExited();
}

final class OpeningHintRequested extends OpeningsEvent {
  const OpeningHintRequested();
}
