import 'package:flutter/material.dart';
import 'dart:async';
import '../../config/theme.dart';
import 'shared_ui.dart';

class DuchaChallenge extends StatefulWidget {
  final VoidCallback onBack;
  final SubmitChallengeFunc onSubmit;

  const DuchaChallenge({super.key, required this.onBack, required this.onSubmit});

  @override
  State<DuchaChallenge> createState() => _DuchaChallengeState();
}

class _DuchaChallengeState extends State<DuchaChallenge> {
  int _timerSec = 0;
  bool _timerRunning = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _timerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _timerSec++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _timerRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() { _timerRunning = false; _timerSec = 0; });
  }

  String _fmtTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final done = _timerSec > 0 && !_timerRunning;
    final xp = _timerSec <= 600 ? 50 : 0;
    final monedas = _timerSec <= 600 ? 20 : 0;
    
    return ChallengeShell(
      color: AppTheme.blue700,
      title: '🚿 Speedrun de la Ducha',
      onClose: () { _resetTimer(); widget.onBack(); },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_fmtTime(_timerSec), style: const TextStyle(color: AppTheme.blue700, fontSize: 64, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
            const SizedBox(height: 8),
            Text(
              _timerSec == 0 ? 'Presiona Iniciar cuando entres' : _timerRunning ? '¡Duchándose!' : '¡Ducha terminada!',
              style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
            ),
            const SizedBox(height: 20),
            if (!done)
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _timerRunning ? _stopTimer : _startTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _timerRunning ? Colors.redAccent : AppTheme.green700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(_timerSec == 0 ? '🚿 Iniciar' : '⏹ Terminar', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.green50, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    const Text('Resultado', style: TextStyle(color: AppTheme.green600, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RewardStat(value: '+$xp XP', label: 'Para nivel', color: AppTheme.textDark),
                        const SizedBox(width: 20),
                        RewardStat(value: '+$monedas 🪙', label: 'Canjes', color: AppTheme.amber400),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async { 
                  await widget.onSubmit('ducha', 'Speedrun de la Ducha', xp, monedas, [_fmtTime(_timerSec)], false, '#1565c0');
                  _resetTimer(); 
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evidencia enviada al Jefe de Familia')));
                  widget.onBack(); 
                }, 
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green700), 
                child: const Text('Enviar Evidencia', style: TextStyle(color: Colors.white))
              ),
            ],
          ],
        ),
      ),
    );
  }
}
