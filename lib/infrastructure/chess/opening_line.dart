import 'package:equatable/equatable.dart';

enum OpeningSide { white, black }

class OpeningLine extends Equatable {
  const OpeningLine({
    required this.id,
    required this.eco,
    required this.name,
    required this.side,
    required this.moves,
    this.description = '',
  });

  final String id;
  final String eco;
  final String name;
  final OpeningSide side;
  final List<String> moves;
  final String description;

  bool get isUserWhite => side == OpeningSide.white;

  /// Indices in [moves] that the user must play.
  Iterable<int> get userMoveIndices sync* {
    for (var i = 0; i < moves.length; i++) {
      final userTurn = isUserWhite ? i.isEven : i.isOdd;
      if (userTurn) yield i;
    }
  }

  factory OpeningLine.fromJson(Map<String, dynamic> json) {
    final sideRaw = json['side'] as String? ?? 'white';
    return OpeningLine(
      id: json['id'] as String,
      eco: json['eco'] as String,
      name: json['name'] as String,
      side: sideRaw == 'black' ? OpeningSide.black : OpeningSide.white,
      moves: (json['moves'] as List<dynamic>).cast<String>(),
      description: json['description'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, eco, name, side, moves, description];
}
