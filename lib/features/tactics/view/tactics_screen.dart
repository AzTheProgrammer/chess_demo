import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/board_constants.dart';
import '../../../core/widgets/chess_board.dart';
import '../../../infrastructure/persistence/tactics_repository.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../bloc/tactics_bloc.dart';

class TacticsScreen extends StatelessWidget {
  const TacticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TacticsBloc(
        repository: context.read<TacticsRepository>(),
      )..add(const TacticsLoadRequested()),
      child: const _TacticsView(),
    );
  }
}

class _TacticsView extends StatelessWidget {
  const _TacticsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tactics Trainer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/train'),
        ),
      ),
      body: BlocBuilder<TacticsBloc, TacticsState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.phase == TacticsPhase.solving ||
              state.phase == TacticsPhase.feedback) {
            return _PuzzleView(state: state);
          }

          return _MenuView(state: state);
        },
      ),
    );
  }
}

class _MenuView extends StatelessWidget {
  const _MenuView({required this.state});

  final TacticsState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TacticsBloc>();
    final daily = state.dailyPuzzle;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your stats', style: Theme.of(context).textTheme.titleMedium),
                Text('Rating: ${state.stats.localRating}'),
                Text('Accuracy: ${state.stats.accuracy.toStringAsFixed(1)}%'),
                Text('Streak: ${state.stats.currentStreak} (best ${state.stats.bestStreak})'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (daily != null) ...[
          Text('Daily puzzle', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: Text(daily.theme.isNotEmpty ? daily.theme : 'Today\'s puzzle'),
              subtitle: Text('Rating ~${daily.rating}'),
              trailing: state.dailyCompleted
                  ? const Chip(label: Text('Done'))
                  : const Icon(Icons.play_arrow),
              enabled: !state.dailyCompleted,
              onTap: state.dailyCompleted
                  ? null
                  : () => bloc.add(const TacticsDailyStarted()),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text('Practice', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => bloc.add(const TacticsPracticeStarted()),
          icon: const Icon(Icons.queue_play_next),
          label: const Text('Start 10-puzzle queue'),
        ),
        if (state.phase == TacticsPhase.queueComplete) ...[
          const SizedBox(height: 16),
          Text(
            state.message ?? 'Queue complete!',
            style: const TextStyle(color: Colors.greenAccent),
          ),
        ],
      ],
    );
  }
}

class _PuzzleView extends StatelessWidget {
  const _PuzzleView({required this.state});

  final TacticsState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TacticsBloc>();
    final puzzle = state.currentPuzzle;
    final settings = context.watch<SettingsCubit>().state;
    final theme = boardThemeFor(settings.boardTheme.name);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (puzzle != null) ...[
          Text(
            puzzle.theme.isNotEmpty ? puzzle.theme : 'Tactics puzzle',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text('Rating ~${puzzle.rating} · Puzzle ${state.queueIndex + 1}/${state.queue.length}'),
        ],
        const SizedBox(height: 8),
        if (state.message != null)
          Text(state.message!, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        if (state.fen != null)
          ChessBoard(
            fen: state.fen!,
            showCoordinates: settings.showCoordinates,
            lightColor: theme.lightSquare,
            darkColor: theme.darkSquare,
            onMove: state.phase == TacticsPhase.solving
                ? (from, to, {promotion}) =>
                    bloc.add(TacticsUserMoved(from, to, promotion: promotion))
                : (_, __, {promotion}) {},
            enabled: state.phase == TacticsPhase.solving,
          ),
        const SizedBox(height: 12),
        if (state.showSolution && puzzle != null)
          Text(
            'Solution: ${puzzle.solution.join(' → ')}',
            style: const TextStyle(color: Colors.amberAccent),
          ),
        if (state.phase == TacticsPhase.feedback) ...[
          if (!state.showSolution)
            OutlinedButton(
              onPressed: () => bloc.add(const TacticsShowSolution()),
              child: const Text('Show solution'),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => bloc.add(const TacticsNextPuzzle()),
            child: Text(
              state.mode == TacticsMode.daily ? 'Done' : 'Next puzzle',
            ),
          ),
        ],
        if (state.phase == TacticsPhase.solving) ...[
          OutlinedButton(
            onPressed: () => bloc.add(const TacticsSessionEnded()),
            child: const Text('Exit'),
          ),
        ],
      ],
    );
  }
}
