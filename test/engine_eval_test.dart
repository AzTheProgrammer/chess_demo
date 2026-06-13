import 'package:chess_app/infrastructure/stockfish/stockfish_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseEngineInfo', () {
    test('parses centipawn score', () {
      final eval = parseEngineInfo('info depth 12 score cp 35 nodes 123 nps 456');
      expect(eval?.centipawns, 35);
      expect(eval?.mateIn, isNull);
      expect(eval?.label, '+0.3');
    });

    test('parses mate score', () {
      final eval = parseEngineInfo('info depth 18 score mate 3 nodes 999');
      expect(eval?.mateIn, 3);
      expect(eval?.label, 'M3');
    });

    test('returns null for non-info lines', () {
      expect(parseEngineInfo('bestmove e2e4'), isNull);
    });
  });

  group('EngineEvaluation barValue', () {
    test('maps cp to bar fraction', () {
      expect(const EngineEvaluation(centipawns: 0).barValue, 0.5);
      expect(const EngineEvaluation(centipawns: 400).barValue, greaterThan(0.5));
      expect(const EngineEvaluation(centipawns: -400).barValue, lessThan(0.5));
    });
  });
}
