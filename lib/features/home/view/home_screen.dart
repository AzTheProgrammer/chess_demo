import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/action_card.dart';
import '../../../infrastructure/persistence/game_repository.dart';
import '../../settings/cubit/settings_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final games = context.read<GameRepository>().loadAll();
    final settings = context.watch<SettingsCubit>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('Chess')),
      body: ListView(
        padding: DesignTokens.screenPadding,
        children: [
          Text(
            'Welcome back',
            style: DesignTokens.headlineMedium,
          ),
          const SizedBox(height: DesignTokens.space2),
          const Text(
            'Play, analyze, drill openings, and solve tactics.',
            style: DesignTokens.bodyMedium,
          ),
          const SizedBox(height: DesignTokens.space5),
          ActionCard(
            title: 'Train',
            subtitle: 'Openings, tactics & square drills',
            icon: Icons.school_outlined,
            onTap: () => context.go('/train'),
          ),
          const SizedBox(height: DesignTokens.cardGap),
          ActionCard(
            title: 'Play vs Bot',
            subtitle: 'Difficulty: ${settings.difficulty.name}',
            icon: Icons.sports_esports,
            onTap: () => context.go('/play'),
          ),
          const SizedBox(height: DesignTokens.cardGap),
          ActionCard(
            title: 'Square Trainer',
            subtitle: 'Learn file & rank names',
            icon: Icons.grid_on,
            onTap: () => context.go('/train/squares'),
          ),
          const SizedBox(height: DesignTokens.cardGap),
          ActionCard(
            title: 'Analyze Game',
            subtitle: 'Import PGN, Lichess, or Chess.com',
            icon: Icons.analytics_outlined,
            onTap: () => context.go('/analyze'),
          ),
          const SizedBox(height: DesignTokens.space6),
          Text(
            'Recent games',
            style: DesignTokens.titleMedium,
          ),
          const SizedBox(height: DesignTokens.space2),
          if (games.isEmpty)
            const Card(
              child: Padding(
                padding: DesignTokens.cardPadding,
                child: Text('No saved games yet. Start a bot game!'),
              ),
            )
          else
            ...games.take(5).map(
                  (g) => Card(
                    child: ListTile(
                      title: Text('${g.result} vs bot'),
                      subtitle: Text(
                        '${g.difficulty} · ${_formatDate(g.playedAt)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/analyze', extra: g),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
