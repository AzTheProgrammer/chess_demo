import 'dart:math';

import 'package:chess/chess.dart' as chess;

import '../persistence/settings_repository.dart';
import '../stockfish/stockfish_service.dart';
import '../../core/widgets/chess_board.dart';

/// Picks bot moves via Stockfish when available, else random legal moves.
class BotService {
  BotService({StockfishService? engine}) : _engine = engine;

  StockfishService? _engine;
  final _random = Random();

  Future<void> start() async {
    if (!StockfishService.isSupported) return;
    _engine?.dispose();
    _engine = StockfishService();
    await _engine!.start();
  }

  void dispose() {
    _engine?.dispose();
    _engine = null;
  }

  bool get isEngineReady => _engine?.isReady ?? false;

  Future<String?> pickMove({
    required String fen,
    required BotDifficulty difficulty,
  }) async {
    final engine = _engine;
    if (engine != null && engine.isReady) {
      final depth = depthForDifficulty(difficulty);
      final uci = await engine.bestMove(fen: fen, depth: depth);
      return uci;
    }
    return _randomLegalMove(fen);
  }

  String? _randomLegalMove(String fen) {
    final game = chess.Chess.fromFEN(fen);
    final moves = game.moves({'verbose': true});
    if (moves.isEmpty) return null;
    final move = moves[_random.nextInt(moves.length)] as Map<String, dynamic>;
    final from = move['from'] as String;
    final to = move['to'] as String;
    final promotion = move['promotion'] as String?;
    return '$from$to${promotion ?? ''}';
  }
}

/// Applies a UCI move string to a FEN and returns the new FEN.
String? applyUciMove(String fen, String uci) {
  if (uci.length < 4) return null;
  final from = uci.substring(0, 2);
  final to = uci.substring(2, 4);
  final promotion = uci.length > 4 ? uci[4] : null;
  return applyMove(fen, from, to, promotion: promotion);
}

String gameResultLabel(chess.Chess game) {
  if (game.in_checkmate) {
    return game.turn == chess.Color.WHITE ? '0-1' : '1-0';
  }
  if (game.in_stalemate || game.in_draw) return '1/2-1/2';
  return '*';
}

String buildPgn({
  required List<String> moveSans,
  required String result,
  String event = 'Bot Game',
}) {
  final buffer = StringBuffer()
    ..writeln('[Event "$event"]')
    ..writeln('[Result "$result"]')
    ..writeln();
  for (var i = 0; i < moveSans.length; i++) {
    if (i % 2 == 0) buffer.write('${i ~/ 2 + 1}. ');
    buffer.write('${moveSans[i]} ');
  }
  buffer.write(result);
  return buffer.toString().trim();
}
