import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/models.dart';
import '../../../models/notification_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/family_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/achievement_provider.dart';
import '../../../services/reward_service.dart';
import '../../../config/theme.dart';

class RewardsController extends ChangeNotifier {
  final RewardService _rewardService = RewardService();

  List<RewardItem> rewards = [];
  List<Map<String, dynamic>> historialCanjes = [];
  StreamSubscription<List<RewardItem>>? _rewardsSub;
  bool loading = true;

  @override
  void dispose() {
    _rewardsSub?.cancel();
    super.dispose();
  }

  Future<void> init(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final familyId = auth.profile?.familyId;
    final userId = auth.user?.id;

    if (userId != null) await _loadHistorial(userId);

    if (familyId == null) {
      loading = false;
      notifyListeners();
      return;
    }

    try {
      await _rewardService.seedDefaults(familyId);
    } catch (e) {
      debugPrint('RewardsController: seed error $e');
    }

    _rewardsSub = _rewardService.streamRewards(familyId).listen(
      (list) {
        final now = DateTime.now();
        final updated = list.map((r) {
          if (!r.disponible && r.lastRedeemedAt != null) {
            final rd = r.lastRedeemedAt!;
            if (rd.year != now.year || rd.month != now.month || rd.day != now.day) {
              _rewardService.markRedeemed(r.id, disponible: true).ignore();
              return RewardItem(id: r.id, titulo: r.titulo, descripcion: r.descripcion,
                emoji: r.emoji, costo: r.costo, disponible: true, creador: r.creador);
            }
          }
          return r;
        }).toList();
        
        rewards = updated;
        loading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('RewardsController: stream error $e');
        loading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _loadHistorial(String userId) async {
    try {
      final dbHistory = await _rewardService.getRedemptionHistory(userId);
      historialCanjes = dbHistory;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final serializable = dbHistory.map((e) => {
        ...e,
        'fecha': (e['fecha'] as DateTime).toIso8601String(),
      }).toList();
      await prefs.setString('canje_historial_$userId', jsonEncode(serializable));
    } catch (e) {
      debugPrint('RewardsController: error loading history from Supabase: $e');
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('canje_historial_$userId');
      if (raw != null) {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        historialCanjes = list.map((e) => {
          ...e,
          'fecha': DateTime.tryParse(e['fecha'] as String? ?? '') ?? DateTime.now(),
        }).toList();
        notifyListeners();
      }
    }
  }

  Future<void> canjear(BuildContext context, int id) async {
    final r = rewards.firstWhere((r) => r.id == id);
    final auth = context.read<AuthProvider>();
    final monedas = auth.profile?.monedas ?? 0;
    if (!r.disponible || monedas < r.costo || auth.profile == null) return;
    final userId = auth.user?.id;

    // Optimistic UI
    final idx = rewards.indexWhere((x) => x.id == id);
    if (idx != -1) {
      rewards[idx] = RewardItem(
        id: r.id, titulo: r.titulo, descripcion: r.descripcion,
        emoji: r.emoji, costo: r.costo, disponible: false,
        creador: r.creador, lastRedeemedAt: DateTime.now(),
      );
      notifyListeners();
    }

    try {
      await auth.deductCoins(r.costo);
      await _rewardService.markRedeemed(id, disponible: false);
      if (userId != null && auth.profile?.familyId != null) {
        await _rewardService.createRedemption(userId, auth.profile!.familyId!, r.titulo, r.costo);
      }
    } catch (e) {
      if (idx != -1) {
        rewards[idx] = RewardItem(
          id: r.id, titulo: r.titulo, descripcion: r.descripcion,
          emoji: r.emoji, costo: r.costo, disponible: true,
          creador: r.creador,
        );
        notifyListeners();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
      return;
    }

    historialCanjes.insert(0, {'titulo': r.titulo, 'costo': r.costo, 'fecha': DateTime.now()});
    notifyListeners();

    if (userId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final serializable = historialCanjes.map((e) => {
          ...e,
          'fecha': (e['fecha'] as DateTime).toIso8601String(),
        }).toList();
        await prefs.setString('canje_historial_$userId', jsonEncode(serializable));
      } catch (_) {}
    }

    if (!context.mounted) return;

    final taskProvider = context.read<TaskProvider>();
    final achievementProvider = context.read<AchievementProvider>();
    final familyProvider = context.read<FamilyProvider>();
    final messenger = ScaffoldMessenger.of(context);

    await taskProvider.addValidation(PendingValidation(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: auth.profile!.id,
      usuario: auth.profile!.nombre,
      avatar: auth.profile!.nombre[0],
      color: '#F57C00',
      reto: 'Canje: ${r.titulo}',
      hora: 'Recién',
      xp: 0,
      monedas: r.costo,
      evidencias: const ['Canje'],
      requiereEvidencia: false,
    ), familyId: auth.profile!.familyId);

    achievementProvider.checkAndUnlock(
      auth.profile!.id,
      'primer_canje',
      authProvider: auth,
    ).ignore();

    final familyMembers = familyProvider.members;
    final jefes = familyMembers.where((m) => m.rol.toLowerCase().contains('jefe')).toList();
    for (var jefe in jefes) {
      NotificationProvider.writeNotificationForUser(
        jefe.id,
        NotificationItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_canje',
          title: 'Nueva solicitud de canje',
          desc: '${auth.profile!.nombre.split(' ')[0]} quiere canjear "${r.titulo}"',
          time: DateTime.now().toIso8601String(),
          iconCode: 'card_giftcard',
          colorHex: '#F57C00',
        ),
      );
    }

    messenger.showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.access_time, color: Colors.white),
        SizedBox(width: 10),
        Expanded(child: Text('Canje solicitado. Esperando validación del Jefe de Hogar.',
          style: TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: AppTheme.amber400,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      duration: const Duration(seconds: 4),
    ));
  }

  Future<void> createReward(BuildContext context, String title, String desc, int cost, String emoji) async {
    final auth = context.read<AuthProvider>();
    final familyId = auth.profile?.familyId;
    if (familyId == null) return;

    final newItem = RewardItem(
      id: DateTime.now().millisecondsSinceEpoch,
      emoji: emoji,
      titulo: title,
      descripcion: desc,
      costo: cost,
      disponible: true,
      creador: auth.profile?.nombre ?? 'Jefe',
    );
    
    await _rewardService.upsertReward(newItem, familyId);
  }

  Future<void> updateReward(BuildContext context, RewardItem oldItem, String title, String desc, int cost, String emoji) async {
    final auth = context.read<AuthProvider>();
    final familyId = auth.profile?.familyId;
    if (familyId == null) return;

    final updated = RewardItem(
      id: oldItem.id,
      emoji: emoji,
      titulo: title,
      descripcion: desc,
      costo: cost,
      disponible: oldItem.disponible,
      creador: oldItem.creador,
      lastRedeemedAt: oldItem.lastRedeemedAt,
    );
    
    await _rewardService.upsertReward(updated, familyId);
  }

  Future<void> deleteReward(int id) async {
    await _rewardService.deleteReward(id);
  }
}
