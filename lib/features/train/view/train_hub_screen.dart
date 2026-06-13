import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/action_card.dart';

class TrainHubScreen extends StatelessWidget {
  const TrainHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Train')),
      body: ListView(
        padding: DesignTokens.screenPadding,
        children: [
          Text(
            'Sharpen your skills',
            style: DesignTokens.headlineMedium,
          ),
          const SizedBox(height: DesignTokens.space2),
          const Text(
            'Drill openings, solve tactics, or learn board coordinates.',
            style: DesignTokens.bodyMedium,
          ),
          const SizedBox(height: DesignTokens.space5),
          ActionCard(
            title: 'Openings Trainer',
            subtitle: 'ECO lines with drill mode & spaced repetition',
            icon: Icons.menu_book_outlined,
            onTap: () => context.go('/train/openings'),
          ),
          const SizedBox(height: DesignTokens.cardGap),
          ActionCard(
            title: 'Tactics Trainer',
            subtitle: 'Daily puzzle & 10-puzzle practice queue',
            icon: Icons.extension_outlined,
            onTap: () => context.go('/train/tactics'),
          ),
          const SizedBox(height: DesignTokens.cardGap),
          ActionCard(
            title: 'Square Trainer',
            subtitle: 'Find, name, and timed coordinate drills',
            icon: Icons.grid_on,
            onTap: () => context.go('/train/squares'),
          ),
        ],
      ),
    );
  }
}
