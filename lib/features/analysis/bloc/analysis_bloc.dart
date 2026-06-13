import 'package:chess/chess.dart' as chess;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/chess_board.dart';
import '../../../infrastructure/chess/game_record.dart';
import '../../../infrastructure/import/game_import_service.dart';
import '../../../infrastructure/persistence/game_repository.dart';
import '../../../infrastructure/stockfish/stockfish_service.dart';

part 'analysis_event.dart';
part 'analysis_state.dart';

class AnalysisBloc extends Bloc<AnalysisEvent, AnalysisState> {
  AnalysisBloc({required GameImportService imports})
      : _imports = imports,
        super(const AnalysisState()) {
    on<AnalysisStarted>(_onStarted);
    on<AnalysisImportPasted>(_onImportPasted);
    on<AnalysisImportLocal>(_onImportLocal);
    on<AnalysisImportLichess>(_onImportLichess);
    on<AnalysisImportChessCom>(_onImportChessCom);
    on<AnalysisGoToMove>(_onGoToMove);
    on<AnalysisStepBack>(_onStepBack);
    on<AnalysisStepForward>(_onStepForward);
    on<AnalysisFlipBoard>(_onFlipBoard);
    on<AnalysisRequestEval>(_onRequestEval);
    on<AnalysisClear>(_onClear);
  }

  final GameImportService _imports;
  StockfishService? _engine;

  Future<void> _onStarted(
    AnalysisStarted event,
    Emitter<AnalysisState> emit,
  ) async {
    if (!StockfishService.isSupported) {
      emit(state.copyWith(
        engineAvailable: false,
        message: 'Engine eval unavailable on this platform',
      ));
      return;
    }
    try {
      _engine?.dispose();
      _engine = StockfishService();
      await _engine!.start();
      emit(state.copyWith(engineAvailable: true, clearMessage: true));
    } catch (error) {
      emit(state.copyWith(
        engineAvailable: false,
        message: 'Engine unavailable: $error',
      ));
    }
  }

  Future<void> _onImportPasted(
    AnalysisImportPasted event,
    Emitter<AnalysisState> emit,
  ) async {
    await _loadGame(emit, () async => _imports.importPgn(event.pgn));
  }

  Future<void> _onImportLocal(
    AnalysisImportLocal event,
    Emitter<AnalysisState> emit,
  ) async {
    await _loadGame(emit, () async => _imports.importSavedGame(event.game));
  }

  Future<void> _onImportLichess(
    AnalysisImportLichess event,
    Emitter<AnalysisState> emit,
  ) async {
    await _loadGame(
      emit,
      () => _imports.importLichess(event.gameIdOrUrl),
    );
  }

  Future<void> _onImportChessCom(
    AnalysisImportChessCom event,
    Emitter<AnalysisState> emit,
  ) async {
    await _loadGame(
      emit,
      () => _imports.importChessCom(
        username: event.username,
        year: event.year,
        month: event.month,
        gameIndex: event.gameIndex,
      ),
    );
  }

  Future<void> _loadGame(
    Emitter<AnalysisState> emit,
    Future<GameRecord> Function() load,
  ) async {
    emit(state.copyWith(
      status: AnalysisStatus.loading,
      clearMessage: true,
      clearEvaluation: true,
    ));
    try {
      final game = await load();
      emit(state.copyWith(
        status: AnalysisStatus.ready,
        game: game,
        halfMoveIndex: 0,
        clearEvaluation: true,
      ));
      add(const AnalysisRequestEval());
    } catch (error) {
      emit(state.copyWith(
        status: AnalysisStatus.error,
        message: '$error',
      ));
    }
  }

  void _onGoToMove(AnalysisGoToMove event, Emitter<AnalysisState> emit) {
    final game = state.game;
    if (game == null) return;
    final index = event.halfMoveIndex.clamp(0, game.moveCount);
    emit(state.copyWith(halfMoveIndex: index, clearEvaluation: true));
    add(const AnalysisRequestEval());
  }

  void _onStepBack(AnalysisStepBack event, Emitter<AnalysisState> emit) {
    if (!state.canStepBack) return;
    final index = state.halfMoveIndex - 1;
    emit(state.copyWith(halfMoveIndex: index, clearEvaluation: true));
    add(const AnalysisRequestEval());
  }

  void _onStepForward(AnalysisStepForward event, Emitter<AnalysisState> emit) {
    if (!state.canStepForward) return;
    final index = state.halfMoveIndex + 1;
    emit(state.copyWith(halfMoveIndex: index, clearEvaluation: true));
    add(const AnalysisRequestEval());
  }

  void _onFlipBoard(AnalysisFlipBoard event, Emitter<AnalysisState> emit) {
    emit(state.copyWith(
      orientation: state.orientation == BoardOrientation.white
          ? BoardOrientation.black
          : BoardOrientation.white,
    ));
  }

  Future<void> _onRequestEval(
    AnalysisRequestEval event,
    Emitter<AnalysisState> emit,
  ) async {
    final engine = _engine;
    if (state.game == null || engine == null || !engine.isReady) return;

    emit(state.copyWith(evalLoading: true, clearEvaluation: true));
    try {
      final evaluation = await engine.evaluate(fen: state.currentFen);
      emit(state.copyWith(
        evaluation: evaluation,
        evalLoading: false,
      ));
    } catch (error) {
      emit(state.copyWith(
        evalLoading: false,
        message: 'Eval failed: $error',
      ));
    }
  }

  void _onClear(AnalysisClear event, Emitter<AnalysisState> emit) {
    emit(const AnalysisState());
    add(const AnalysisStarted());
  }

  @override
  Future<void> close() {
    _engine?.dispose();
    return super.close();
  }
}
