part of 'play_bloc.dart';

sealed class PlayEvent extends Equatable {
  const PlayEvent();

  @override
  List<Object?> get props => [];
}

final class PlayStarted extends PlayEvent {
  const PlayStarted();
}

final class PlayerMoved extends PlayEvent {
  const PlayerMoved({
    required this.from,
    required this.to,
    this.promotion,
  });

  final String from;
  final String to;
  final String? promotion;

  @override
  List<Object?> get props => [from, to, promotion];
}

final class PlayReset extends PlayEvent {
  const PlayReset();
}
