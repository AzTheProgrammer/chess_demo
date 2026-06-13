import 'dart:convert';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/services.dart';

import 'opening_line.dart';
import 'tactic_puzzle.dart';

/// Loads bundled opening and puzzle datasets from assets.
class TrainingCatalog {
  TrainingCatalog._();

  static List<OpeningLine>? _openings;
  static List<TacticPuzzle>? _puzzles;

  static Future<List<OpeningLine>> loadOpenings() async {
    if (_openings != null) return _openings!;
    final raw = await rootBundle.loadString('assets/openings/openings.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _openings = (json['lines'] as List<dynamic>)
        .map((e) => OpeningLine.fromJson(e as Map<String, dynamic>))
        .toList();
    return _openings!;
  }

  static Future<List<TacticPuzzle>> loadPuzzles() async {
    if (_puzzles != null) return _puzzles!;
    final raw = await rootBundle.loadString('assets/puzzles/puzzles.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _puzzles = (json['puzzles'] as List<dynamic>)
        .map((e) => TacticPuzzle.fromJson(e as Map<String, dynamic>))
        .toList();
    return _puzzles!;
  }

  /// Clears cached data (for tests).
  static void resetCache() {
    _openings = null;
    _puzzles = null;
  }
}

/// Replays [moves] from the starting position; returns final FEN or null if illegal.
String? fenAfterMoves(List<String> moves, {int count = -1}) {
  final game = chess.Chess();
  final limit = count < 0 ? moves.length : count;
  for (var i = 0; i < limit && i < moves.length; i++) {
    if (game.move(moves[i]) != true) return null;
  }
  return game.fen;
}

/// Returns true when [san] is a legal move matching one of the legal SAN options.
bool isSanMoveLegal(String fen, String san) {
  final game = chess.Chess.fromFEN(fen);
  final legal = game.moves({'verbose': true}) as List<dynamic>;
  for (final move in legal) {
    final from = move['from'] as String;
    final to = move['to'] as String;
    final promotion = move['promotion'] as String?;
    final moved = game.move({'from': from, 'to': to, 'promotion': promotion});
    if (moved == true) {
      final played = game.san_moves().last;
      game.undo();
      if (played == san) return true;
    }
  }
  return false;
}

/// Applies SAN [san] to position [fen]; returns new FEN or null.
String? applySan(String fen, String san) {
  final game = chess.Chess.fromFEN(fen);
  if (game.move(san) == true) return game.fen;
  if (game.move(normalizeSan(san)) == true) return game.fen;
  return null;
}

/// Normalizes SAN for comparison (strip check/mate markers).
String normalizeSan(String san) => san.replaceAll(RegExp(r'[+#]$'), '');

/// Picks daily puzzle index from catalog using date seed.
int dailyPuzzleIndex(int catalogSize, DateTime date) {
  if (catalogSize <= 0) return 0;
  final seed = date.year * 10000 + date.month * 100 + date.day;
  return seed % catalogSize;
}
