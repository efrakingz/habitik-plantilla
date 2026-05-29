import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import 'puzzle_game.dart';
import '../../providers/auth_provider.dart';
import '../../providers/achievement_provider.dart';
import 'shared_ui.dart';

class PuzzleChallenge extends StatefulWidget {
  final VoidCallback onBack;
  final SubmitChallengeFunc onSubmit;

  const PuzzleChallenge({super.key, required this.onBack, required this.onSubmit});

  @override
  State<PuzzleChallenge> createState() => _PuzzleChallengeState();
}

class _PuzzleChallengeState extends State<PuzzleChallenge> {
  @override
  Widget build(BuildContext context) {
    final pzColor = DateTime.now().weekday == 1 
      ? AppTheme.green700 
      : (DateTime.now().weekday == 3 
        ? const Color(0xFFE65100) 
        : (DateTime.now().weekday == 5 ? AppTheme.blue700 : AppTheme.red700));
    
    final pzTitle = DateTime.now().weekday == 1 
      ? 'Eco-Puzzle (Orgánicos)' 
      : (DateTime.now().weekday == 3 
        ? 'Eco-Puzzle (Chatarra y Pilas)' 
        : (DateTime.now().weekday == 5 ? 'Eco-Puzzle (Envases)' : 'Eco-Puzzle'));

    return ChallengeShell(
      color: pzColor,
      title: '🎯 $pzTitle',
      onClose: widget.onBack,
      extra: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: pzColor.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(12)),
        child: const Text('60s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
      child: SingleChildScrollView(
        child: EcoPuzzleGame(
          onComplete: (xp, monedas) async {
            if (xp >= 120) {
              final userId = context.read<AuthProvider>().profile?.id;
              if (userId != null) {
                context.read<AchievementProvider>().checkAndUnlock(
                  userId,
                  'eco_puzzle',
                  authProvider: context.read<AuthProvider>(),
                ).ignore();
              }
            }
            await widget.onSubmit('puzzle', pzTitle, xp, monedas, [], false, '#c62828');
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evidencia enviada al Jefe de Familia')));
            widget.onBack();
          },
        ),
      ),
    );
  }
}
