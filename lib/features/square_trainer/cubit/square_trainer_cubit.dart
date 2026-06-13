import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/board_constants.dart';
import '../../../core/widgets/chess_board.dart';
import '../../../infrastructure/persistence/square_trainer_repository.dart';

part 'square_trainer_state.dart';

enum TrainerMode { findSquare, nameSquare, timedBlast }

class SquareTrainerCubit extends Cubit<SquareTrainerState> {
  SquareTrainerCubit(this._repository)
      : super(const SquareTrainerState());

  final SquareTrainerRepository _repository;
  final _random = Random();
  Timer? _timer;

  void selectMode(TrainerMode mode) {
    _timer?.cancel();
    emit(state.copyWith(
      mode: mode,
      phase: TrainerPhase.ready,
      streak: 0,
      timedScore: 0,
      feedback: null,
      clearPrompt: true,
      clearChoices: true,
    ));
  }

  void setOrientation(BoardOrientation orientation) {
    emit(state.copyWith(orientation: orientation));
  }

  void startSession() {
    _timer?.cancel();
    final stats = _repository.load();
    emit(state.copyWith(
      phase: TrainerPhase.active,
      streak: 0,
      timedScore: 0,
      stats: stats,
      feedback: null,
    ));
    if (state.mode == TrainerMode.timedBlast) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (state.secondsLeft <= 1) {
          _endTimedSession();
        } else {
          emit(state.copyWith(secondsLeft: state.secondsLeft - 1));
        }
      });
      emit(state.copyWith(secondsLeft: 30));
    }
    _nextPrompt();
  }

  void onSquareTapped(String square) {
    if (state.phase != TrainerPhase.active) return;
    if (state.mode == TrainerMode.nameSquare) return;

    final correct = square == state.promptSquare;
    _recordAttempt(correct);
    if (correct) {
      final streak = state.streak + 1;
      final timedScore =
          state.mode == TrainerMode.timedBlast ? state.timedScore + 1 : 0;
      emit(state.copyWith(
        streak: streak,
        timedScore: timedScore,
        feedback: 'Correct!',
      ));
      _nextPrompt();
    } else {
      emit(state.copyWith(streak: 0, feedback: 'Wrong — it was ${state.promptSquare}'));
      if (state.mode != TrainerMode.timedBlast) {
        Future.delayed(const Duration(milliseconds: 800), _nextPrompt);
      } else {
        _nextPrompt();
      }
    }
  }

  void onChoiceSelected(String choice) {
    if (state.phase != TrainerPhase.active || state.mode != TrainerMode.nameSquare) {
      return;
    }
    final correct = choice == state.promptSquare;
    _recordAttempt(correct);
    if (correct) {
      emit(state.copyWith(
        streak: state.streak + 1,
        feedback: 'Correct!',
      ));
      _nextPrompt();
    } else {
      emit(state.copyWith(streak: 0, feedback: 'Wrong — it was ${state.promptSquare}'));
      Future.delayed(const Duration(milliseconds: 800), _nextPrompt);
    }
  }

  void _nextPrompt() {
    if (state.phase != TrainerPhase.active) return;
    final square = _randomSquare();
    if (state.mode == TrainerMode.findSquare ||
        state.mode == TrainerMode.timedBlast) {
      emit(state.copyWith(
        promptSquare: square,
        promptLabel: 'Tap $square',
        clearHighlight: true,
        feedback: null,
      ));
    } else {
      final choices = _choicesFor(square);
      emit(state.copyWith(
        promptSquare: square,
        promptLabel: 'What square is highlighted?',
        highlightSquare: square,
        choices: choices,
        feedback: null,
      ));
    }
  }

  void _recordAttempt(bool correct) {
    final stats = state.stats.copyWith(
      totalAttempts: state.stats.totalAttempts + 1,
      totalCorrect: state.stats.totalCorrect + (correct ? 1 : 0),
      bestStreak: correct
          ? max(state.stats.bestStreak, state.streak + 1)
          : state.stats.bestStreak,
    );
    emit(state.copyWith(stats: stats));
    _repository.save(stats);
  }

  void _endTimedSession() {
    _timer?.cancel();
    final stats = state.stats.copyWith(
      bestTimedScore: max(state.stats.bestTimedScore, state.timedScore),
    );
    _repository.save(stats);
    emit(state.copyWith(
      phase: TrainerPhase.finished,
      stats: stats,
      feedback: 'Time! Score: ${state.timedScore}',
    ));
  }

  String _randomSquare() {
    final file = _random.nextInt(8);
    final rank = _random.nextInt(8);
    return squareName(file, rank);
  }

  List<String> _choicesFor(String correct) {
    final choices = <String>{correct};
    while (choices.length < 4) {
      choices.add(_randomSquare());
    }
    final list = choices.toList()..shuffle(_random);
    return list;
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
