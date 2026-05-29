import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import 'rewards_controller.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final controller = RewardsController();
        WidgetsBinding.instance.addPostFrameCallback((_) => controller.init(context));
        return controller;
      },
      child: const _RewardsScreenContent(),
    );
  }
}

class _RewardsScreenContent extends StatelessWidget {
  const _RewardsScreenContent();

  void _mostrarDialogoNuevoPremio(BuildContext context, RewardsController controller) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    String selectedEmoji = '🎁';
    const List<String> emojis = ['🎁', '🍕', '🎮', '🍿', '🎬', '🛌', '🍦', '🍔', '🚲', '🎉', '⭐', '🏖️', '🎵', '🧁', '🐾'];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
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
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || costCtrl.text.trim().isEmpty) return;
                await controller.createReward(
                  context, 
                  titleCtrl.text.trim(), 
                  descCtrl.text.trim(), 
                  int.tryParse(costCtrl.text.trim()) ?? 0, 
                  selectedEmoji
                );
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Crear Canje', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoEditarPremio(BuildContext context, RewardsController controller, RewardItem r) {
    final titleCtrl = TextEditingController(text: r.titulo);
    final descCtrl = TextEditingController(text: r.descripcion);
    final costCtrl = TextEditingController(text: r.costo.toString());
    String selectedEmoji = r.emoji;
    const List<String> emojis = ['🎁', '🍕', '🎮', '🍿', '🎬', '🛌', '🍦', '🍔', '🚲', '🎉', '⭐', '🏖️', '🎵', '🧁', '🐾'];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
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
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || costCtrl.text.trim().isEmpty) return;
                await controller.updateReward(
                  context,
                  r,
                  titleCtrl.text.trim(),
                  descCtrl.text.trim(),
                  int.tryParse(costCtrl.text.trim()) ?? r.costo,
                  selectedEmoji
                );
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Guardar Cambios', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final controller = context.watch<RewardsController>();
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
                  onPressed: () => _mostrarDialogoNuevoPremio(context, controller),
                  icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: controller.loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.green500))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
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

                      if (controller.rewards.isEmpty)
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
                          children: controller.rewards.map((r) {
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
                                          await controller.deleteReward(r.id);
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
                                            onTap: () => _mostrarDialogoEditarPremio(context, controller, r),
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
                                          onPressed: puede ? () => controller.canjear(context, r.id) : null,
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

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Historial Personal', style: TextStyle(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(height: 12),
                      if (controller.historialCanjes.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                          child: const Center(child: Text('No has canjeado premios aún.', style: TextStyle(color: AppTheme.textLight, fontSize: 13))),
                        )
                      else
                        ...controller.historialCanjes.map((h) {
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
