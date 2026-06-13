import 'package:chess_app/features/square_trainer/cubit/square_trainer_cubit.dart';
import 'package:chess_app/infrastructure/persistence/square_trainer_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SquareTrainerCubit', () {
    late SquareTrainerRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = SquareTrainerRepository(prefs);
    });

    test('correct find-square tap increments streak', () {
      final cubit = SquareTrainerCubit(repo);
      cubit.selectMode(TrainerMode.findSquare);
      cubit.startSession();
      final target = cubit.state.promptSquare!;
      cubit.onSquareTapped(target);
      expect(cubit.state.streak, 1);
      cubit.close();
    });

    test('wrong tap resets streak', () {
      final cubit = SquareTrainerCubit(repo);
      cubit.selectMode(TrainerMode.findSquare);
      cubit.startSession();
      final target = cubit.state.promptSquare!;
      final wrong = target == 'a1' ? 'h8' : 'a1';
      cubit.onSquareTapped(wrong);
      expect(cubit.state.streak, 0);
      cubit.close();
    });
  });
}
