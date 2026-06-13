import 'package:chess/chess.dart' as chess;
import 'package:chess_app/infrastructure/chess/game_record.dart';
import 'package:chess_app/infrastructure/chess/pgn_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const samplePgn = '''
[Event "Test Game"]
[White "Alice"]
[Black "Bob"]
[Result "1-0"]

1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 1-0
''';

  group('PgnService', () {
    late PgnService service;

    setUp(() {
      service = PgnService();
    });

    test('parses headers, moves, and replay fens', () {
      final record = service.parse(samplePgn);

      expect(record.white, 'Alice');
      expect(record.black, 'Bob');
      expect(record.result, '1-0');
      expect(record.source, GameSource.paste);
      expect(record.moveSans, ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5', 'a6']);
      expect(record.fens.length, record.moveSans.length + 1);
      expect(record.fens.first, chess.Chess.DEFAULT_POSITION);
      expect(record.fens.last, isNot(record.fens.first));
    });

    test('fenAt returns clamped positions', () {
      final record = service.parse(samplePgn);
      expect(record.fenAt(-1), record.fens.first);
      expect(record.fenAt(999), record.fens.last);
    });

    test('lastMoveAt identifies from/to squares', () {
      final record = service.parse(samplePgn);
      final move = record.lastMoveAt(1);
      expect(move, isNotNull);
      expect(move!.from, 'e2');
      expect(move.to, 'e4');
    });

    test('throws on invalid pgn', () {
      expect(() => service.parse('not a pgn'), throwsA(isA<PgnParseException>()));
    });
  });
}
