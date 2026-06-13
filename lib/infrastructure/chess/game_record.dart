import 'package:chess/chess.dart' as chess;

enum GameSource { local, paste, lichess, chesscom }

class GameRecord {
  const GameRecord({
    required this.pgn,
    required this.moveSans,
    required this.fens,
    required this.source,
    this.white,
    this.black,
    this.result = '*',
    this.title,
  });

  final String pgn;
  final List<String> moveSans;
  final List<String> fens;
  final GameSource source;
  final String? white;
  final String? black;
  final String result;
  final String? title;

  int get moveCount => moveSans.length;

  String fenAt(int halfMoveIndex) {
    final index = halfMoveIndex.clamp(0, fens.length - 1);
    return fens[index];
  }

  ({String from, String to})? lastMoveAt(int halfMoveIndex) {
    if (halfMoveIndex <= 0 || halfMoveIndex > moveSans.length) return null;
    final before = chess.Chess.fromFEN(fens[halfMoveIndex - 1]);
    final after = chess.Chess.fromFEN(fens[halfMoveIndex]);
    return _diffMove(before, after);
  }
}

({String from, String to})? _diffMove(chess.Chess before, chess.Chess after) {
  for (final move in before.moves({'verbose': true})) {
    final from = move['from'] as String;
    final to = move['to'] as String;
    final promotion = move['promotion'] as String?;
    final trial = chess.Chess.fromFEN(before.fen);
    trial.move({'from': from, 'to': to, 'promotion': promotion});
    if (trial.fen == after.fen) {
      return (from: from, to: to);
    }
  }
  return null;
}
