import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/board_constants.dart';
import '../../../core/widgets/chess_board.dart';
import '../../../infrastructure/bot/bot_service.dart';
import '../../../infrastructure/persistence/game_repository.dart';
import '../bloc/play_bloc.dart';
import '../../settings/cubit/settings_cubit.dart';

class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlayBloc(
        bot: BotService(),
        games: context.read<GameRepository>(),
        difficulty: context.read<SettingsCubit>().state.difficulty,
      )..add(const PlayStarted()),
      child: const _PlayView(),
    );
  }
}

class _PlayView extends StatelessWidget {
  const _PlayView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Play vs Bot')),
      body: BlocBuilder<PlayBloc, PlayState>(
        builder: (context, state) {
          final settings = context.watch<SettingsCubit>().state;
          final theme = boardThemeFor(settings.boardTheme.name);
          final highlights = <String>{};
          if (state.lastMove != null) {
            highlights.add(state.lastMove!.from);
            highlights.add(state.lastMove!.to);
          }
          final checkSquare = kingInCheckSquare(state.fen);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChessBoard(
                  fen: state.fen,
                  enabled: state.boardEnabled,
                  highlightSquares: highlights,
                  checkSquares:
                      checkSquare != null ? {checkSquare} : const {},
                  showCoordinates: settings.showCoordinates,
                  lightColor: theme.lightSquare,
                  darkColor: theme.darkSquare,
                  onMove: (from, to, {promotion}) {
                    context.read<PlayBloc>().add(
                          PlayerMoved(from: from, to: to, promotion: promotion),
                        );
                  },
                ),
                const SizedBox(height: 12),
                if (state.message != null)
                  Text(
                    state.message!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                if (state.result != null)
                  Text(
                    'Result: ${state.result}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                const SizedBox(height: 8),
                if (state.status == PlayStatus.botThinking)
                  const Center(child: CircularProgressIndicator()),
                if (state.gameOver) ...[
                  FilledButton(
                    onPressed: () =>
                        context.read<PlayBloc>().add(const PlayReset()),
                    child: const Text('New game'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      final pgn = buildPgn(
                        moveSans: state.moveSans,
                        result: state.result ?? '*',
                      );
                      context.go('/analyze', extra: pgn);
                    },
                    child: const Text('Analyze game'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
