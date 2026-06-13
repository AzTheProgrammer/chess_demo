import 'package:chess/chess.dart' as chess;
import 'package:chess_app/core/constants/board_constants.dart';
import 'package:chess_app/core/theme/design_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('boardColorsFor', () {
    test('returns classic theme from DesignTokens by default', () {
      final colors = boardColorsFor('classic');
      expect(colors.light, DesignTokens.boardClassic.lightSquare.toARGB32());
      expect(colors.dark, DesignTokens.boardClassic.darkSquare.toARGB32());
    });

    test('returns midnight theme colors', () {
      final colors = boardColorsFor('midnight');
      expect(colors.light, DesignTokens.boardMidnight.lightSquare.toARGB32());
      expect(colors.dark, DesignTokens.boardMidnight.darkSquare.toARGB32());
    });

    test('falls back to classic for unknown theme', () {
      final colors = boardColorsFor('unknown');
      expect(colors.light, DesignTokens.boardClassic.lightSquare.toARGB32());
    });
  });

  group('kingInCheckSquare', () {
    test('returns null when not in check', () {
      expect(kingInCheckSquare(chess.Chess.DEFAULT_POSITION), isNull);
    });

    test('returns king square when in check', () {
      // Scholar's mate position — black king on e8 in check from queen on f7
      const fen = 'r1bqkb1r/pppp1Qpp/2n2n2/4p3/2B1P3/8/PPPP1PPP/RNB1KBNR b KQkq - 0 4';
      expect(kingInCheckSquare(fen), 'e8');
    });
  });

  group('squareSemanticsLabel', () {
    test('describes empty square', () {
      expect(squareSemanticsLabel('e4', null), 'e4, empty');
    });

    test('describes occupied square', () {
      final game = chess.Chess.fromFEN(chess.Chess.DEFAULT_POSITION);
      final piece = game.get('e2');
      expect(squareSemanticsLabel('e2', piece), 'e2, white pawn');
    });
  });
}
