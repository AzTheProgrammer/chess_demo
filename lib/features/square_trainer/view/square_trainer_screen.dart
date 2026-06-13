import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/board_constants.dart';
import '../../../core/widgets/chess_board.dart';
import '../../../infrastructure/persistence/square_trainer_repository.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../cubit/square_trainer_cubit.dart';

class SquareTrainerScreen extends StatelessWidget {
  const SquareTrainerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SquareTrainerCubit(
        context.read<SquareTrainerRepository>(),
      ),
      child: const _SquareTrainerView(),
    );
  }
}

class _SquareTrainerView extends StatelessWidget {
  const _SquareTrainerView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Square Trainer')),
      body: BlocBuilder<SquareTrainerCubit, SquareTrainerState>(
        builder: (context, state) {
          final settings = context.watch<SettingsCubit>().state;
          final theme = boardThemeFor(settings.boardTheme.name);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ModePicker(state: state),
              const SizedBox(height: 12),
              _OrientationPicker(state: state),
              const SizedBox(height: 12),
              if (state.phase == TrainerPhase.idle ||
                  state.phase == TrainerPhase.ready)
                FilledButton(
                  onPressed: () =>
                      context.read<SquareTrainerCubit>().startSession(),
                  child: const Text('Start'),
                ),
              if (state.phase == TrainerPhase.active) ...[
                Text(
                  state.promptLabel ?? 'Get ready…',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                if (state.mode == TrainerMode.timedBlast)
                  Text(
                    'Time: ${state.secondsLeft}s · Score: ${state.timedScore}',
                    textAlign: TextAlign.center,
                  ),
                Text(
                  'Streak: ${state.streak}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ChessBoard(
                  fen: chess.Chess.DEFAULT_POSITION,
                  orientation: state.orientation,
                  moveEnabled: false,
                  showCoordinates: true,
                  lightColor: theme.lightSquare,
                  darkColor: theme.darkSquare,
                  highlightSquares: state.highlightSquare != null
                      ? {state.highlightSquare!}
                      : const {},
                  onMove: (_, __, {promotion}) {},
                  onSquareTap: state.mode == TrainerMode.nameSquare
                      ? null
                      : (square) => context
                          .read<SquareTrainerCubit>()
                          .onSquareTapped(square),
                ),
                if (state.mode == TrainerMode.nameSquare) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: state.choices
                        .map(
                          (c) => FilledButton.tonal(
                            onPressed: () => context
                                .read<SquareTrainerCubit>()
                                .onChoiceSelected(c),
                            child: Text(c),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
              if (state.feedback != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.feedback!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: state.feedback!.startsWith('Correct')
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                ),
              ],
              if (state.phase == TrainerPhase.finished)
                FilledButton(
                  onPressed: () =>
                      context.read<SquareTrainerCubit>().startSession(),
                  child: const Text('Play again'),
                ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stats', style: Theme.of(context).textTheme.titleMedium),
                      Text('Accuracy: ${state.stats.accuracy.toStringAsFixed(1)}%'),
                      Text('Best streak: ${state.stats.bestStreak}'),
                      Text('Best timed score: ${state.stats.bestTimedScore}'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModePicker extends StatelessWidget {
  const _ModePicker({required this.state});

  final SquareTrainerState state;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TrainerMode>(
      segments: const [
        ButtonSegment(value: TrainerMode.findSquare, label: Text('Find')),
        ButtonSegment(value: TrainerMode.nameSquare, label: Text('Name')),
        ButtonSegment(value: TrainerMode.timedBlast, label: Text('Timed')),
      ],
      selected: {state.mode},
      onSelectionChanged: (modes) {
        context.read<SquareTrainerCubit>().selectMode(modes.first);
      },
    );
  }
}

class _OrientationPicker extends StatelessWidget {
  const _OrientationPicker({required this.state});

  final SquareTrainerState state;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<BoardOrientation>(
      segments: const [
        ButtonSegment(
          value: BoardOrientation.white,
          label: Text('White bottom'),
        ),
        ButtonSegment(
          value: BoardOrientation.black,
          label: Text('Black bottom'),
        ),
      ],
      selected: {state.orientation},
      onSelectionChanged: (values) {
        context.read<SquareTrainerCubit>().setOrientation(values.first);
      },
    );
  }
}
