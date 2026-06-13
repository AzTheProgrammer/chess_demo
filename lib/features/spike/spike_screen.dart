import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import '../../core/widgets/chess_board.dart';
import '../../infrastructure/stockfish/stockfish_service.dart';

class SpikeScreen extends StatefulWidget {
  const SpikeScreen({super.key});

  @override
  State<SpikeScreen> createState() => _SpikeScreenState();
}

class _SpikeScreenState extends State<SpikeScreen> {
  String _fen = chess.Chess.DEFAULT_POSITION;
  String? _engineMove;
  String? _status;
  bool _busy = false;
  StockfishService? _engine;

  @override
  void initState() {
    super.initState();
    _bootEngine();
  }

  Future<void> _bootEngine() async {
    if (!StockfishService.isSupported) {
      setState(() {
        _status =
            'Stockfish FFI unavailable on this platform (Android/iOS only). '
            'Board + rules still testable here.';
      });
      return;
    }
    setState(() => _status = 'Starting Stockfish…');
    final engine = StockfishService();
    try {
      await engine.start();
      if (!mounted) {
        engine.dispose();
        return;
      }
      setState(() {
        _engine = engine;
        _status = 'Stockfish ready';
      });
    } catch (error) {
      engine.dispose();
      setState(() => _status = 'Engine failed: $error');
    }
  }

  @override
  void dispose() {
    _engine?.dispose();
    super.dispose();
  }

  void _onMove(String from, String to, {String? promotion}) {
    final next = applyMove(_fen, from, to, promotion: promotion);
    if (next == null) return;
    setState(() {
      _fen = next;
      _engineMove = null;
    });
  }

  Future<void> _askEngine() async {
    final engine = _engine;
    if (engine == null) return;
    setState(() {
      _busy = true;
      _status = 'Searching…';
    });
    final sw = Stopwatch()..start();
    try {
      final move = await engine.bestMove(fen: _fen, movetimeMs: 2500);
      sw.stop();
      if (!mounted) return;
      setState(() {
        _engineMove = move;
        _status = 'Engine: $move in ${sw.elapsedMilliseconds}ms';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'Search failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phase 0 Spike')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChessBoard(fen: _fen, onMove: _onMove, enabled: !_busy),
              const SizedBox(height: 12),
              Text(_status ?? '', style: Theme.of(context).textTheme.bodyMedium),
              if (_engineMove != null) Text('Suggested: $_engineMove'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _engine != null && !_busy ? _askEngine : null,
                child: const Text('Get engine move (<3s)'),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _fen = chess.Chess.DEFAULT_POSITION;
                          _engineMove = null;
                        }),
                child: const Text('Reset board'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
