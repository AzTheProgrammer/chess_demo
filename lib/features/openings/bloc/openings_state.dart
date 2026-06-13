part of 'openings_bloc.dart';

enum OpeningsPhase { browsing, drilling, completed }

class OpeningsState extends Equatable {
  const OpeningsState({
    this.phase = OpeningsPhase.browsing,
    this.lines = const [],
    this.progress = const {},
    this.selectedLineId,
    this.fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    this.moveIndex = 0,
    this.failuresOnMove = 0,
    this.message,
    this.hintMove,
    this.loading = true,
  });

  final OpeningsPhase phase;
  final List<OpeningLine> lines;
  final Map<String, OpeningProgress> progress;
  final String? selectedLineId;
  final String fen;
  final int moveIndex;
  final int failuresOnMove;
  final String? message;
  final String? hintMove;
  final bool loading;

  OpeningLine? get selectedLine {
    if (selectedLineId == null) return null;
    for (final line in lines) {
      if (line.id == selectedLineId) return line;
    }
    return null;
  }

  int masteryFor(String lineId) => progress[lineId]?.masteryScore ?? 0;

  OpeningsState copyWith({
    OpeningsPhase? phase,
    List<OpeningLine>? lines,
    Map<String, OpeningProgress>? progress,
    String? selectedLineId,
    String? fen,
    int? moveIndex,
    int? failuresOnMove,
    String? message,
    String? hintMove,
    bool? loading,
    bool clearSelectedLine = false,
    bool clearHint = false,
    bool clearMessage = false,
  }) {
    return OpeningsState(
      phase: phase ?? this.phase,
      lines: lines ?? this.lines,
      progress: progress ?? this.progress,
      selectedLineId:
          clearSelectedLine ? null : (selectedLineId ?? this.selectedLineId),
      fen: fen ?? this.fen,
      moveIndex: moveIndex ?? this.moveIndex,
      failuresOnMove: failuresOnMove ?? this.failuresOnMove,
      message: clearMessage ? null : (message ?? this.message),
      hintMove: clearHint ? null : (hintMove ?? this.hintMove),
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        lines,
        progress,
        selectedLineId,
        fen,
        moveIndex,
        failuresOnMove,
        message,
        hintMove,
        loading,
      ];
}
