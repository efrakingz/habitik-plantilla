import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/models.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/evidence_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/achievement_provider.dart';
import 'profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final controller = ProfileController();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final auth = context.read<AuthProvider>();
          final achievementProv = context.read<AchievementProvider>();
          if (auth.profile != null) {
            achievementProv.checkProfileAchievements(auth.profile!, auth);
          }
        });
        return controller;
      },
      child: const _ProfileScreenContent(),
    );
  }
}

class _ProfileScreenContent extends StatelessWidget {
  const _ProfileScreenContent();

  Color _parseColor(String hex) => Color(int.parse(hex.replaceAll('#', '0xFF')));

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final family = context.watch<FamilyProvider>();
    final achievementProv = context.watch<AchievementProvider>();
    final controller = context.watch<ProfileController>();
    final profile = auth.profile;

    if (profile == null) {
      if (auth.user == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        color: AppTheme.green700,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(width: 32, height: 32, decoration: const BoxDecoration(color: AppTheme.green600, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 18)),
                    ),
                    const SizedBox(width: 12),
                    const Text('Mi Perfil', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 40, 
                                        backgroundColor: _parseColor(profile.avatarColor), 
                                        backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                                        child: profile.avatarUrl == null 
                                          ? Text(profile.avatarLetra, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900))
                                          : null,
                                      ),
                                      Positioned(
                                        bottom: 0, right: 0, 
                                        child: GestureDetector(
                                          onTap: controller.uploadingAvatar ? null : () => controller.pickAndUploadAvatar(context, profile.id),
                                          child: Container(
                                            width: 24, height: 24, 
                                            decoration: BoxDecoration(color: AppTheme.green600, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), 
                                            child: controller.uploadingAvatar 
                                              ? const Padding(padding: EdgeInsets.all(4.0), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                              : const Icon(Icons.camera_alt, color: Colors.white, size: 12)
                                          ),
                                        )
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(profile.nombre, style: const TextStyle(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(profile.rol.toUpperCase(), style: const TextStyle(color: AppTheme.green500, fontSize: 12, fontWeight: FontWeight.w700)),
                                      if (profile.rol.toLowerCase() != 'jefe' && profile.rol.toLowerCase() != 'jefa' && profile.rol.toLowerCase() != 'co-admin' && profile.rol.toLowerCase() != 'coadmin')
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 14, color: AppTheme.green500),
                                          onPressed: () async {
                                            final newRole = await showDialog<String>(
                                              context: context,
                                              builder: (dialogCtx) {
                                                return SimpleDialog(
                                                  title: const Text('Cambiar Rol', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                  children: ['Miembro', 'Hijo', 'Hija'].map((r) {
                                                    return SimpleDialogOption(
                                                      onPressed: () => Navigator.pop(dialogCtx, r.toLowerCase()),
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                        child: Text(r, style: const TextStyle(fontSize: 16)),
                                                      ),
                                                    );
                                                  }).toList(),
                                                );
                                              }
                                            );
                                            if (newRole != null && context.mounted) {
                                              try {
                                                await Supabase.instance.client.from('profiles').update({'rol': newRole}).eq('id', profile.id);
                                                if (!context.mounted) return;
                                                await context.read<AuthProvider>().refreshProfile();
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rol actualizado'), backgroundColor: AppTheme.green600));
                                              } catch (e) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                                              }
                                            }
                                          },
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (profile.rol.toLowerCase() == 'jefe' || profile.rol.toLowerCase() == 'jefa') ...[
                              Container(width: 1, height: 100, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 8)),
                              Expanded(
                                flex: 1,
                                child: _buildFamilyGrid(context, controller, family.members.where((m) => m.id != profile.id).toList()),
                              ),
                            ]
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        if (family.familyCode.isNotEmpty && (profile.rol.toLowerCase() == 'jefe' || profile.rol.toLowerCase() == 'jefa'))
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(color: AppTheme.green50, borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.qr_code_scanner, color: AppTheme.green600),
                                    const SizedBox(width: 8),
                                    const Text('Código de Familia', style: TextStyle(color: AppTheme.green700, fontWeight: FontWeight.w800, fontSize: 16)),
                                    if (controller.showQr && controller.qrToken != null) ...[
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => controller.loadActiveQrToken(profile.familyId ?? '', forceNew: true),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.green600,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.refresh, color: Colors.white, size: 12),
                                              SizedBox(width: 4),
                                              Text('Pedir otro', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (!controller.showQr)
                                  ElevatedButton.icon(
                                    onPressed: () => controller.generateQr(profile.familyId ?? ''),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green600, foregroundColor: Colors.white),
                                    icon: const Icon(Icons.visibility),
                                    label: const Text('Generar/Mostrar Código'),
                                  )
                                else if (controller.qrToken != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                    child: QrImageView(
                                      data: jsonEncode({'token': controller.qrToken, 'family_id': profile.familyId ?? ''}),
                                      version: QrVersions.auto,
                                      size: 150.0,
                                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.green700),
                                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.green700),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(controller.qrToken!, style: const TextStyle(color: AppTheme.textDark, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
                                  const SizedBox(height: 4),
                                  Text('Expira en ${controller.fmtQrTime}', style: const TextStyle(color: AppTheme.amber400, fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  const Text('Muestra este QR para añadir miembros a tu familia', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
                                ] else
                                  const CircularProgressIndicator(color: AppTheme.green700),
                              ],
                            ),
                          ),

                        if (family.familyCode.isNotEmpty && (profile.rol.toLowerCase() == 'jefe' || profile.rol.toLowerCase() == 'jefa'))
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(color: AppTheme.blue700.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.family_restroom, color: AppTheme.blue700),
                                    const SizedBox(width: 8),
                                    const Text('Identidad de Familia', style: TextStyle(color: AppTheme.blue700, fontWeight: FontWeight.w800, fontSize: 16)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => _editFamilyDialog(context, controller, family.familyName, profile.familyId ?? ''),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.blue700, foregroundColor: Colors.white),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Cambiar Nombre y Foto'),
                                )
                              ],
                            ),
                          ),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppTheme.green50, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    const Text('🏆', style: TextStyle(fontSize: 18)),
                                    const SizedBox(width: 6),
                                    Text('Nivel ${profile.nivel}', style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800)),
                                  ]),
                                  Text('${profile.xp} / ${profile.nivel * 500} XP', style: const TextStyle(color: AppTheme.green600, fontWeight: FontWeight.w900)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: profile.xp / (profile.nivel * 500), backgroundColor: AppTheme.green100, valueColor: const AlwaysStoppedAnimation(AppTheme.green600), minHeight: 8)),
                              const SizedBox(height: 4),
                              Text('${(profile.nivel * 500) - profile.xp} XP para nivel ${profile.nivel + 1}', style: const TextStyle(color: AppTheme.textLight, fontSize: 11)),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        const Align(alignment: Alignment.centerLeft, child: Text('Mis Badges', style: TextStyle(color: AppTheme.textDark, fontSize: 15, fontWeight: FontWeight.w800))),
                        const SizedBox(height: 8),
                        achievementProv.achievements.any((a) => a.desbloqueado)
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: achievementProv.achievements
                                    .where((a) => a.desbloqueado)
                                    .map((a) => Tooltip(
                                          message: '${a.nombre}: ${a.desc}',
                                          child: Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: AppTheme.green50,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: AppTheme.green200, width: 1.5),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.05),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                a.emoji,
                                                style: const TextStyle(fontSize: 24),
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            )
                          : const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: Text('Aún no tienes badges.', style: TextStyle(color: AppTheme.textLight))),
                            ),
                        
                        const SizedBox(height: 20),
                        _buildAchievementsSection(achievementProv),
                        
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () {
                              context.read<AuthProvider>().setOnboardingActive(false);
                              context.read<FamilyProvider>().clear();
                              context.read<EvidenceProvider>().clear();
                              context.read<TaskProvider>().clear();
                              context.read<BillProvider>().clear();
                              context.read<NotificationProvider>().clear();
                              Navigator.of(context).popUntil((route) => route.isFirst);
                              context.read<AuthProvider>().signOut();
                            },
                            icon: const Icon(Icons.logout, color: Colors.redAccent),
                            label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$min';
    } catch (_) {
      return '';
    }
  }

  Widget _buildAchievementsSection(AchievementProvider achievementProv) {
    final list = achievementProv.achievements;
    final total = list.length;
    final unlockedCount = list.where((item) => item.desbloqueado).length;
    final pct = total > 0 ? (unlockedCount / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Logros Ecológicos',
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.green700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unlockedCount / $total (${(pct * 100).round()}%)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (total > 0) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation(AppTheme.green600),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (achievementProv.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: AppTheme.green700),
            ),
          )
        else if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
               'No hay logros disponibles.',
               style: TextStyle(color: AppTheme.textLight),
             ),
           ),
         )
       else
         ...list.map((item) => _logro(item)),
      ],
    );
  }

  Widget _logro(AchievementItem item) {
    final unlocked = item.desbloqueado;
    
    Color cardBg;
    Color borderCol;
    if (unlocked) {
      if (item.dificultad == 'difícil') {
        cardBg = const Color(0xFFFFFDF0);
        borderCol = AppTheme.amber400.withValues(alpha: 0.5);
      } else if (item.dificultad == 'medio') {
        cardBg = const Color(0xFFF3F9F6);
        borderCol = AppTheme.green200;
      } else {
        cardBg = Colors.grey.shade50;
        borderCol = Colors.grey.shade200;
      }
    } else {
      cardBg = Colors.grey.shade50.withValues(alpha: 0.5);
      borderCol = Colors.grey.shade100;
    }

    Color diffColor;
    Color diffBg;
    if (item.dificultad == 'difícil') {
      diffColor = const Color(0xFFD97706);
      diffBg = const Color(0x1FDD6B20);
    } else if (item.dificultad == 'medio') {
      diffColor = AppTheme.blue700;
      diffBg = AppTheme.blue700.withValues(alpha: 0.1);
    } else {
      diffColor = AppTheme.green600;
      diffBg = AppTheme.green100;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: unlocked ? 1.5 : 1),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: unlocked ? Colors.white : Colors.grey.shade200,
              shape: BoxShape.circle,
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Text(
              item.emoji,
              style: TextStyle(
                fontSize: 26,
                color: unlocked ? null : Colors.grey.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 14),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.nombre,
                        style: TextStyle(
                          color: unlocked ? AppTheme.textDark : Colors.grey.shade600,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: diffBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.dificultad.toUpperCase(),
                        style: TextStyle(
                          color: diffColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.desc,
                  style: TextStyle(
                    color: unlocked ? AppTheme.textLight : Colors.grey.shade400,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: unlocked ? AppTheme.green50 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${item.xp} XP',
                            style: TextStyle(
                              color: unlocked ? AppTheme.green700 : Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: unlocked ? const Color(0xFFFFF9C4) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+${item.monedas}',
                                style: TextStyle(
                                  color: unlocked ? const Color(0xFFF57F17) : Colors.grey.shade500,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '🪙',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: unlocked ? null : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    if (unlocked && item.desbloqueadoEn != null)
                      Expanded(
                        child: Text(
                          'Desbloqueado el ${_formatDate(item.desbloqueadoEn)}',
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else if (!unlocked)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            'BLOQUEADO',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyGrid(BuildContext context, ProfileController controller, List<FamilyMember> members) {
    if (members.isEmpty) {
      return const Center(child: Text('Solo tú', style: TextStyle(color: Colors.grey, fontSize: 12)));
    }
    
    final displayMembers = members.take(4).toList();
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: displayMembers.map((m) => GestureDetector(
        onTap: () => _editMemberDialog(context, controller, m),
        child: SizedBox(
          width: 44,
          child: Column(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: _parseColor(m.color), shape: BoxShape.circle),
                child: Center(child: Text(m.avatar, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(height: 4),
              Text(m.nombre.split(' ')[0], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Future<void> _editMemberDialog(BuildContext context, ProfileController controller, FamilyMember member) async {
    final nameCtrl = TextEditingController(text: member.nombre);
    String selectedRole = member.rol.toLowerCase();
    if (!['miembro', 'hijo', 'hija', 'co-admin'].contains(selectedRole)) {
      selectedRole = 'miembro';
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Editar Miembro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    items: const [
                      DropdownMenuItem(value: 'miembro', child: Text('Miembro')),
                      DropdownMenuItem(value: 'hijo', child: Text('Hijo')),
                      DropdownMenuItem(value: 'hija', child: Text('Hija')),
                      DropdownMenuItem(value: 'co-admin', child: Text('Co-Admin')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedRole = val);
                    },
                    decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green600, foregroundColor: Colors.white),
                      onPressed: () async {
                        await controller.updateMemberRole(context, member.id, nameCtrl.text, selectedRole);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Guardar'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }
          ),
        );
      }
    );
  }

  Future<void> _editFamilyDialog(BuildContext context, ProfileController controller, String currentName, String familyId) async {
    final nameCtrl = TextEditingController(text: currentName);
    bool uploading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Identidad de Familia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre de la familia', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.blue700.withValues(alpha: 0.1), foregroundColor: AppTheme.blue700),
                      onPressed: uploading ? null : () async {
                        await controller.updateFamilyPhoto(context, familyId, (val) {
                          if (ctx.mounted) setModalState(() => uploading = val);
                        });
                      },
                      icon: uploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.photo_camera),
                      label: const Text('Subir/Cambiar Foto'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.blue700, foregroundColor: Colors.white),
                      onPressed: () async {
                        await controller.updateFamilyName(context, familyId, nameCtrl.text);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Guardar Nombre'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }
          ),
        );
      }
    );
  }
}
