import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/evidence_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../providers/family_provider.dart';

import 'challenges/games/ducha_challenge.dart';
import 'challenges/games/trivia_challenge.dart';
import 'challenges/games/puzzle_challenge.dart';
import 'challenges/games/evidence_challenge.dart';
import 'challenges/games/wordle_challenge.dart';
class ChallengesScreen extends StatefulWidget {
  final String active;
  final VoidCallback onBack;
  final void Function(String) onSelect;

  const ChallengesScreen({super.key, required this.active, required this.onBack, required this.onSelect});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  int _triviaCorrectCount = 0;
  bool _dailyBonusClaimed = false;

  @override
  void initState() {
    super.initState();
    _loadBonusState();
  }

  Future<void> _loadBonusState() async {
    // Read AuthProvider before async gaps to satisfy use_build_context_synchronously
    AuthProvider? auth;
    try {
      auth = context.read<AuthProvider>();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Determine if daily bonus is claimed from Supabase profile, fallback to SP
    bool claimed = false;
    if (auth != null && auth.profile != null) {
      claimed = auth.profile!.dailyBonusClaimedAt == today;
    }
    if (!claimed) {
      final claimedDate = prefs.getString('daily_bonus_claimed_date');
      claimed = claimedDate == today;
    }
    
    // Read Supabase score first via AuthProvider
    int triviaScore = 0;
    if (auth != null && auth.profile != null) {
      if (auth.profile!.triviaLastUpdated == today) {
        triviaScore = auth.profile!.triviaCorrectCount;
      }
    }
    
    // Fallback to local cache if Supabase didn't have today's score
    if (triviaScore == 0) {
      triviaScore = prefs.getInt('last_trivia_correct_count_$today') ?? 0;
    }

    setState(() {
      _dailyBonusClaimed = claimed;
      _triviaCorrectCount = triviaScore;
    });
  }



  Future<void> _claimDailyBonus() async {
    final auth = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final userId = auth.user?.id;
    if (userId == null) return;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Optimistic UI update
    setState(() => _dailyBonusClaimed = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('daily_bonus_claimed_date', today);
    } catch (_) {}

    try {
      await auth.updateDailyBonusClaimedAt(today);
      // Award XP and coins directly to the member
      await taskProvider.rewardUser(userId, 30, 5);
    } catch (e) {
      debugPrint('Error claiming daily bonus in Supabase: $e');
    }

    if (!mounted) return;
    await auth.refreshProfile();
    if (!mounted) return;

    // Add bonus evidence to feed
    final familyId = auth.profile?.familyId;
    if (familyId != null) {
      context.read<EvidenceProvider>().addEvidence(
        Evidence(
          userId: userId,
          familyId: familyId,
          autor: auth.profile?.nombre ?? 'Usuario',
          avatar: auth.profile?.avatarLetra ?? 'U',
          color: auth.profile?.avatarColor ?? '#2e7d32',
          avatarUrl: auth.profile?.avatarUrl,
          accion: 'âš¡ Bonus de constancia diaria desbloqueado',
          desc: 'CompletÃ³ 2 retos diferentes hoy y ganÃ³ +30 XP Â· +5 ðŸª™',
          likes: 0,
          tiempo: DateTime.now().toIso8601String(),
          xp: 30,
          emoji: 'âš¡',
        ),
        achievementProvider: context.read<AchievementProvider>(),
        authProvider: context.read<AuthProvider>(),
      );
    }

    // Trigger racha_constancia achievement
    context.read<AchievementProvider>().checkAndUnlock(
      userId,
      'racha_constancia',
      authProvider: context.read<AuthProvider>(),
    ).ignore();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          Icon(Icons.bolt, color: Colors.white),
          SizedBox(width: 8),
          Text('Â¡Bonus de Constancia desbloqueado! +30 XP Â· +5 ðŸª™', style: TextStyle(fontWeight: FontWeight.w700)),
        ]),
        backgroundColor: Color(0xFF7B1FA2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  final List<ChallengeType> _retos = [
    ChallengeType(id: 'ducha', emoji: 'ðŸš¿', titulo: 'Speedrun de la Ducha', desc: 'DÃºchate en menos de 10 min', xp: 50, monedas: 5, color: '#1565c0'),
    ChallengeType(id: 'inspeccion', emoji: 'ðŸ”', titulo: 'InspecciÃ³n del DÃ­a', desc: 'MisiÃ³n rotativa para el hogar', xp: 100, monedas: 15, color: '#f57c00'),
    ChallengeType(id: 'trivia', emoji: 'ðŸ§ ', titulo: 'Trivia Infinita', desc: '3 vidas Â· preguntas de ecologÃ­a', xp: 150, monedas: 15, color: '#7b1fa2'),
    ChallengeType(id: 'puzzle', emoji: 'ðŸŽ¯', titulo: 'Eco-Puzzle TemÃ¡tico', desc: 'Clasifica residuos en 60s', xp: 120, monedas: 20, color: '#c62828'),
    ChallengeType(id: 'wordle', emoji: 'ðŸ”¤', titulo: 'Eco-Wordle del DÃ­a', desc: 'Adivina la palabra ecolÃ³gica de hoy', xp: 50, monedas: 5, color: '#2e7d32'),
  ];
  
  Color _parseColor(String hex) => Color(int.parse(hex.replaceAll('#', '0xFF')));

  Future<void> _submitChallenge(String id, String title, int xp, int monedas, List<String> evidencias, bool requiereEvidencia, String color) async {
    final auth = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final achievementProvider = context.read<AchievementProvider>();
    final familyMembers = context.read<FamilyProvider>().members;
    if (auth.profile == null) return;
    
    List<String> finalEvidencias = [];
    
    // Upload local images to Supabase Storage if present
    if (evidencias.isNotEmpty && evidencias.first != 'Canje') {
      final client = Supabase.instance.client;
      for (final path in evidencias) {
        if (path.contains('/') || path.contains('\\')) {
          try {
            final file = File(path);
            final bytes = await file.readAsBytes();
            final ext = path.split('.').last;
            final fileName = 'evidences/${auth.profile!.id}-${DateTime.now().millisecondsSinceEpoch}.$ext';
            
            await client.storage.from('avatars').uploadBinary(fileName, bytes);
            final url = client.storage.from('avatars').getPublicUrl(fileName);
            finalEvidencias.add(url);
          } catch (e) {
            debugPrint('Error uploading evidence image: $e');
          }
        } else {
          finalEvidencias.add(path); // Fallback for non-file string evidences
        }
      }
    } else {
      finalEvidencias = List.from(evidencias);
    }

    // For retos that DON'T require jefe evidence validation, reward directly
    if (!requiereEvidencia) {
      final leveledUp = await taskProvider.rewardUser(auth.profile!.id, xp, monedas);
      if (leveledUp && mounted) {
        NotificationProvider.writeNotificationForUser(
          auth.profile!.id,
          NotificationItem(
            id: '${DateTime.now().millisecondsSinceEpoch}_nivel',
            title: 'Â¡Subiste de nivel!',
            desc: 'Â¡Felicidades! Has alcanzado un nuevo nivel por completar $title.',
            time: DateTime.now().toIso8601String(),
            iconCode: 'emoji_events',
            colorHex: '#F9A825',
          ),
        );
      }
      if (!mounted) return;
      await auth.refreshProfile();
      if (!mounted) return;
    } else {
      // Reto requiere validaciÃ³n -> notificar a los jefes
      final jefes = familyMembers.where((m) => m.rol.toLowerCase().contains('jefe')).toList();
      for (var jefe in jefes) {
        NotificationProvider.writeNotificationForUser(
          jefe.id,
          NotificationItem(
            id: '${DateTime.now().millisecondsSinceEpoch}_val',
            title: 'ValidaciÃ³n pendiente',
            desc: '${auth.profile!.nombre.split(' ')[0]} completÃ³ "$title".',
            time: DateTime.now().toIso8601String(),
            iconCode: 'check_circle',
            colorHex: '#1976D2',
          ),
        );
      }
    }

    // Always register a pending validation so jefe sees completed retos
    await taskProvider.addValidation(
      PendingValidation(
        id: DateTime.now().millisecondsSinceEpoch,
        userId: auth.profile!.id,
        usuario: auth.profile!.nombre,
        avatar: auth.profile!.nombre[0],
        color: color,
        reto: title,
        hora: 'ReciÃ©n',
        xp: xp,
        monedas: monedas,
        evidencias: finalEvidencias,
        requiereEvidencia: requiereEvidencia,
      ),
      familyId: auth.profile!.familyId,
      achievementProvider: achievementProvider,
      authProvider: auth,
    );
    if (!mounted) return;
    taskProvider.markRetoCompleted(id);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.active == 'ducha') return DuchaChallenge(onBack: widget.onBack, onSubmit: _submitChallenge);
    if (widget.active == 'trivia') return TriviaChallenge(onBack: widget.onBack, onSubmit: _submitChallenge);
    if (widget.active == 'puzzle') return PuzzleChallenge(onBack: widget.onBack, onSubmit: _submitChallenge);
    if (widget.active == 'inspeccion') return EvidenceChallenge(active: widget.active, onBack: widget.onBack, onSubmit: _submitChallenge);
    if (widget.active == 'wordle') return WordleChallenge(onBack: widget.onBack, onSubmit: _submitChallenge);

    return _buildChallengeList();
  }

  Widget _buildChallengeList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('GamificaciÃ³n', style: TextStyle(color: AppTheme.green200, fontSize: 12)),
              const Text('Retos del DÃ­a', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Racha semanal
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppTheme.amber400.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.amber400.withValues(alpha: 0.3))),
                    child: Column(
                      children: [
                        const Row(children: [
                          Text('ðŸ”¥', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 6),
                          Text('Racha semanal', style: TextStyle(color: AppTheme.amber400, fontSize: 14, fontWeight: FontWeight.w900)),
                        ]),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final auth = context.watch<AuthProvider>();
                            final evidenceProv = context.watch<EvidenceProvider>();
                            final taskProv = context.watch<TaskProvider>();
                            final now = DateTime.now();
                            final currentWeekday = now.weekday; // 1 = Lunes, 7 = Domingo
                            final monday = now.subtract(Duration(days: currentWeekday - 1));
                            final weekDays = ['Lun', 'Mar', 'MiÃ©', 'Jue', 'Vie', 'SÃ¡b', 'Dom'];
                            
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(7, (index) {
                                final dayDate = monday.add(Duration(days: index));
                                final isToday = dayDate.day == now.day && dayDate.month == now.month && dayDate.year == now.year;
                                final isPast = dayDate.isBefore(DateTime(now.year, now.month, now.day));
                                
                                final done = _hasCompletedRetoOnDay(
                                  dayDate,
                                  auth.user?.id,
                                  evidenceProv.evidences,
                                  taskProv.pendingValidations,
                                  taskProv.completedRetos,
                                );
                                final missed = isPast && !done;
                                
                                return Column(
                                  children: [
                                    Container(
                                      width: 30, height: 30,
                                      decoration: BoxDecoration(
                                        color: done ? AppTheme.green500 : (missed ? Colors.red.shade100 : (isToday ? AppTheme.amber400.withValues(alpha: 0.2) : Colors.grey.shade100)),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: done ? AppTheme.green600 : (missed ? Colors.red.shade300 : (isToday ? AppTheme.amber400 : Colors.grey.shade200))),
                                      ),
                                      child: done 
                                        ? const Icon(Icons.check, color: Colors.white, size: 16) 
                                        : (missed ? const Icon(Icons.close, color: Colors.red, size: 16) 
                                        : (isToday ? const Icon(Icons.circle, color: AppTheme.amber400, size: 8) : null)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text('${dayDate.day}', style: TextStyle(fontSize: 11, fontWeight: isToday ? FontWeight.w900 : FontWeight.normal, color: done ? AppTheme.green700 : (missed ? Colors.red.shade700 : (isToday ? AppTheme.amber400 : Colors.grey.shade600)))),
                                    Text(weekDays[index], style: TextStyle(fontSize: 9, color: done ? AppTheme.green700 : (missed ? Colors.red.shade400 : Colors.grey.shade400))),
                                  ],
                                );
                              }),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // â”€â”€ Bonus de constancia diaria â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Builder(builder: (context) {
                    final completed = context.watch<TaskProvider>().completedRetos.length;
                    final canClaim = completed >= 2 && !_dailyBonusClaimed;
                    final progress = completed.clamp(0, 2);
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _dailyBonusClaimed
                            ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]
                            : [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _dailyBonusClaimed
                            ? AppTheme.green400
                            : const Color(0xFF7B1FA2).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('âš¡', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 6),
                              const Text('Bonus de Constancia Diaria',
                                style: TextStyle(color: Color(0xFF7B1FA2), fontSize: 14, fontWeight: FontWeight.w900)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7B1FA2).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Text('+30 XP', style: TextStyle(color: Color(0xFF7B1FA2), fontSize: 10, fontWeight: FontWeight.w900)),
                                  const Text(' Â· ', style: TextStyle(color: Color(0xFF7B1FA2), fontSize: 10)),
                                  const Text('+5 ðŸª™', style: TextStyle(color: Color(0xFF7B1FA2), fontSize: 10, fontWeight: FontWeight.w900)),
                                ]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _dailyBonusClaimed
                              ? 'âœ… Bonus reclamado hoy. Â¡Vuelve maÃ±ana!'
                              : 'Completa 2 retos hoy para desbloquear el bonus',
                            style: TextStyle(
                              color: _dailyBonusClaimed ? AppTheme.green700 : const Color(0xFF6A1B9A),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress / 2,
                              minHeight: 8,
                              backgroundColor: Colors.white.withValues(alpha: 0.5),
                              valueColor: AlwaysStoppedAnimation(
                                _dailyBonusClaimed ? AppTheme.green500 : const Color(0xFF7B1FA2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$progress / 2 retos completados',
                                style: const TextStyle(color: Color(0xFF7B1FA2), fontSize: 11)),
                              if (canClaim)
                                GestureDetector(
                                  onTap: _claimDailyBonus,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7B1FA2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text('Â¡Reclamar!',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                                  ),
                                )
                              else if (_dailyBonusClaimed)
                                const Icon(Icons.check_circle, color: AppTheme.green500, size: 18),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 14),

                  // Grid de retos
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: _retos.map((r) => GestureDetector(
                      onTap: () {
                        if (context.read<TaskProvider>().completedRetos.contains(r.id)) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya has realizado este reto hoy, espera a maÃ±ana', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: AppTheme.amber400, behavior: SnackBarBehavior.floating));
                        } else {
                          widget.onSelect(r.id);
                        }
                      },
                      child: Container(
                        width: (MediaQuery.of(context).size.width - 60) / 2,
                        height: 165, // Fixed height so all cards are identical in size
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: _parseColor(r.color).withValues(alpha: 0.05), border: Border.all(color: _parseColor(r.color).withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(
                                        color: _parseColor(r.color).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(child: Text(r.emoji, style: const TextStyle(fontSize: 20))),
                                    ),
                                    if (context.watch<TaskProvider>().completedRetos.contains(r.id))
                                      Positioned(
                                        right: -2, top: -2,
                                        child: Container(
                                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                          child: const Icon(Icons.check_circle, color: AppTheme.green600, size: 14),
                                        ),
                                      ),
                                  ],
                                ),
                                if (r.id == 'trivia')
                                  GestureDetector(
                                    onTap: () {
                                      TriviaChallenge.showRanking(context);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.amber400.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.emoji_events, color: AppTheme.amber500, size: 16),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              r.titulo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              r.desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.textLight, fontSize: 11),
                            ),
                            const Spacer(), // Pushes rewards row to the bottom of the card
                            Row(
                              children: [
                                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _parseColor(r.color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text('+${r.xp} XP', style: TextStyle(color: _parseColor(r.color), fontSize: 10, fontWeight: FontWeight.w900))),
                                const SizedBox(width: 4),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppTheme.amber400.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)), child: Text('+${r.monedas} ðŸª™', style: const TextStyle(color: AppTheme.amber400, fontSize: 10, fontWeight: FontWeight.w900))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _hasCompletedRetoOnDay(
    DateTime dayDate,
    String? userId,
    List<Evidence> evidences,
    List<PendingValidation> pending,
    Set<String> completedToday,
  ) {
    if (userId == null) return false;

    final now = DateTime.now();
    final isToday = dayDate.day == now.day && dayDate.month == now.month && dayDate.year == now.year;
    
    if (isToday && completedToday.isNotEmpty) {
      return true;
    }

    final hasEvidence = evidences.any((e) {
      if (e.userId != userId) return false;
      try {
        final dt = DateTime.parse(e.tiempo).toLocal();
        return dt.day == dayDate.day && dt.month == dayDate.month && dt.year == dayDate.year;
      } catch (_) {
        return false;
      }
    });
    if (hasEvidence) return true;

    final hasPending = pending.any((pv) {
      if (pv.userId != userId) return false;
      final dt = DateTime.fromMillisecondsSinceEpoch(pv.id).toLocal();
      return dt.day == dayDate.day && dt.month == dayDate.month && dt.year == dayDate.year;
    });
    return hasPending;
  }
}
