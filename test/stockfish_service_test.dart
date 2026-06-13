import 'dart:io';

import 'package:chess/chess.dart' as chess;
import 'package:chess_app/infrastructure/stockfish/stockfish_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StockfishService integration', () {
    test(
      'returns legal move in under 3 seconds',
      () async {
        final engine = StockfishService();
        await engine.start();
        addTearDown(engine.dispose);

        final sw = Stopwatch()..start();
        final move = await engine.bestMove(
          fen: chess.Chess.DEFAULT_POSITION,
          movetimeMs: 2000,
        );
        sw.stop();

        expect(move, isNotEmpty);
        expect(sw.elapsedMilliseconds, lessThan(3000));
        expect(
          parseBestMove('bestmove $move', chess.Chess.DEFAULT_POSITION),
          move,
        );
      },
      skip: !(Platform.isAndroid || Platform.isIOS)
          ? 'Stockfish FFI requires Android or iOS device/emulator'
          : false,
    );
  });
}
