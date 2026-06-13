part of 'play_bloc.dart';

enum PlayStatus { idle, loading, playing, botThinking }

typedef MovePair = ({String from, String to});

class PlayState extends Equatable {
  const PlayState({
    required this.fen,
    required this.difficulty,
    required this.status,
    required this.moveSans,
    this.lastMove,
    this.gameOver = false,
    this.result,
    this.message,
  });

  factory PlayState.initial({required BotDifficulty difficulty}) {
    return PlayState(
      fen: chess.Chess.DEFAULT_POSITION,
      difficulty: difficulty,
      status: PlayStatus.idle,
      moveSans: const [],
    );
  }

  final String fen;
  final BotDifficulty difficulty;
  final PlayStatus status;
  final List<String> moveSans;
  final MovePair? lastMove;
  final bool gameOver;
  final String? result;
  final String? message;

  bool get boardEnabled =>
      status == PlayStatus.playing && !gameOver;

  PlayState copyWith({
    String? fen,
    BotDifficulty? difficulty,
    PlayStatus? status,
    List<String>? moveSans,
    MovePair? lastMove,
    bool? gameOver,
    String? result,
    String? message,
  }) {
    return PlayState(
      fen: fen ?? this.fen,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      moveSans: moveSans ?? this.moveSans,
      lastMove: lastMove ?? this.lastMove,
      gameOver: gameOver ?? this.gameOver,
      result: result ?? this.result,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        fen,
        difficulty,
        status,
        moveSans,
        lastMove,
        gameOver,
        result,
        message,
      ];
}
