import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/board_constants.dart';
import '../../../core/widgets/chess_board.dart';
import '../../../infrastructure/persistence/openings_repository.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../bloc/openings_bloc.dart';

class OpeningsScreen extends StatelessWidget {
  const OpeningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OpeningsBloc(
        repository: context.read<OpeningsRepository>(),
      )..add(const OpeningsLoadRequested()),
      child: const _OpeningsView(),
    );
  }
}

class _OpeningsView extends StatelessWidget {
  const _OpeningsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Openings Trainer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/train'),
        ),
      ),
      body: BlocBuilder<OpeningsBloc, OpeningsState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.phase == OpeningsPhase.drilling ||
              state.phase == OpeningsPhase.completed) {
            return _DrillView(state: state);
          }

          return _LineList(state: state);
        },
      ),
    );
  }
}

class _LineList extends StatelessWidget {
  const _LineList({required this.state});

  final OpeningsState state;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<dynamic>>{};
    for (final line in state.lines) {
      grouped.putIfAbsent(line.eco, () => []).add(line);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Repertoire lines',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Sorted by review priority — lower mastery first.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white60,
              ),
        ),
        const SizedBox(height: 16),
        ...grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ECO ${entry.key}', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              ...entry.value.map((line) {
                final mastery = state.masteryFor(line.id);
                return Card(
                  child: ListTile(
                    title: Text(line.name),
                    subtitle: Text(
                      '${line.side.name} · ${line.moves.length} moves · $mastery% mastery',
                    ),
                    trailing: const Icon(Icons.play_arrow),
                    onTap: () => context
                        .read<OpeningsBloc>()
                        .add(OpeningDrillStarted(line.id)),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
          );
        }),
      ],
    );
  }
}

class _DrillView extends StatelessWidget {
  const _DrillView({required this.state});

  final OpeningsState state;

  @override
  Widget build(BuildContext context) {
    final line = state.selectedLine;
    final bloc = context.read<OpeningsBloc>();
    final settings = context.watch<SettingsCubit>().state;
    final theme = boardThemeFor(settings.boardTheme.name);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (line != null) ...[
          Text(line.name, style: Theme.of(context).textTheme.titleLarge),
          Text('${line.eco} · Play as ${line.side.name}'),
          if (line.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(line.description, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
        const SizedBox(height: 12),
        if (state.message != null)
          Text(
            state.message!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        const SizedBox(height: 8),
        ChessBoard(
          fen: state.fen,
          orientation: (line?.isUserWhite ?? true)
              ? BoardOrientation.white
              : BoardOrientation.black,
          showCoordinates: settings.showCoordinates,
          lightColor: theme.lightSquare,
          darkColor: theme.darkSquare,
          onMove: (from, to, {promotion}) =>
              bloc.add(OpeningUserMoved(from, to, promotion: promotion)),
        ),
        const SizedBox(height: 12),
        if (state.phase == OpeningsPhase.drilling) ...[
          if (state.hintMove != null)
            Text(
              'Hint: ${state.hintMove}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.amberAccent),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => bloc.add(const OpeningHintRequested()),
                  child: const Text('Hint'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => bloc.add(const OpeningDrillExited()),
                  child: const Text('Exit'),
                ),
              ),
            ],
          ),
        ],
        if (state.phase == OpeningsPhase.completed) ...[
          FilledButton(
            onPressed: () {
              bloc.add(const OpeningDrillExited());
              if (line != null) {
                bloc.add(OpeningDrillStarted(line.id));
              }
            },
            child: const Text('Drill again'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => bloc.add(const OpeningDrillExited()),
            child: const Text('Back to lines'),
          ),
        ],
      ],
    );
  }
}
