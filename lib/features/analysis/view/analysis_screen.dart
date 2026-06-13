import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/board_constants.dart';
import '../../../core/widgets/chess_board.dart';
import '../../../infrastructure/chess/game_record.dart';
import '../../../infrastructure/import/game_import_service.dart';
import '../../../infrastructure/persistence/game_repository.dart';
import '../../../infrastructure/stockfish/stockfish_service.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../bloc/analysis_bloc.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key, this.initialPgn, this.initialSavedGame});

  final String? initialPgn;
  final SavedGame? initialSavedGame;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = AnalysisBloc(
          imports: context.read<GameImportService>(),
        )..add(const AnalysisStarted());
        if (initialSavedGame != null) {
          bloc.add(AnalysisImportLocal(initialSavedGame!));
        } else if (initialPgn != null && initialPgn!.trim().isNotEmpty) {
          bloc.add(AnalysisImportPasted(initialPgn!));
        }
        return bloc;
      },
      child: const _AnalysisView(),
    );
  }
}

class _AnalysisView extends StatelessWidget {
  const _AnalysisView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyze'),
        actions: [
          IconButton(
            tooltip: 'Import game',
            onPressed: () => _showImportSheet(context),
            icon: const Icon(Icons.file_upload_outlined),
          ),
        ],
      ),
      body: BlocBuilder<AnalysisBloc, AnalysisState>(
        builder: (context, state) {
          if (state.status == AnalysisStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.game == null) {
            return _EmptyAnalysis(onImport: () => _showImportSheet(context));
          }

          final settings = context.watch<SettingsCubit>().state;
          final theme = boardThemeFor(settings.boardTheme.name);
          final lastMove = state.lastMove;
          final highlights = <String>{};
          if (lastMove != null) {
            highlights.add(lastMove.from);
            highlights.add(lastMove.to);
          }
          final checkSquare = kingInCheckSquare(state.currentFen);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GameHeader(game: state.game!),
                const SizedBox(height: 12),
                if (state.engineAvailable || state.evaluation != null)
                  _EvalBar(
                    evaluation: state.evaluation,
                    loading: state.evalLoading,
                  ),
                const SizedBox(height: 12),
                ChessBoard(
                  fen: state.currentFen,
                  orientation: state.orientation,
                  enabled: false,
                  moveEnabled: false,
                  highlightSquares: highlights,
                  checkSquares:
                      checkSquare != null ? {checkSquare} : const {},
                  showCoordinates: settings.showCoordinates,
                  lightColor: theme.lightSquare,
                  darkColor: theme.darkSquare,
                  onMove: (_, __, {promotion}) {},
                ),
                const SizedBox(height: 12),
                _MoveControls(state: state),
                const SizedBox(height: 12),
                _MoveList(state: state),
                if (state.message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.message!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orangeAccent,
                        ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showImportSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _ImportSheet(
        onImportPgn: (pgn) {
          context.read<AnalysisBloc>().add(AnalysisImportPasted(pgn));
          Navigator.pop(sheetContext);
        },
        onImportLocal: (game) {
          context.read<AnalysisBloc>().add(AnalysisImportLocal(game));
          Navigator.pop(sheetContext);
        },
        onImportLichess: (id) {
          context.read<AnalysisBloc>().add(AnalysisImportLichess(id));
          Navigator.pop(sheetContext);
        },
        onImportChessCom: (username, year, month, index) {
          context.read<AnalysisBloc>().add(
                AnalysisImportChessCom(
                  username: username,
                  year: year,
                  month: month,
                  gameIndex: index,
                ),
              );
          Navigator.pop(sheetContext);
        },
        savedGames: context.read<GameRepository>().loadAll(),
      ),
    );
  }
}

class _EmptyAnalysis extends StatelessWidget {
  const _EmptyAnalysis({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, size: 48, color: Colors.white38),
            const SizedBox(height: 16),
            Text(
              'Import a game to analyze',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Paste PGN, pick a saved game, or fetch from Lichess / Chess.com.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white60,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Import game'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({required this.game});

  final GameRecord game;

  @override
  Widget build(BuildContext context) {
    final white = game.white ?? 'White';
    final black = game.black ?? 'Black';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$white vs $black',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          '${game.result} · ${_sourceLabel(game.source)} · ${game.moveCount} moves',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white60,
              ),
        ),
      ],
    );
  }

  String _sourceLabel(GameSource source) {
    return switch (source) {
      GameSource.local => 'Saved',
      GameSource.paste => 'Pasted PGN',
      GameSource.lichess => 'Lichess',
      GameSource.chesscom => 'Chess.com',
    };
  }
}

class _EvalBar extends StatelessWidget {
  const _EvalBar({required this.evaluation, required this.loading});

  final EngineEvaluation? evaluation;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final value = evaluation?.barValue ?? 0.5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Eval', style: Theme.of(context).textTheme.labelLarge),
            const Spacer(),
            if (loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                evaluation?.label ?? '—',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 12,
            child: Stack(
              children: [
                Container(color: Colors.black87),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    child: Container(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MoveControls extends StatelessWidget {
  const _MoveControls({required this.state});

  final AnalysisState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AnalysisBloc>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Start',
          onPressed: state.halfMoveIndex > 0
              ? () => bloc.add(const AnalysisGoToMove(0))
              : null,
          icon: const Icon(Icons.first_page),
        ),
        IconButton(
          tooltip: 'Previous',
          onPressed: state.canStepBack
              ? () => bloc.add(const AnalysisStepBack())
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('${state.halfMoveIndex} / ${state.game?.moveCount ?? 0}'),
        IconButton(
          tooltip: 'Next',
          onPressed: state.canStepForward
              ? () => bloc.add(const AnalysisStepForward())
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
        IconButton(
          tooltip: 'End',
          onPressed: state.game != null &&
                  state.halfMoveIndex < state.game!.moveCount
              ? () => bloc.add(AnalysisGoToMove(state.game!.moveCount))
              : null,
          icon: const Icon(Icons.last_page),
        ),
        IconButton(
          tooltip: 'Flip board',
          onPressed: () => bloc.add(const AnalysisFlipBoard()),
          icon: const Icon(Icons.swap_vert),
        ),
      ],
    );
  }
}

class _MoveList extends StatelessWidget {
  const _MoveList({required this.state});

  final AnalysisState state;

  @override
  Widget build(BuildContext context) {
    final game = state.game!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (var i = 0; i < game.moveSans.length; i++)
              _MoveChip(
                label: _moveLabel(i, game.moveSans[i]),
                selected: state.halfMoveIndex == i + 1,
                onTap: () => context.read<AnalysisBloc>().add(
                      AnalysisGoToMove(i + 1),
                    ),
              ),
          ],
        ),
      ),
    );
  }

  String _moveLabel(int index, String san) {
    if (index.isEven) {
      return '${index ~/ 2 + 1}. $san';
    }
    return san;
  }
}

class _MoveChip extends StatelessWidget {
  const _MoveChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      onPressed: onTap,
    );
  }
}

class _ImportSheet extends StatefulWidget {
  const _ImportSheet({
    required this.onImportPgn,
    required this.onImportLocal,
    required this.onImportLichess,
    required this.onImportChessCom,
    required this.savedGames,
  });

  final void Function(String pgn) onImportPgn;
  final void Function(SavedGame game) onImportLocal;
  final void Function(String gameIdOrUrl) onImportLichess;
  final void Function(String username, int year, int month, int index)
      onImportChessCom;
  final List<SavedGame> savedGames;

  @override
  State<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends State<_ImportSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _pgnController = TextEditingController();
  final _lichessController = TextEditingController();
  final _usernameController = TextEditingController();
  final _yearController = TextEditingController(
    text: DateTime.now().year.toString(),
  );
  final _monthController = TextEditingController(
    text: DateTime.now().month.toString(),
  );
  final _indexController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _pgnController.dispose();
    _lichessController.dispose();
    _usernameController.dispose();
    _yearController.dispose();
    _monthController.dispose();
    _indexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Import game', style: Theme.of(context).textTheme.titleLarge),
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Paste'),
              Tab(text: 'Saved'),
              Tab(text: 'Lichess'),
              Tab(text: 'Chess.com'),
            ],
          ),
          SizedBox(
            height: 280,
            child: TabBarView(
              controller: _tabs,
              children: [
                _pasteTab(),
                _savedTab(),
                _lichessTab(),
                _chessComTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pasteTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Expanded(
          child: TextField(
            controller: _pgnController,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              hintText: 'Paste PGN here…',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => widget.onImportPgn(_pgnController.text),
          child: const Text('Load PGN'),
        ),
      ],
    );
  }

  Widget _savedTab() {
    if (widget.savedGames.isEmpty) {
      return const Center(child: Text('No saved games yet.'));
    }
    return ListView.builder(
      itemCount: widget.savedGames.length,
      itemBuilder: (context, index) {
        final game = widget.savedGames[index];
        return ListTile(
          title: Text('${game.result} vs bot'),
          subtitle: Text(game.difficulty),
          onTap: () => widget.onImportLocal(game),
        );
      },
    );
  }

  Widget _lichessTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        TextField(
          controller: _lichessController,
          decoration: const InputDecoration(
            labelText: 'Game ID or URL',
            hintText: 'abc12345 or https://lichess.org/abc12345',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => widget.onImportLichess(_lichessController.text),
          child: const Text('Fetch from Lichess'),
        ),
      ],
    );
  }

  Widget _chessComTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _monthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Month',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _indexController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Game index (0 = first in month)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {
            widget.onImportChessCom(
              _usernameController.text,
              int.parse(_yearController.text),
              int.parse(_monthController.text),
              int.parse(_indexController.text),
            );
          },
          child: const Text('Fetch from Chess.com'),
        ),
      ],
    );
  }
}
