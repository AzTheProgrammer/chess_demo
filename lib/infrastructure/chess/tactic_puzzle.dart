import 'package:equatable/equatable.dart';

class TacticPuzzle extends Equatable {
  const TacticPuzzle({
    required this.id,
    required this.fen,
    required this.solution,
    required this.rating,
    this.theme = '',
  });

  final String id;
  final String fen;
  final List<String> solution;
  final int rating;
  final String theme;

  factory TacticPuzzle.fromJson(Map<String, dynamic> json) {
    return TacticPuzzle(
      id: json['id'] as String,
      fen: json['fen'] as String,
      solution: (json['solution'] as List<dynamic>).cast<String>(),
      rating: json['rating'] as int? ?? 800,
      theme: json['theme'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, fen, solution, rating, theme];
}
