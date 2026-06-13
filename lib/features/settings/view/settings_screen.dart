import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../infrastructure/persistence/settings_repository.dart';
import '../cubit/settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Bot difficulty'),
            subtitle: Text('Engine search depth per tier'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<BotDifficulty>(
              segments: const [
                ButtonSegment(
                  value: BotDifficulty.beginner,
                  label: Text('Beginner'),
                ),
                ButtonSegment(
                  value: BotDifficulty.intermediate,
                  label: Text('Mid'),
                ),
                ButtonSegment(
                  value: BotDifficulty.advanced,
                  label: Text('Advanced'),
                ),
              ],
              selected: {settings.difficulty},
              onSelectionChanged: (values) {
                context.read<SettingsCubit>().setDifficulty(values.first);
              },
            ),
          ),
          const Divider(),
          const ListTile(title: Text('Board theme')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<BoardTheme>(
              segments: const [
                ButtonSegment(value: BoardTheme.classic, label: Text('Classic')),
                ButtonSegment(value: BoardTheme.midnight, label: Text('Midnight')),
                ButtonSegment(
                  value: BoardTheme.tournament,
                  label: Text('Tournament'),
                ),
              ],
              selected: {settings.boardTheme},
              onSelectionChanged: (values) {
                context.read<SettingsCubit>().setBoardTheme(values.first);
              },
            ),
          ),
          SwitchListTile(
            title: const Text('Show coordinates'),
            value: settings.showCoordinates,
            onChanged: (v) =>
                context.read<SettingsCubit>().setShowCoordinates(v),
          ),
        ],
      ),
    );
  }
}
