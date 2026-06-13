part of 'square_trainer_cubit.dart';

enum TrainerPhase { idle, ready, active, finished }

class SquareTrainerState extends Equatable {
  const SquareTrainerState({
    this.mode = TrainerMode.findSquare,
    this.phase = TrainerPhase.idle,
    this.orientation = BoardOrientation.white,
    this.promptSquare,
    this.promptLabel,
    this.highlightSquare,
    this.choices = const [],
    this.streak = 0,
    this.timedScore = 0,
    this.secondsLeft = 30,
    this.feedback,
    this.stats = const SquareTrainerStats(),
  });

  final TrainerMode mode;
  final TrainerPhase phase;
  final BoardOrientation orientation;
  final String? promptSquare;
  final String? promptLabel;
  final String? highlightSquare;
  final List<String> choices;
  final int streak;
  final int timedScore;
  final int secondsLeft;
  final String? feedback;
  final SquareTrainerStats stats;

  SquareTrainerState copyWith({
    TrainerMode? mode,
    TrainerPhase? phase,
    BoardOrientation? orientation,
    String? promptSquare,
    String? promptLabel,
    String? highlightSquare,
    List<String>? choices,
    int? streak,
    int? timedScore,
    int? secondsLeft,
    String? feedback,
    SquareTrainerStats? stats,
    bool clearPrompt = false,
    bool clearHighlight = false,
    bool clearChoices = false,
  }) {
    return SquareTrainerState(
      mode: mode ?? this.mode,
      phase: phase ?? this.phase,
      orientation: orientation ?? this.orientation,
      promptSquare: clearPrompt ? null : (promptSquare ?? this.promptSquare),
      promptLabel: clearPrompt ? null : (promptLabel ?? this.promptLabel),
      highlightSquare:
          clearHighlight ? null : (highlightSquare ?? this.highlightSquare),
      choices: clearChoices ? const [] : (choices ?? this.choices),
      streak: streak ?? this.streak,
      timedScore: timedScore ?? this.timedScore,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      feedback: feedback,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        phase,
        orientation,
        promptSquare,
        promptLabel,
        highlightSquare,
        choices,
        streak,
        timedScore,
        secondsLeft,
        feedback,
        stats,
      ];
}
