import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/evidence_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/notification_provider.dart';
import '../../components/bottom_nav.dart';
import '../../components/avatar_badge.dart';
import '../../components/role_badge.dart';
import '../challenges/challenges_screen.dart';
import '../scan_screen.dart';
import '../control/control_screen.dart';
import '../profile_screen.dart';
import '../notifications_screen.dart';
import '../rewards_screen.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardController()..initData(context),
      child: const _DashboardScreenContent(),
    );
  }
}

class _DashboardScreenContent extends StatelessWidget {
  const _DashboardScreenContent();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isJefe = auth.profile?.rol.toLowerCase() == 'jefe' || 
                   auth.profile?.rol.toLowerCase() == 'jefa' || 
                   auth.profile?.rol.toLowerCase() == 'co-admin' || 
                   auth.profile?.rol.toLowerCase() == 'coadmin';
    final controller = context.watch<DashboardController>();

    return Scaffold(
      body: Container(
        color: AppTheme.green700,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(child: _buildBody(context, controller, isJefe)),
              BottomNav(
                currentIndex: controller.currentIndex,
                onTap: controller.setTabIndex,
                isJefe: isJefe,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DashboardController controller, bool isJefe) {
    switch (controller.currentIndex) {
      case 0: return _buildDashboard(context, controller);
      case 1: return ChallengesScreen(
        active: controller.activeChallenge, 
        onBack: () => controller.setActiveChallenge(''), 
        onSelect: controller.setActiveChallenge
      );
      case 2: return isJefe ? ScanScreen(
        tab: controller.scanTab, 
        state: controller.scanState, 
        onTabChange: controller.setScanTab, 
        onStateChange: controller.setScanState
      ) : _buildDashboard(context, controller);
      case 3: return const RewardsScreen();
      case 4: return isJefe ? ControlScreen(
        metaLuz: controller.metaLuz, 
        metaAgua: controller.metaAgua, 
        onMetaLuzChanged: controller.setMetaLuz, 
        onMetaAguaChanged: controller.setMetaAgua
      ) : _buildDashboard(context, controller);
      default: return _buildDashboard(context, controller);
    }
  }

  Widget _buildDashboard(BuildContext context, DashboardController controller) {
    final auth = context.watch<AuthProvider>();
    final familyProvider = context.watch<FamilyProvider>();
    final profile = auth.profile;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      familyProvider.familyAvatar != null && familyProvider.familyAvatar!.trim().isNotEmpty
                        ? CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(familyProvider.familyAvatar!),
                            backgroundColor: AppTheme.green700,
                            onBackgroundImageError: (e, s) => debugPrint('Error loading family avatar'),
                          )
                        : const CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.green700,
                            child: Text('MH', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Hola, ${familyProvider.familyName}!', style: const TextStyle(color: AppTheme.green200, fontSize: 12)),
                              const SizedBox(width: 6),
                              if (profile != null) RoleBadge(rol: profile.rol),
                            ],
                          ),
                          const Text('Muro Familiar', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                    child: Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(color: AppTheme.green600, shape: BoxShape.circle),
                      child: Stack(
                        children: [
                          const Center(child: Icon(Icons.notifications_outlined, color: Colors.white, size: 18)),
                          if (context.watch<NotificationProvider>().unreadCount > 0)
                            Positioned(top: 2, right: 2, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppTheme.amber400, shape: BoxShape.circle))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                      child: AvatarBadge(
                        letter: profile?.avatarLetra ?? 'U',
                        colorHex: profile?.avatarColor ?? '#2e7d32',
                        avatarUrl: profile?.avatarUrl,
                        radius: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.green600,
            backgroundColor: Colors.white,
            onRefresh: () => controller.refresh(context),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEnergyBar(context, controller),
                    const SizedBox(height: 16),
                    _buildRanking(context),
                    const SizedBox(height: 16),
                    const Text('Feed de Evidencias', style: TextStyle(color: AppTheme.textDark, fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Consumer<EvidenceProvider>(
                      builder: (context, evidenceProvider, _) {
                        if (evidenceProvider.isLoading) {
                          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppTheme.green500)));
                        }
                        if (evidenceProvider.evidences.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: Text('Aún no hay evidencias en la familia', style: TextStyle(color: AppTheme.textLight))),
                          );
                        }
                        return Column(
                          children: evidenceProvider.evidences.asMap().entries.map((e) => _buildEvidenceCard(context, e.key, e.value)).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnergyBar(BuildContext context, DashboardController controller) {
    final billProvider = context.watch<BillProvider>();
    final energyPct = billProvider.familyEnergyPercent(controller.metaLuz, controller.metaAgua);
    final pctDisplay = (energyPct * 100).round();

    final luzChange = billProvider.consumoChangePercent('luz');
    final aguaChange = billProvider.consumoChangePercent('agua');
    final luzSaving = billProvider.savingsAmount('luz');
    final aguaSaving = billProvider.savingsAmount('agua');

    final luzLabel = luzChange != null
        ? '${luzChange < 0 ? '-' : '+'}${luzChange.abs().toStringAsFixed(0)}%'
        : '--';
    final aguaLabel = aguaChange != null
        ? '${aguaChange < 0 ? '-' : '+'}${aguaChange.abs().toStringAsFixed(0)}%'
        : '--';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.green700, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Barra de Energia Familiar', style: TextStyle(color: AppTheme.green200, fontSize: 12)),
                  Text('Contribucion colectiva del mes', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
              Text('$pctDisplay%', style: const TextStyle(color: AppTheme.amber400, fontSize: 28, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              child: LinearProgressIndicator(
                value: energyPct,
                backgroundColor: AppTheme.green600,
                valueColor: AlwaysStoppedAnimation(
                  energyPct >= 0.75 ? AppTheme.amber400 : energyPct >= 0.4 ? Colors.orangeAccent : Colors.redAccent,
                ),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _savingsCard(Icons.bolt, AppTheme.amber400, 'Ahorro Luz', luzSaving, luzLabel, luzChange)),
              const SizedBox(width: 8),
              Expanded(child: _savingsCard(Icons.water_drop, Colors.lightBlueAccent, 'Ahorro Agua', aguaSaving, aguaLabel, aguaChange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _savingsCard(IconData icon, Color color, String title, String amount, String changeLabel, double? change) {
    final isGood = change != null && change <= 0;
    final isNeutral = change == null;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppTheme.green600, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(title, style: const TextStyle(color: AppTheme.green200, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Text(amount, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: isNeutral ? Colors.white12 : isGood ? Colors.green.shade800 : Colors.red.shade800,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isNeutral ? 'Sin datos' : (isGood ? '↓ $changeLabel' : '↑ $changeLabel'),
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRanking(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ranking XP', style: TextStyle(color: AppTheme.textDark, fontSize: 15, fontWeight: FontWeight.w800)),
            Text('Este mes', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Consumer<FamilyProvider>(
          builder: (context, familyProvider, _) {
            if (familyProvider.isLoading) {
              return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppTheme.green500)));
            }
            final miembros = familyProvider.members;
            if (miembros.isEmpty) return const SizedBox.shrink();
            
            return Column(
              children: miembros.asMap().entries.map((entry) {
                final i = entry.key;
                final m = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.green50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      SizedBox(width: 24, child: Text('${i + 1}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.amber400))),
                      AvatarBadge(letter: m.avatar, colorHex: m.color, avatarUrl: m.avatarUrl, radius: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(m.nombre, style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w700)),
                                const SizedBox(width: 4),
                                RoleBadge(rol: m.rol),
                              ],
                            ),
                            Text('Nivel ${m.nivel}', style: const TextStyle(color: AppTheme.textLight, fontSize: 11)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${m.xp} XP', style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w900)),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: SizedBox(
                              width: 48, height: 4,
                              child: LinearProgressIndicator(value: (m.xp / (miembros[0].xp > 0 ? miembros[0].xp : 1)).clamp(0.0, 1.0), backgroundColor: AppTheme.green100, valueColor: const AlwaysStoppedAnimation(AppTheme.green600)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _formatTime(String timeStr) {
    try {
      final date = DateTime.parse(timeStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Recién';
      if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
      if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
      return '${date.day}/${date.month}';
    } catch (_) {
      return timeStr;
    }
  }

  Widget _buildEvidenceCard(BuildContext context, int index, Evidence e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: AppTheme.green100), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarBadge(letter: e.avatar, colorHex: e.color, avatarUrl: e.avatarUrl, radius: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(text: e.autor, style: const TextStyle(color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.w700)),
                          TextSpan(text: ' - ${_formatTime(e.tiempo)}', style: const TextStyle(color: AppTheme.textLight, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(e.accion, style: const TextStyle(color: AppTheme.green500, fontSize: 11), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.amber400.withAlpha(51), borderRadius: BorderRadius.circular(20)),
                child: Text('+${e.xp} XP', style: const TextStyle(color: AppTheme.amber400, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.green50, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Text(e.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(child: Text(e.desc, style: const TextStyle(color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          if (e.imagen != null && e.imagen!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (dlgCtx) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(16),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            e.imagen!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                                child: const Column(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Imagen no disponible', style: TextStyle(color: Colors.grey)),
                                ]),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 30, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
                            onPressed: () => Navigator.pop(dlgCtx),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  e.imagen!, 
                  height: 90, 
                  width: 90, 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 90,
                      width: 90,
                      color: AppTheme.green100,
                      child: const Center(child: Icon(Icons.broken_image, color: AppTheme.green300)),
                    );
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Builder(
            builder: (context) {
              final isLiked = context.watch<EvidenceProvider>().likedEvidenceIds.contains(e.id);
              return GestureDetector(
                onTap: () {
                  final auth = context.read<AuthProvider>();
                  if (auth.user != null) {
                    context.read<EvidenceProvider>().toggleLike(e, auth.user!.id);
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.redAccent : AppTheme.green500,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${e.likes}',
                      style: TextStyle(
                        color: isLiked ? Colors.redAccent : AppTheme.green500,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }
          ),
        ],
      ),
    );
  }
}
