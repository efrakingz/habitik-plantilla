import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/family_provider.dart';
import '../../constants/trivia_questions.dart';
import 'shared_ui.dart';

class TriviaChallenge extends StatefulWidget {
  final VoidCallback onBack;
  final SubmitChallengeFunc onSubmit;

  const TriviaChallenge({super.key, required this.onBack, required this.onSubmit});

  static void showRanking(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _TriviaRankingSheet(),
    );
  }

  @override
  State<TriviaChallenge> createState() => _TriviaChallengeState();
}

class _TriviaRankingSheet extends StatefulWidget {
  const _TriviaRankingSheet();
  @override
  State<_TriviaRankingSheet> createState() => _TriviaRankingSheetState();
}

class _TriviaRankingSheetState extends State<_TriviaRankingSheet> {
  int _triviaCorrectCount = 0;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    int score = prefs.getInt('last_trivia_correct_count_$today') ?? 0;
    
    if (mounted) {
      final auth = context.read<AuthProvider>();
      if (auth.profile != null && auth.profile!.triviaLastUpdated == today) {
        if (auth.profile!.triviaCorrectCount > score) {
          score = auth.profile!.triviaCorrectCount;
        }
      }
      setState(() {
        _triviaCorrectCount = score;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.profile?.id;
    final familyProv = context.watch<FamilyProvider>();
    final members = List<FamilyMember>.from(familyProv.members);
    
    final Map<String, int> scores = {};
    final today = DateTime.now().toIso8601String().split('T')[0];
    for (var m in members) {
      if (m.id == currentUserId) {
        scores[m.id] = _triviaCorrectCount;
      } else {
        scores[m.id] = m.triviaLastUpdated == today ? m.triviaCorrectCount : 0;
      }
    }
    
    members.sort((a, b) => (scores[b.id] ?? 0).compareTo(scores[a.id] ?? 0));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('🏆 Ranking Diario de Trivia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.purple700)),
            const SizedBox(height: 4),
            const Text('Compite con tu familia respondiendo preguntas', style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: members.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final member = members[index];
                  final score = scores[member.id] ?? 0;
                  final isMe = member.id == currentUserId;
                  Widget rankBadge;
                  if (index == 0) rankBadge = const Text('🥇', style: TextStyle(fontSize: 24));
                  else if (index == 1) rankBadge = const Text('🥈', style: TextStyle(fontSize: 24));
                  else if (index == 2) rankBadge = const Text('🥉', style: TextStyle(fontSize: 24));
                  else rankBadge = Text('#${index + 1}', style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.bold, fontSize: 16));

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: isMe ? AppTheme.purple700.withValues(alpha: 0.08) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isMe ? AppTheme.purple700.withValues(alpha: 0.3) : Colors.grey.shade200)),
                    child: Row(
                      children: [
                        SizedBox(width: 40, child: Center(child: rankBadge)),
                        const SizedBox(width: 8),
                        Container(width: 40, height: 40, decoration: BoxDecoration(color: Color(int.parse(member.color.replaceAll('#', '0xFF'))), shape: BoxShape.circle), child: Center(child: Text(member.avatar, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Flexible(child: Text(member.nombre, style: TextStyle(color: AppTheme.textDark, fontWeight: isMe ? FontWeight.w800 : FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis)), if (isMe) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppTheme.purple700, borderRadius: BorderRadius.circular(8)), child: const Text('TÚ', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)))]]), Text(member.rol.toUpperCase(), style: const TextStyle(color: AppTheme.textLight, fontSize: 11, fontWeight: FontWeight.bold))])),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: isMe ? AppTheme.purple700 : AppTheme.purple700.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text('$score', style: TextStyle(color: isMe ? Colors.white : AppTheme.purple700, fontWeight: FontWeight.w900, fontSize: 16)), Text('correctas', style: TextStyle(color: isMe ? Colors.white70 : AppTheme.purple700, fontSize: 9, fontWeight: FontWeight.bold))])),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _TriviaChallengeState extends State<TriviaChallenge> {
  int _triviaIdx = 0;
  int _vidas = 3;
  int _triviaScore = 0;
  int? _triviaResp;
  List<TriviaQuestion> _shuffledTrivia = [];
  int _triviaCorrectCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTriviaState();
  }

  Future<void> _loadTriviaState() async {
    AuthProvider? auth;
    try {
      auth = context.read<AuthProvider>();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    int triviaScore = 0;
    if (auth != null && auth.profile != null) {
      if (auth.profile!.triviaLastUpdated == today) {
        triviaScore = auth.profile!.triviaCorrectCount;
      }
    }
    
    if (triviaScore == 0) {
      triviaScore = prefs.getInt('last_trivia_correct_count_$today') ?? 0;
    }

    if (mounted) {
      setState(() {
        _triviaCorrectCount = triviaScore;
        _isLoading = false;
        _initTrivia();
      });
    }
  }

  Future<void> _saveTriviaScore(int score) async {
    final auth = context.read<AuthProvider>();
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setInt('last_trivia_correct_count_$today', score);
    
    try {
      await auth.updateTriviaScore(score);
    } catch (_) {}
  }

  void _initTrivia() {
    final now = DateTime.now();
    final seed = now.year * 365 + now.month * 31 + now.day;
    final random = Random(seed);
    _shuffledTrivia = List.from(triviaQuestions);
    _shuffledTrivia.shuffle(random);
    _triviaIdx = _triviaCorrectCount;
    _vidas = 3;
    _triviaScore = _triviaCorrectCount * 50;
    _triviaResp = null;
  }

  Future<void> _buyTriviaLife() async {
    final auth = context.read<AuthProvider>();
    final coins = auth.profile?.monedas ?? 0;
    if (coins < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes suficientes monedas (necesitas 2 🪙)'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      await auth.deductCoins(2);
      setState(() {
        _vidas = min(3, _vidas + 1);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Vida regenerada! ❤️ +1'),
            backgroundColor: AppTheme.green500,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al regenerar vida: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildFamilyPodium() {
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.profile?.id;
    final familyProv = context.watch<FamilyProvider>();
    final members = List<FamilyMember>.from(familyProv.members);
    
    final Map<String, int> scores = {};
    final today = DateTime.now().toIso8601String().split('T')[0];
    for (var m in members) {
      if (m.id == currentUserId) {
        scores[m.id] = _triviaCorrectCount;
      } else {
        scores[m.id] = m.triviaLastUpdated == today ? m.triviaCorrectCount : 0;
      }
    }
    
    members.sort((a, b) => (scores[b.id] ?? 0).compareTo(scores[a.id] ?? 0));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.purple700.withValues(alpha: 0.05), AppTheme.purple700.withValues(alpha: 0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.purple700.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👑', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text(
                'Ranking del Hogar - Trivia',
                style: TextStyle(
                  color: AppTheme.purple700,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.purple700.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Diario ⏱️',
                  style: TextStyle(
                    color: AppTheme.purple700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (members.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Aún no hay miembros en tu familia.',
                  style: TextStyle(color: AppTheme.textLight, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final member = members[index];
                final score = scores[member.id] ?? 0;
                final isMe = member.id == currentUserId;
                
                Widget rankBadge;
                if (index == 0) {
                  rankBadge = const Text('🥇', style: TextStyle(fontSize: 18));
                } else if (index == 1) {
                  rankBadge = const Text('🥈', style: TextStyle(fontSize: 18));
                } else if (index == 2) {
                  rankBadge = const Text('🥉', style: TextStyle(fontSize: 18));
                } else {
                  rankBadge = Text(
                    '#${index + 1}',
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  );
                }

                Color itemBg = isMe
                    ? AppTheme.purple700.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.6);
                
                Color itemBorder = isMe
                    ? AppTheme.purple700.withValues(alpha: 0.25)
                    : Colors.grey.shade200;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: itemBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: itemBorder),
                    boxShadow: isMe
                        ? [BoxShadow(color: AppTheme.purple700.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                        : [],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Center(child: rankBadge),
                      ),
                      const SizedBox(width: 4),
                      
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(int.parse(member.color.replaceAll('#', '0xFF'))),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            member.avatar,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    member.nombre,
                                    style: TextStyle(
                                      color: AppTheme.textDark,
                                      fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppTheme.purple700,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'TÚ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              member.rol.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.textLight,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.purple700 : AppTheme.purple700.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$score correctas',
                          style: TextStyle(
                            color: isMe ? Colors.white : AppTheme.purple700,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ChallengeShell(
        color: AppTheme.purple700,
        title: '🧠 Trivia Infinita',
        onClose: widget.onBack,
        child: const Center(child: CircularProgressIndicator(color: AppTheme.purple700)),
      );
    }

    final coins = context.watch<AuthProvider>().profile?.monedas ?? 0;

    if (_vidas == 0) {
      return ChallengeShell(
        color: AppTheme.purple700,
        title: '🧠 Trivia Infinita',
        onClose: () { widget.onBack(); },
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('😵', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                const Text('¡Sin vidas!', style: TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('¿Quieres seguir respondiendo para llegar a las 100 preguntas?', style: TextStyle(color: AppTheme.textLight, fontSize: 13), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                
                ElevatedButton.icon(
                  onPressed: coins >= 2 ? _buyTriviaLife : null,
                  icon: const Icon(Icons.favorite, color: Colors.white),
                  label: Text('Regenerar 1 Vida (2 🪙) | Tienes: $coins 🪙', style: const TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: coins >= 2 ? AppTheme.green700 : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text('O envía tu resultado actual:', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  RewardStat(value: '$_triviaScore XP', label: 'Nivel', color: AppTheme.textDark),
                  const SizedBox(width: 20),
                  RewardStat(value: '${(_triviaScore * 0.1).round()} 🪙', label: 'Canjes', color: AppTheme.amber400),
                ]),
                const SizedBox(height: 16),
                
                ElevatedButton(
                  onPressed: () async { 
                    await widget.onSubmit('trivia', 'Trivia Infinita', _triviaScore, (_triviaScore * 0.1).round(), ['Puntaje: $_triviaScore XP', 'Respuestas correctas: $_triviaCorrectCount'], false, '#7b1fa2');
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evidencia enviada al Jefe de Familia')));
                    widget.onBack(); 
                  }, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.purple700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ), 
                  child: const Text('Enviar Resultado y Salir', style: TextStyle(fontWeight: FontWeight.w700))
                ),
                const SizedBox(height: 24),
                
                _buildFamilyPodium(),
              ],
            ),
          ),
        ),
      );
    }

    if (_triviaIdx >= 100 || _triviaIdx >= _shuffledTrivia.length) {
      return ChallengeShell(
        color: AppTheme.purple700,
        title: '🧠 Trivia Infinita',
        onClose: () { widget.onBack(); },
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('👑🏆', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                const Text('¡DIOS DE LA ECOLOGÍA!', style: TextStyle(color: AppTheme.purple700, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('Respondiste las 100 preguntas del día de forma perfecta.', style: TextStyle(color: AppTheme.textDark, fontSize: 15), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  RewardStat(value: '$_triviaScore XP', label: 'Nivel', color: AppTheme.textDark),
                  const SizedBox(width: 20),
                  RewardStat(value: '${(_triviaScore * 0.1).round()} 🪙', label: 'Canjes', color: AppTheme.amber400),
                ]),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async { 
                    final userId = context.read<AuthProvider>().profile?.id;
                    if (userId != null) {
                      context.read<AchievementProvider>().checkAndUnlock(
                        userId,
                        'trivia_100',
                        authProvider: context.read<AuthProvider>(),
                      ).ignore();
                    }
                    await widget.onSubmit('trivia', 'Trivia Infinita - 100/100', _triviaScore, (_triviaScore * 0.1).round(), ['Completó las 100 preguntas perfectas. Puntaje: $_triviaScore XP'], false, '#7b1fa2');
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evidencia de trivia perfecta enviada al Jefe de Familia')));
                    widget.onBack(); 
                  }, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.purple700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ), 
                  child: const Text('Reclamar Gran Premio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))
                ),
                const SizedBox(height: 24),
                
                _buildFamilyPodium(),
              ],
            ),
          ),
        ),
      );
    }

    final q = _shuffledTrivia[_triviaIdx];
    
    return ChallengeShell(
      color: AppTheme.purple700,
      title: '🧠 Trivia Infinita',
      onClose: () { widget.onBack(); },
      extra: Row(
        children: [
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Text(i < _vidas ? '❤️' : '🖤', style: const TextStyle(fontSize: 18)),
          )),
          const SizedBox(width: 8),
          if (_vidas < 3)
            GestureDetector(
              onTap: coins >= 2 ? _buyTriviaLife : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No tienes suficientes monedas (necesitas 2 🪙)'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 12),
                    const Icon(Icons.favorite, color: Colors.redAccent, size: 14),
                    const SizedBox(width: 2),
                    const Text('2🪙', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Pregunta ${_triviaIdx + 1} de 100', style: const TextStyle(color: AppTheme.purple700, fontWeight: FontWeight.w800, fontSize: 15)),
              Row(
                children: [
                  const Text('⭐ ', style: TextStyle(fontSize: 14)),
                  Text('$_triviaScore XP', style: const TextStyle(color: AppTheme.amber500, fontWeight: FontWeight.w900, fontSize: 15)),
                ],
              ),
            ]),
            const SizedBox(height: 12),
            
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _triviaIdx / 100.0,
                minHeight: 8,
                backgroundColor: AppTheme.purple700.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation(AppTheme.purple700),
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.purple700.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.purple700.withValues(alpha: 0.1)),
              ),
              child: Text(
                q.pregunta,
                style: const TextStyle(color: AppTheme.purple700, fontSize: 16, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            
            ...q.opciones.asMap().entries.map((e) {
              final revealed = _triviaResp != null;
              final correct = e.key == q.correcta;
              final selected = e.key == _triviaResp;
              Color bg = AppTheme.purple700.withValues(alpha: 0.05);
              if (revealed && correct) bg = AppTheme.green500.withValues(alpha: 0.2);
              if (revealed && selected && !correct) bg = Colors.red.withValues(alpha: 0.15);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: revealed ? null : () {
                      setState(() => _triviaResp = e.key);
                      final isCorrect = correct;
                      if (isCorrect) {
                        _triviaScore += 50;
                        _triviaCorrectCount++;
                        _saveTriviaScore(_triviaCorrectCount);
                        
                        final userId = context.read<AuthProvider>().profile?.id;
                        if (userId != null) {
                          final achievementProv = context.read<AchievementProvider>();
                          final authProv = context.read<AuthProvider>();
                          if (_triviaCorrectCount == 25) {
                            achievementProv.checkAndUnlock(userId, 'trivia_25', authProvider: authProv).ignore();
                          } else if (_triviaCorrectCount == 50) {
                            achievementProv.checkAndUnlock(userId, 'trivia_50', authProvider: authProv).ignore();
                          } else if (_triviaCorrectCount == 75) {
                            achievementProv.checkAndUnlock(userId, 'trivia_75', authProvider: authProv).ignore();
                          } else if (_triviaCorrectCount == 100) {
                            achievementProv.checkAndUnlock(userId, 'trivia_100', authProvider: authProv).ignore();
                          }
                        }
                      } else {
                        _vidas--;
                      }
                      
                      Future.delayed(const Duration(milliseconds: 1200), () {
                        if (mounted) {
                          setState(() {
                            _triviaResp = null;
                            _triviaIdx++;
                          });
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bg,
                      foregroundColor: revealed && !correct && !selected ? Colors.grey : AppTheme.purple700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      side: BorderSide(
                        color: revealed && correct
                            ? AppTheme.green600
                            : (revealed && selected && !correct
                                ? Colors.redAccent
                                : AppTheme.purple700.withValues(alpha: 0.1)),
                        width: revealed ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            e.value,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                        if (revealed && correct) const Text('✅', style: TextStyle(fontSize: 16)),
                        if (revealed && selected && !correct) const Text('❌', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              );
            }),
            
            const SizedBox(height: 24),
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 20),
            
            _buildFamilyPodium(),
          ],
        ),
      ),
    );
  }
}
