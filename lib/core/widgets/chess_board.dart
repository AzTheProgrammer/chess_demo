import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import '../constants/board_constants.dart';
import '../theme/design_tokens.dart';

typedef MoveCallback = void Function(String from, String to, {String? promotion});

/// Interactive 8×8 board backed by the chess rules package.
class ChessBoard extends StatefulWidget {
  const ChessBoard({
    super.key,
    required this.fen,
    required this.onMove,
    this.orientation = BoardOrientation.white,
    this.selectedSquare,
    this.highlightSquares = const {},
    this.checkSquares = const {},
    this.enabled = true,
    this.moveEnabled = true,
    this.showCoordinates = false,
    this.onSquareTap,
    this.lightColor,
    this.darkColor,
  });

  final String fen;
  final MoveCallback onMove;
  final BoardOrientation orientation;
  final String? selectedSquare;
  final Set<String> highlightSquares;
  final Set<String> checkSquares;
  final bool enabled;
  final bool moveEnabled;
  final bool showCoordinates;
  final void Function(String square)? onSquareTap;
  final Color? lightColor;
  final Color? darkColor;

  Color get resolvedLightColor =>
      lightColor ?? DesignTokens.boardClassic.lightSquare;

  Color get resolvedDarkColor =>
      darkColor ?? DesignTokens.boardClassic.darkSquare;

  @override
  State<ChessBoard> createState() => _ChessBoardState();
}

enum BoardOrientation { white, black }

class _ChessBoardState extends State<ChessBoard> {
  String? _selected;
  Set<String> _legalTargets = {};

  @override
  void didUpdateWidget(covariant ChessBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fen != widget.fen) {
      _selected = null;
      _legalTargets = {};
    }
  }

  chess.Chess get _game => chess.Chess.fromFEN(widget.fen);

  void _onSquareTap(int file, int rank) {
    if (!widget.enabled) return;
    final square = squareName(file, rank);
    widget.onSquareTap?.call(square);
    if (!widget.moveEnabled) return;

    final piece = _game.get(square);

    if (_selected != null && _legalTargets.contains(square)) {
      final promotion = _needsPromotion(_selected!, square) ? 'q' : null;
      widget.onMove(_selected!, square, promotion: promotion);
      setState(() {
        _selected = null;
        _legalTargets = {};
      });
      return;
    }

    if (piece == null || piece.color != _game.turn) {
      setState(() {
        _selected = null;
        _legalTargets = {};
      });
      return;
    }

    final targets = _legalTargetSquares(square);
    setState(() {
      _selected = square;
      _legalTargets = targets;
    });
  }

  bool _needsPromotion(String from, String to) {
    final piece = _game.get(from);
    if (piece?.type != chess.PieceType.PAWN) return false;
    final toRank = int.parse(to[1]);
    return toRank == 1 || toRank == 8;
  }

  Set<String> _legalTargetSquares(String from) {
    final moves = _game.moves({'square': from, 'verbose': true});
    return moves.map<String>((move) => move['to'] as String).toSet();
  }

  String _pieceKey(chess.Piece piece) {
    final color = piece.color == chess.Color.WHITE ? 'w' : 'b';
    return '$color${piece.type.name.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell = constraints.maxWidth / 8;
          return Stack(
            children: [
              for (var rank = 0; rank < 8; rank++)
                for (var file = 0; file < 8; file++)
                  _buildSquare(file, rank, cell),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSquare(int file, int rank, double size) {
    final displayFile =
        widget.orientation == BoardOrientation.white ? file : 7 - file;
    final displayRank =
        widget.orientation == BoardOrientation.white ? 7 - rank : rank;
    final square = squareName(file, rank);
    final isLight = (file + rank).isEven;
    final piece = _game.get(square);

    final isSelected =
        _selected == square || widget.selectedSquare == square;
    final isCheck = widget.checkSquares.contains(square);
    final isLastMove = widget.highlightSquares.contains(square);
    final isLegalTarget = _legalTargets.contains(square);
    final isCaptureTarget = isLegalTarget && piece != null;

    final baseColor =
        isLight ? widget.resolvedLightColor : widget.resolvedDarkColor;
    final overlays = <Color>[];
    if (isLastMove && !isSelected && !isCheck) {
      overlays.add(DesignTokens.lastMoveHighlight);
    }
    if (isCheck && !isSelected) {
      overlays.add(DesignTokens.checkHighlight);
    }
    if (isSelected) {
      overlays.add(DesignTokens.selectedSquare);
    }

    return Positioned(
      left: displayFile * size,
      top: displayRank * size,
      width: size,
      height: size,
      child: Semantics(
        label: squareSemanticsLabel(square, piece),
        button: widget.enabled,
        child: GestureDetector(
          onTap: () => _onSquareTap(file, rank),
          child: DecoratedBox(
            decoration: BoxDecoration(color: baseColor),
            child: Stack(
              children: [
                for (final overlay in overlays)
                  Positioned.fill(
                    child: ColoredBox(color: overlay),
                  ),
                if (isLegalTarget)
                  Center(
                    child: isCaptureTarget
                        ? Container(
                            width: size * 0.82,
                            height: size * 0.82,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: DesignTokens.legalTargetCapture,
                                width: size * 0.08,
                              ),
                            ),
                          )
                        : Container(
                            width: size * 0.28,
                            height: size * 0.28,
                            decoration: const BoxDecoration(
                              color: DesignTokens.legalTargetEmpty,
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                if (piece != null)
                  Center(
                    child: Text(
                      pieceSymbols[_pieceKey(piece)] ?? '?',
                      style: TextStyle(
                        fontSize: size * 0.62,
                        height: 1,
                        shadows: const [
                          Shadow(blurRadius: 2, color: Colors.black26),
                        ],
                      ),
                    ),
                  ),
                if (widget.showCoordinates) ...[
                  if (_showFileLabel(displayRank))
                    Positioned(
                      left: 2,
                      bottom: 2,
                      child: Text(
                        String.fromCharCode(97 + file),
                        style: DesignTokens.labelSmall.copyWith(
                          color: isLight
                              ? DesignTokens.coordinateDark
                              : DesignTokens.coordinateLight,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  if (_showRankLabel(displayFile))
                    Positioned(
                      left: 2,
                      top: 2,
                      child: Text(
                        '${rank + 1}',
                        style: DesignTokens.labelSmall.copyWith(
                          color: isLight
                              ? DesignTokens.coordinateDark
                              : DesignTokens.coordinateLight,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _showFileLabel(int displayRank) {
    return widget.orientation == BoardOrientation.white
        ? displayRank == 7
        : displayRank == 0;
  }

  bool _showRankLabel(int displayFile) {
    return widget.orientation == BoardOrientation.white
        ? displayFile == 0
        : displayFile == 7;
  }
}

/// Applies a move to a FEN string; returns updated FEN or null if illegal.
String? applyMove(String fen, String from, String to, {String? promotion}) {
  final game = chess.Chess.fromFEN(fen);
  final ok = game.move({'from': from, 'to': to, 'promotion': promotion});
  return ok ? game.fen : null;
}
