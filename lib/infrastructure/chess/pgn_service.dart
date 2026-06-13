import 'package:chess/chess.dart' as chess;

import 'game_record.dart';

class PgnParseException implements Exception {
  PgnParseException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PgnService {
  GameRecord parse(String rawPgn, {GameSource source = GameSource.paste}) {
    final pgn = rawPgn.trim();
    if (pgn.isEmpty) {
      throw PgnParseException('PGN is empty');
    }

    final game = chess.Chess();
    if (!game.load_pgn(pgn)) {
      throw PgnParseException('Could not parse PGN');
    }

    final replay = _buildReplay(pgn);
    final white = game.header['White'];
    final black = game.header['Black'];
    final result = game.header['Result'] ?? '*';
    final event = game.header['Event'];

    return GameRecord(
      pgn: pgn,
      moveSans: replay.moveSans,
      fens: replay.fens,
      source: source,
      white: white,
      black: black,
      result: result,
      title: event,
    );
  }

  _ReplayData _buildReplay(String pgn) {
    final replay = chess.Chess();
    if (!replay.load_pgn(pgn)) {
      throw PgnParseException('Could not replay PGN');
    }

    final fens = <String>[];
    final moveSans = <String>[];

    while (true) {
      fens.insert(0, replay.fen);
      if (replay.history.isEmpty) break;
      final move = replay.undo_move();
      if (move == null) break;
      moveSans.insert(0, replay.move_to_san(move));
    }

    if (moveSans.isEmpty) {
      throw PgnParseException('PGN contains no moves');
    }

    return _ReplayData(fens: fens, moveSans: moveSans);
  }
}

class _ReplayData {
  const _ReplayData({required this.fens, required this.moveSans});

  final List<String> fens;
  final List<String> moveSans;
}
