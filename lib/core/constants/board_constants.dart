import 'package:chess/chess.dart' as chess;

import '../theme/design_tokens.dart';

const pieceSymbols = {
  'wK': '♔',
  'wQ': '♕',
  'wR': '♖',
  'wB': '♗',
  'wN': '♘',
  'wP': '♙',
  'bK': '♚',
  'bQ': '♛',
  'bR': '♜',
  'bB': '♝',
  'bN': '♞',
  'bP': '♟',
};

String squareName(int file, int rank) {
  return '${String.fromCharCode(97 + file)}${rank + 1}';
}

(int file, int rank) parseSquare(String square) {
  return (square.codeUnitAt(0) - 97, int.parse(square[1]) - 1);
}

BoardThemeTokens boardThemeFor(String themeName) {
  return DesignTokens.boardThemes.firstWhere(
    (theme) => theme.id == themeName,
    orElse: () => DesignTokens.boardClassic,
  );
}

({int light, int dark}) boardColorsFor(String themeName) {
  return boardThemeFor(themeName).argbValues;
}

/// Returns the king square for the side currently in check, if any.
String? kingInCheckSquare(String fen) {
  final game = chess.Chess.fromFEN(fen);
  if (!game.in_check) return null;

  for (var file = 0; file < 8; file++) {
    for (var rank = 0; rank < 8; rank++) {
      final square = squareName(file, rank);
      final piece = game.get(square);
      if (piece?.type == chess.PieceType.KING && piece?.color == game.turn) {
        return square;
      }
    }
  }
  return null;
}

String squareSemanticsLabel(String square, chess.Piece? piece) {
  if (piece == null) return '$square, empty';
  final color = piece.color == chess.Color.WHITE ? 'white' : 'black';
  final type = switch (piece.type) {
    chess.PieceType.PAWN => 'pawn',
    chess.PieceType.KNIGHT => 'knight',
    chess.PieceType.BISHOP => 'bishop',
    chess.PieceType.ROOK => 'rook',
    chess.PieceType.QUEEN => 'queen',
    chess.PieceType.KING => 'king',
    _ => 'piece',
  };
  return '$square, $color $type';
}
