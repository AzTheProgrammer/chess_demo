import 'dart:convert';

import 'package:http/http.dart' as http;

class ChessComGameSummary {
  const ChessComGameSummary({
    required this.index,
    required this.white,
    required this.black,
    required this.result,
    required this.playedAt,
    required this.pgn,
  });

  final int index;
  final String white;
  final String black;
  final String result;
  final DateTime playedAt;
  final String pgn;
}

class ChessComClient {
  ChessComClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _userAgent = 'ExpansionLabChess/1.0 (contact: dev@expansionlab.local)';

  Future<List<ChessComGameSummary>> listGames({
    required String username,
    required int year,
    required int month,
  }) async {
    final user = username.trim().toLowerCase();
    final uri = Uri.parse(
      'https://api.chess.com/pub/player/$user/games/${year.toString().padLeft(4, '0')}/${month.toString().padLeft(2, '0')}',
    );
    final response = await _client.get(uri, headers: {'User-Agent': _userAgent});
    if (response.statusCode == 404) {
      throw ChessComImportException('No games found for $user in $year-$month');
    }
    if (response.statusCode != 200) {
      throw ChessComImportException('Chess.com returned ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final games = body['games'] as List<dynamic>? ?? [];
    if (games.isEmpty) {
      throw ChessComImportException('No games found for $user in $year-$month');
    }

    return [
      for (var i = 0; i < games.length; i++)
        _parseGame(games[i] as Map<String, dynamic>, i),
    ];
  }

  Future<String> fetchPgnByIndex({
    required String username,
    required int year,
    required int month,
    required int gameIndex,
  }) async {
    final games = await listGames(username: username, year: year, month: month);
    if (gameIndex < 0 || gameIndex >= games.length) {
      throw ChessComImportException('Game index out of range (0-${games.length - 1})');
    }
    return games[gameIndex].pgn;
  }

  ChessComGameSummary _parseGame(Map<String, dynamic> json, int index) {
    final pgn = json['pgn'] as String?;
    if (pgn == null || pgn.trim().isEmpty) {
      throw ChessComImportException('Chess.com game is missing PGN');
    }
    final white = (json['white'] as Map<String, dynamic>?)?['username'] as String? ?? '?';
    final black = (json['black'] as Map<String, dynamic>?)?['username'] as String? ?? '?';
    final result = json['result'] as String? ?? '*';
    final endTime = json['end_time'] as int?;
    final playedAt = endTime != null
        ? DateTime.fromMillisecondsSinceEpoch(endTime * 1000)
        : DateTime.now();
    return ChessComGameSummary(
      index: index,
      white: white,
      black: black,
      result: result,
      playedAt: playedAt,
      pgn: pgn.trim(),
    );
  }
}

class ChessComImportException implements Exception {
  ChessComImportException(this.message);

  final String message;

  @override
  String toString() => message;
}
