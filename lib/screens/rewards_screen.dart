import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../services/reward_service.dart';

import '../providers/family_provider.dart';
import '../providers/achievement_provider.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final RewardService _rewardService = RewardService();

  List<RewardItem> _rewards = [];
  List<Map<String, dynamic>> _historialCanjes = [];
  StreamSubscription<List<RewardItem>>? _rewardsSub;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _rewardsSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    final familyId = auth.profile?.familyId;
    final userId = auth.user?.id;

    // Load personal historial from SP
    if (userId != null) await _loadHistorial(userId);

    if (familyId == null) {
      setState(() => _loading = false);
      return;
    }

    // Seed defaults on first run (no-op if already seeded)
    try {
      await _rewardService.seedDefaults(familyId);
    } catch (e) {
      debugPrint('RewardsScreen: seed error $e');
    }

    // Subscribe to realtime stream — updates immediately on any device
    _rewardsSub = _rewardService.streamRewards(familyId).listen(
      (list) {
        if (!mounted) return;
        // Apply daily reset locally (no extra DB call)
        final now = DateTime.now();
        final updated = list.map((r) {
          if (!r.disponible && r.lastRedeemedAt != null) {
            final rd = r.lastRedeemedAt!;
            if (rd.year != now.year || rd.month != now.month || rd.day != now.day) {
              // Update Supabase silently; stream will reflect the change
              _rewardService.markRedeemed(r.id, disponible: true).ignore();
              return RewardItem(id: r.id, titulo: r.titulo, descripcion: r.descripcion,
                emoji: r.emoji, costo: r.costo, disponible: true, creador: r.creador);
            }
          }
          return r;
        }).toList();
        setState(() { _rewards = updated; _loading = false; });
      },
      onError: (e) {
        debugPrint('RewardsScreen: stream error $e');
        setState(() => _loading = false);
      },
    );
  }

  Future<void> _loadHistorial(String userId) async {
    try {
      final dbHistory = await _rewardService.getRedemptionHistory(userId);
      if (mounted) {
        setState(() {
          _historialCanjes = dbHistory;
        });
      }
      // Save local cache for offline backup
      final prefs = await SharedPreferences.getInstance();
      final serializable = dbHistory.map((e) => {
        ...e,
        'fecha': (e['fecha'] as DateTime).toIso8601String(),
      }).toList();
      await prefs.setString('canje_historial_$userId', jsonEncode(serializable));
    } catch (e) {
      debugPrint('RewardsScreen: error loading history from Supabase: $e');
      // Offline fallback
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('canje_historial_$userId');
      if (raw != null && mounted) {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        setState(() {
          _historialCanjes = list.map((e) => {
            ...e,
            'fecha': DateTime.tryParse(e['fecha'] as String? ?? '') ?? DateTime.now(),
          }).toList();
        });
      }
    }
  }

  // ── Canjear ───────────────────────────────────────────────────────────────

  void _canjear(int id) async {
    final r = _rewards.firstWhere((r) => r.id == id);
    final auth = context.read<AuthProvider>();
    final monedas = auth.profile?.monedas ?? 0;
    if (!r.disponible || monedas < r.costo || auth.profile == null) return;
    final userId = auth.user?.id;

    // Optimistic UI
    setState(() {
      final idx = _rewards.indexWhere((x) => x.id == id);
      if (idx != -1) {
        _rewards[idx] = RewardItem(
          id: r.id, titulo: r.titulo, descripcion: r.descripcion,
          emoji: r.emoji, costo: r.costo, disponible: false,
          creador: r.creador, lastRedeemedAt: DateTime.now(),
        );
      }
    });

    try {
      await auth.deductCoins(r.costo);
      // Persist redeemed state to Supabase so all devices see it
      await _rewardService.markRedeemed(id, disponible: false);
      if (userId != null && auth.profile?.familyId != null) {
        await _rewardService.createRedemption(userId, auth.profile!.familyId!, r.titulo, r.costo);
      }
    } catch (e) {
      // Rollback
      if (mounted) {
        setState(() {
          final idx = _rewards.indexWhere((x) => x.id == id);
          if (idx != -1) {
            _rewards[idx] = RewardItem(
              id: r.id, titulo: r.titulo, descripcion: r.descripcion,
              emoji: r.emoji, costo: r.costo, disponible: true,
              creador: r.creador,
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
      return;
    }

    if (mounted) {
      setState(() {
        _historialCanjes.insert(0, {'titulo': r.titulo, 'costo': r.costo, 'fecha': DateTime.now()});
      });
      if (userId != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final serializable = _historialCanjes.map((e) => {
            ...e,
            'fecha': (e['fecha'] as DateTime).toIso8601String(),
          }).toList();
          await prefs.setString('canje_historial_$userId', jsonEncode(serializable));
        } catch (_) {}
      }
      if (!mounted) return;

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

      // Trigger primer_canje achievement
      achievementProvider.checkAndUnlock(
        auth.profile!.id,
        'primer_canje',
        authProvider: auth,
      ).ignore();

      if (!mounted) return;
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
  }

  // ── Crear nuevo canje ─────────────────────────────────────────────────────

  void _mostrarDialogoNuevoPremio() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    String selectedEmoji = '🎁';
    const List<String> emojis = ['🎁', '🍕', '🎮', '🍿', '🎬', '🛌', '🍦', '🍔', '🚲', '🎉', '⭐', '🏖️', '🎵', '🧁', '🐾'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nuevo Canje', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(color: AppTheme.amber400.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                    child: Center(child: Text(selectedEmoji, style: const TextStyle(fontSize: 32))),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Emoticón', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: emojis.map((e) => GestureDetector(
                    onTap: () => setModalState(() => selectedEmoji = e),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedEmoji == e ? AppTheme.amber400.withValues(alpha: 0.2) : Colors.transparent,
                        border: Border.all(color: selectedEmoji == e ? AppTheme.amber400 : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 20)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Nombre del Canje', isDense: true)),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción', isDense: true)),
                const SizedBox(height: 8),
                TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Costo (Monedas)', isDense: true, prefixText: '🪙 ')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || costCtrl.text.trim().isEmpty) return;
                final auth = context.read<AuthProvider>();
                final familyId = auth.profile?.familyId;
                if (familyId == null) return;
                final newItem = RewardItem(
                  id: DateTime.now().millisecondsSinceEpoch,
                  emoji: selectedEmoji,
                  titulo: titleCtrl.text.trim(),
                  descripcion: descCtrl.text.trim(),
                  costo: int.tryParse(costCtrl.text.trim()) ?? 0,
                  disponible: true,
                  creador: auth.profile?.nombre ?? 'Jefe',
                );
                Navigator.pop(context);
                // Upsert to Supabase — stream will reflect immediately on all devices
                await _rewardService.upsertReward(newItem, familyId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Crear Canje', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Editar canje existente ────────────────────────────────────────────────

  void _mostrarDialogoEditarPremio(RewardItem r) {
    final titleCtrl = TextEditingController(text: r.titulo);
    final descCtrl = TextEditingController(text: r.descripcion);
    final costCtrl = TextEditingController(text: r.costo.toString());
    String selectedEmoji = r.emoji;
    const List<String> emojis = ['🎁', '🍕', '🎮', '🍿', '🎬', '🛌', '🍦', '🍔', '🚲', '🎉', '⭐', '🏖️', '🎵', '🧁', '🐾'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar Canje', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(color: AppTheme.amber400.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                    child: Center(child: Text(selectedEmoji, style: const TextStyle(fontSize: 32))),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Emoticón', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: emojis.map((e) => GestureDetector(
                    onTap: () => setModalState(() => selectedEmoji = e),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedEmoji == e ? AppTheme.amber400.withValues(alpha: 0.2) : Colors.transparent,
                        border: Border.all(color: selectedEmoji == e ? AppTheme.amber400 : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 20)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Nombre del Canje', isDense: true)),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción', isDense: true)),
                const SizedBox(height: 8),
                TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Costo (Monedas)', isDense: true, prefixText: '🪙 ')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || costCtrl.text.trim().isEmpty) return;
                final auth = context.read<AuthProvider>();
                final familyId = auth.profile?.familyId;
                if (familyId == null) return;
                final updated = RewardItem(
                  id: r.id,
                  emoji: selectedEmoji,
                  titulo: titleCtrl.text.trim(),
                  descripcion: descCtrl.text.trim(),
                  costo: int.tryParse(costCtrl.text.trim()) ?? r.costo,
                  disponible: r.disponible,
                  creador: r.creador,
                  lastRedeemedAt: r.lastRedeemedAt,
                );
                Navigator.pop(context);
                // Upsert to Supabase — stream propagates change to all devices instantly
                await _rewardService.upsertReward(updated, familyId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Guardar Cambios', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final monedas = profile?.monedas ?? 0;
    final nivel = profile?.nivel ?? 1;
    final xp = profile?.xp ?? 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gamificación', style: TextStyle(color: AppTheme.green200, fontSize: 12)),
                  Text('Canjes', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
              if (profile?.rol == 'jefe')
                IconButton(
                  onPressed: () => _mostrarDialogoNuevoPremio(),
                  icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.green500))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // ── Stats cards ────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [AppTheme.green400, AppTheme.green600]),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Nivel actual', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  Text('Nv. $nivel', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                                  Text('$xp XP 🌟', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [AppTheme.amber400, Color(0xFFFF9800)]),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Saldo disponible', style: TextStyle(color: Color(0xFF5D4037), fontSize: 12)),
                                  Text('$monedas 🪙', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                                  const Text('Monedas', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Rewards grid ───────────────────────────────────
                      if (_rewards.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              profile?.rol == 'jefe'
                                ? 'Toca + para crear el primer canje'
                                : 'El jefe aún no ha creado canjes',
                              style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 10, runSpacing: 10,
                          children: _rewards.map((r) {
                            final puede = r.disponible && monedas >= r.costo;
                            final isJefe = profile?.rol == 'jefe';
                            return GestureDetector(
                              onLongPress: isJefe ? () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: const Text('Eliminar Canje', style: TextStyle(fontWeight: FontWeight.w800)),
                                    content: Text('¿Eliminar "${r.titulo}" de la lista de canjes?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          await _rewardService.deleteReward(r.id);
                                          // Stream will remove it from UI automatically
                                        },
                                        child: const Text('Eliminar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                );
                              } : null,
                              child: Container(
                                width: (MediaQuery.of(context).size.width - 60) / 2,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: r.disponible ? Colors.white : Colors.grey.shade50,
                                  border: Border.all(color: r.disponible ? AppTheme.amber400.withValues(alpha: 0.3) : Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 48, height: 48,
                                          decoration: BoxDecoration(
                                            color: r.disponible ? AppTheme.amber400.withValues(alpha: 0.12) : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(child: Text(r.emoji, style: TextStyle(fontSize: 24, color: r.disponible ? null : Colors.grey))),
                                        ),
                                        const Spacer(),
                                        if (isJefe)
                                          GestureDetector(
                                            onTap: () => _mostrarDialogoEditarPremio(r),
                                            child: Container(
                                              width: 28, height: 28,
                                              decoration: BoxDecoration(color: AppTheme.green100, borderRadius: BorderRadius.circular(8)),
                                              child: const Icon(Icons.edit, size: 15, color: AppTheme.green700),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(r.titulo, style: TextStyle(color: r.disponible ? AppTheme.textDark : Colors.grey, fontSize: 13, fontWeight: FontWeight.w700)),
                                    Text(r.descripcion, style: TextStyle(color: r.disponible ? AppTheme.textLight : Colors.grey.shade400, fontSize: 11)),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${r.costo} 🪙', style: TextStyle(color: puede ? AppTheme.amber400 : Colors.grey, fontWeight: FontWeight.w900)),
                                        if (!r.disponible) Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                          child: const Text('Canjeado', style: TextStyle(fontSize: 9)),
                                        ),
                                      ],
                                    ),
                                    if (r.disponible) ...[
                                      const SizedBox(height: 6),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: puede ? () => _canjear(r.id) : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: puede ? AppTheme.amber400 : Colors.grey.shade100,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          child: Text(puede ? 'Canjear' : 'Insuficiente', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: puede ? Colors.white : Colors.grey)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 24),

                      // ── Historial personal ─────────────────────────────
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Historial Personal', style: TextStyle(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(height: 12),
                      if (_historialCanjes.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                          child: const Center(child: Text('No has canjeado premios aún.', style: TextStyle(color: AppTheme.textLight, fontSize: 13))),
                        )
                      else
                        ..._historialCanjes.map((h) {
                          final fecha = h['fecha'] as DateTime;
                          final min = fecha.minute.toString().padLeft(2, '0');
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(h['titulo'], style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                                    Text('Hoy a las ${fecha.hour}:$min', style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                                  ],
                                ),
                                Text('-${h['costo']} 🪙', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
          ),
        ),
      ],
    );
  }
}
