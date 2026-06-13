import 'package:http/http.dart' as http;

class LichessClient {
  LichessClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _userAgent = 'ExpansionLabChess/1.0 (contact: dev@expansionlab.local)';

  Future<String> fetchPgn(String gameIdOrUrl) async {
    final gameId = _extractGameId(gameIdOrUrl);
    final uri = Uri.parse('https://lichess.org/game/export/$gameId');
    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/x-chess-pgn', 'User-Agent': _userAgent},
    );
    if (response.statusCode != 200) {
      throw LichessImportException(
        'Lichess returned ${response.statusCode} for game $gameId',
      );
    }
    final pgn = response.body.trim();
    if (pgn.isEmpty) {
      throw LichessImportException('Lichess returned an empty PGN');
    }
    return pgn;
  }

  String _extractGameId(String input) {
    final trimmed = input.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.host.contains('lichess.org')) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isEmpty) {
        throw LichessImportException('Invalid Lichess URL');
      }
      return segments.first;
    }
    if (!RegExp(r'^[a-zA-Z0-9]{8,12}$').hasMatch(trimmed)) {
      throw LichessImportException('Invalid Lichess game id');
    }
    return trimmed;
  }
}

class LichessImportException implements Exception {
  LichessImportException(this.message);

  final String message;

  @override
  String toString() => message;
}
