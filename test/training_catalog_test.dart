import 'package:chess_app/infrastructure/chess/training_catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TrainingCatalog.resetCache();
  });

  group('TrainingCatalog assets', () {
    test('opening lines replay without illegal moves', () async {
      final lines = await TrainingCatalog.loadOpenings();
      expect(lines, isNotEmpty);
      for (final line in lines) {
        final fen = fenAfterMoves(line.moves);
        expect(fen, isNotNull, reason: '${line.id} has illegal move sequence');
      }
    });

    test('puzzle solutions replay from bundled FEN', () async {
      final puzzles = await TrainingCatalog.loadPuzzles();
      expect(puzzles.length, greaterThanOrEqualTo(10));
      for (final puzzle in puzzles) {
        var fen = puzzle.fen;
        for (final san in puzzle.solution) {
          final next = applySan(fen, san);
          expect(next, isNotNull, reason: '${puzzle.id}: illegal $san at $fen');
          fen = next!;
        }
      }
    });
  });

  group('dailyPuzzleIndex', () {
    test('is deterministic for a given date', () {
      final date = DateTime(2026, 6, 13);
      expect(dailyPuzzleIndex(12, date), dailyPuzzleIndex(12, date));
      expect(dailyPuzzleIndex(12, date), lessThan(12));
    });
  });
}
