import '../chess/game_record.dart';
import '../chess/pgn_service.dart';
import '../persistence/game_repository.dart';
import '../remote/chesscom_client.dart';
import '../remote/lichess_client.dart';

class GameImportService {
  GameImportService({
    PgnService? pgn,
    LichessClient? lichess,
    ChessComClient? chessCom,
  })  : _pgn = pgn ?? PgnService(),
        _lichess = lichess ?? LichessClient(),
        _chessCom = chessCom ?? ChessComClient();

  final PgnService _pgn;
  final LichessClient _lichess;
  final ChessComClient _chessCom;

  GameRecord importPgn(String rawPgn, {GameSource source = GameSource.paste}) {
    return _pgn.parse(rawPgn, source: source);
  }

  GameRecord importSavedGame(SavedGame saved) {
    return _pgn.parse(saved.pgn, source: GameSource.local);
  }

  Future<GameRecord> importLichess(String gameIdOrUrl) async {
    final pgn = await _lichess.fetchPgn(gameIdOrUrl);
    return _pgn.parse(pgn, source: GameSource.lichess);
  }

  Future<GameRecord> importChessCom({
    required String username,
    required int year,
    required int month,
    int gameIndex = 0,
  }) async {
    final pgn = await _chessCom.fetchPgnByIndex(
      username: username,
      year: year,
      month: month,
      gameIndex: gameIndex,
    );
    return _pgn.parse(pgn, source: GameSource.chesscom);
  }

  Future<List<ChessComGameSummary>> listChessComGames({
    required String username,
    required int year,
    required int month,
  }) {
    return _chessCom.listGames(username: username, year: year, month: month);
  }
}
