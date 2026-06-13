import 'dart:async';
import 'dart:io' show Platform;

import 'package:chess/chess.dart' as chess;
import 'package:stockfish/stockfish.dart';

/// Thin UCI wrapper around the [stockfish] FFI plugin (Android/iOS only).
class StockfishService {
  StockfishService({Stockfish? engine}) : _engine = engine;

  Stockfish? _engine;
  StreamSubscription<String>? _stdoutSub;
  _WaitRequest? _activeWait;

  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  bool get isReady => _engine?.state.value == StockfishState.ready;

  Future<void> start() async {
    if (!isSupported) {
      throw UnsupportedError(
        'Stockfish FFI is only available on Android and iOS.',
      );
    }
    dispose();
    _engine = Stockfish();
    await _waitForEngineReady();
    _stdoutSub = _engine!.stdout.listen(_onLine);
    await _sendAndWait('uci', (line) => line == 'uciok');
    await _sendAndWait('isready', (line) => line == 'readyok');
  }

  Future<String> bestMove({
    required String fen,
    int movetimeMs = 2500,
    int? depth,
  }) async {
    _ensureReady();
    _engine!.stdin = 'position fen $fen';
    final goCommand = depth != null
        ? 'go depth $depth'
        : 'go movetime $movetimeMs';
    final timeout = depth != null
        ? const Duration(seconds: 30)
        : Duration(milliseconds: movetimeMs + 3000);
    final moveLine = await _sendAndWait(
      goCommand,
      (line) => line.startsWith('bestmove '),
      timeout: timeout,
    );
    final uci = moveLine.split(' ')[1];
    if (!_isLegalMove(fen, uci)) {
      throw StateError('Engine returned illegal move: $uci for fen: $fen');
    }
    return uci;
  }

  /// Returns centipawns (white POV) or mate distance from Stockfish analysis.
  Future<EngineEvaluation?> evaluate({
    required String fen,
    int depth = 12,
  }) async {
    _ensureReady();
    _engine!.stdin = 'position fen $fen';
    EngineEvaluation? latest;
    await _sendAndWait(
      'go depth $depth',
      (line) {
        if (line.startsWith('info ')) {
          final parsed = parseEngineInfo(line);
          if (parsed != null) latest = parsed;
          return false;
        }
        return line.startsWith('bestmove ');
      },
      timeout: const Duration(seconds: 30),
    );
    return latest;
  }

  void dispose() {
    _stdoutSub?.cancel();
    _stdoutSub = null;
    _activeWait?.completer.completeError(StateError('Stockfish disposed'));
    _activeWait = null;
    _engine?.dispose();
    _engine = null;
  }

  void _ensureReady() {
    if (_engine == null || !isReady) {
      throw StateError('Stockfish is not ready');
    }
  }

  Future<void> _waitForEngineReady({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final engine = _engine!;
    if (engine.state.value == StockfishState.ready) return;
    final completer = Completer<void>();
    void listener() {
      if (engine.state.value == StockfishState.ready &&
          !completer.isCompleted) {
        engine.state.removeListener(listener);
        completer.complete();
      }
    }

    engine.state.addListener(listener);
    try {
      await completer.future.timeout(timeout);
    } finally {
      engine.state.removeListener(listener);
    }
  }

  Future<String> _sendAndWait(
    String command,
    bool Function(String line) predicate, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_activeWait != null) {
      throw StateError('Concurrent UCI wait not supported');
    }
    final completer = Completer<String>();
    _activeWait = _WaitRequest(completer: completer, predicate: predicate);
    _engine!.stdin = command;
    try {
      return await completer.future.timeout(timeout);
    } finally {
      _activeWait = null;
    }
  }

  void _onLine(String line) {
    final wait = _activeWait;
    if (wait == null) return;
    if (wait.predicate(line)) {
      _activeWait = null;
      wait.completer.complete(line);
    }
  }

  bool _isLegalMove(String fen, String uci) {
    return parseBestMove('bestmove $uci', fen) != null;
  }
}

class _WaitRequest {
  _WaitRequest({required this.completer, required this.predicate});

  final Completer<String> completer;
  final bool Function(String line) predicate;
}

/// Parses UCI bestmove output and validates legality against a FEN position.
String? parseBestMove(String line, String fen) {
  if (!line.startsWith('bestmove ')) return null;
  final uci = line.split(' ')[1];
  if (uci == '(none)') return null;
  final game = chess.Chess.fromFEN(fen);
  final from = uci.substring(0, 2);
  final to = uci.substring(2, 4);
  final promotion = uci.length > 4 ? uci[4] : null;
  final moved = game.move({'from': from, 'to': to, 'promotion': promotion});
  return moved ? uci : null;
}

class EngineEvaluation {
  const EngineEvaluation({this.centipawns, this.mateIn});

  final int? centipawns;
  final int? mateIn;

  String get label {
    if (mateIn != null) {
      return mateIn! > 0 ? 'M$mateIn' : 'M${mateIn!.abs()} (Black)';
    }
    if (centipawns == null) return '—';
    final pawns = centipawns! / 100;
    final sign = pawns > 0 ? '+' : '';
    return '$sign${pawns.toStringAsFixed(1)}';
  }

  double get barValue {
    if (mateIn != null) {
      return mateIn! > 0 ? 1.0 : 0.0;
    }
    final cp = (centipawns ?? 0).clamp(-800, 800);
    return 0.5 + cp / 1600;
  }
}

EngineEvaluation? parseEngineInfo(String line) {
  if (!line.startsWith('info ')) return null;
  final scoreIndex = line.indexOf(' score ');
  if (scoreIndex == -1) return null;
  final tail = line.substring(scoreIndex + 7);
  final parts = tail.split(' ');
  if (parts.length < 2) return null;
  if (parts[0] == 'cp') {
    final cp = int.tryParse(parts[1]);
    if (cp == null) return null;
    return EngineEvaluation(centipawns: cp);
  }
  if (parts[0] == 'mate') {
    final mate = int.tryParse(parts[1]);
    if (mate == null) return null;
    return EngineEvaluation(mateIn: mate);
  }
  return null;
}
