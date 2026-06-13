import 'package:chess/chess.dart' as chess;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../infrastructure/chess/opening_line.dart';
import '../../../infrastructure/chess/training_catalog.dart';
import '../../../infrastructure/persistence/openings_repository.dart';

part 'openings_event.dart';
part 'openings_state.dart';

class OpeningsBloc extends Bloc<OpeningsEvent, OpeningsState> {
  OpeningsBloc({required OpeningsRepository repository})
      : _repository = repository,
        super(const OpeningsState()) {
    on<OpeningsLoadRequested>(_onLoad);
    on<OpeningDrillStarted>(_onDrillStarted);
    on<OpeningUserMoved>(_onUserMoved);
    on<OpeningDrillExited>(_onDrillExited);
    on<OpeningHintRequested>(_onHintRequested);
  }

  final OpeningsRepository _repository;

  Future<void> _onLoad(
    OpeningsLoadRequested event,
    Emitter<OpeningsState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    final lines = await TrainingCatalog.loadOpenings();
    lines.sort(
      (a, b) => _repository.compareForReview(a.id, b.id),
    );
    emit(state.copyWith(
      loading: false,
      lines: lines,
      progress: _repository.loadAllProgress(),
    ));
  }

  void _onDrillStarted(OpeningDrillStarted event, Emitter<OpeningsState> emit) {
    final line = state.lines.firstWhere((l) => l.id == event.lineId);
    emit(state.copyWith(
      phase: OpeningsPhase.drilling,
      selectedLineId: line.id,
      fen: chess.Chess.DEFAULT_POSITION,
      moveIndex: 0,
      failuresOnMove: 0,
      clearHint: true,
      message: 'Play the line as ${line.side.name}',
    ));
    _autoPlayOpponent(emit);
  }

  void _onUserMoved(OpeningUserMoved event, Emitter<OpeningsState> emit) {
    final line = state.selectedLine;
    if (line == null || state.phase != OpeningsPhase.drilling) return;

    final expectedSan = line.moves[state.moveIndex];
    final game = chess.Chess.fromFEN(state.fen);
    final moved = game.move({
      'from': event.from,
      'to': event.to,
      'promotion': event.promotion,
    });
    if (moved != true) return;

    final playedSan = game.san_moves().last ?? '';
    if (normalizeSan(playedSan) != normalizeSan(expectedSan)) {
      game.undo();
      final failures = state.failuresOnMove + 1;
      emit(state.copyWith(
        failuresOnMove: failures,
        message: failures >= 2
            ? 'Hint available — tap Hint'
            : 'Not quite — expected $expectedSan',
        hintMove: failures >= 2 ? expectedSan : state.hintMove,
      ));
      return;
    }

    final nextIndex = state.moveIndex + 1;
    emit(state.copyWith(
      fen: game.fen,
      moveIndex: nextIndex,
      failuresOnMove: 0,
      clearHint: true,
      message: nextIndex >= line.moves.length ? 'Line complete!' : 'Correct!',
    ));

    if (nextIndex >= line.moves.length) {
      _completeDrill(line, emit, success: true);
      return;
    }
    _autoPlayOpponent(emit);
  }

  void _onDrillExited(OpeningDrillExited event, Emitter<OpeningsState> emit) {
    emit(state.copyWith(
      phase: OpeningsPhase.browsing,
      clearSelectedLine: true,
      clearHint: true,
      clearMessage: true,
      moveIndex: 0,
      failuresOnMove: 0,
      fen: chess.Chess.DEFAULT_POSITION,
    ));
  }

  void _onHintRequested(
    OpeningHintRequested event,
    Emitter<OpeningsState> emit,
  ) {
    final line = state.selectedLine;
    if (line == null || state.moveIndex >= line.moves.length) return;
    emit(state.copyWith(
      hintMove: line.moves[state.moveIndex],
      message: 'Hint: play ${line.moves[state.moveIndex]}',
    ));
  }

  void _autoPlayOpponent(Emitter<OpeningsState> emit) {
    final line = state.selectedLine;
    if (line == null) return;

    var fen = state.fen;
    var index = state.moveIndex;

    while (index < line.moves.length) {
      final userTurn = line.isUserWhite ? index.isEven : index.isOdd;
      if (userTurn) break;

      final next = applySan(fen, line.moves[index]);
      if (next == null) {
        emit(state.copyWith(message: 'Line data error at move ${index + 1}'));
        return;
      }
      fen = next;
      index++;
    }

    emit(state.copyWith(
      fen: fen,
      moveIndex: index,
      message: index >= line.moves.length
          ? 'Line complete!'
          : 'Your move: ${line.moves[index]}',
    ));

    if (index >= line.moves.length) {
      _completeDrill(line, emit, success: true);
    }
  }

  Future<void> _completeDrill(
    OpeningLine line,
    Emitter<OpeningsState> emit, {
    required bool success,
  }) async {
    final prev = _repository.progressFor(line.id);
    final newMastery = success
        ? (prev.masteryScore + 20).clamp(0, 100)
        : (prev.masteryScore - 5).clamp(0, 100);
    final updated = prev.copyWith(
      masteryScore: newMastery,
      lastPracticed: DateTime.now(),
      successfulDrills: prev.successfulDrills + (success ? 1 : 0),
      totalDrills: prev.totalDrills + 1,
    );
    await _repository.saveProgress(line.id, updated);
    final progress = Map<String, OpeningProgress>.from(state.progress)
      ..[line.id] = updated;
    emit(state.copyWith(
      phase: OpeningsPhase.completed,
      progress: progress,
      message: success
          ? 'Line mastered! Mastery: $newMastery%'
          : 'Drill ended. Mastery: $newMastery%',
    ));
  }
}
