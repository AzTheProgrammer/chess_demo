import 'package:chess/chess.dart' as chess;
import 'package:chess_app/core/widgets/chess_board.dart';
import 'package:chess_app/infrastructure/stockfish/stockfish_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('applyMove', () {
    test('accepts legal opening move e2-e4', () {
      final next = applyMove(chess.Chess.DEFAULT_POSITION, 'e2', 'e4');
      expect(next, isNotNull);
      expect(next, contains('4P3'));
    });

    test('rejects illegal move', () {
      expect(applyMove(chess.Chess.DEFAULT_POSITION, 'e2', 'e5'), isNull);
    });

    test('rejects moving opponent piece', () {
      expect(applyMove(chess.Chess.DEFAULT_POSITION, 'e7', 'e5'), isNull);
    });
  });

  group('parseBestMove', () {
    test('extracts legal UCI move from engine output', () {
      const fen = chess.Chess.DEFAULT_POSITION;
      final move = parseBestMove('bestmove e2e4 ponder e7e5', fen);
      expect(move, 'e2e4');
    });

    test('returns null for illegal engine output', () {
      const fen = chess.Chess.DEFAULT_POSITION;
      expect(parseBestMove('bestmove e2e5', fen), isNull);
    });
  });

  group('ChessBoard widget', () {
    testWidgets('renders 64 tappable squares', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChessBoard(
              fen: chess.Chess.DEFAULT_POSITION,
              onMove: (_, __, {promotion}) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GestureDetector), findsNWidgets(64));
    });

    testWidgets('renders coordinate labels when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChessBoard(
              fen: chess.Chess.DEFAULT_POSITION,
              showCoordinates: true,
              onMove: (_, __, {promotion}) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('a'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });
}
