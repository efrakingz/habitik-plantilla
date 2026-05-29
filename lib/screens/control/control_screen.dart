import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/task_provider.dart';
import 'control_controller.dart';

class ControlScreen extends StatelessWidget {
  final int metaLuz;
  final int metaAgua;
  final void Function(int) onMetaLuzChanged;
  final void Function(int) onMetaAguaChanged;

  const ControlScreen({
    super.key,
    required this.metaLuz,
    required this.metaAgua,
    required this.onMetaLuzChanged,
    required this.onMetaAguaChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final controller = ControlController();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.refreshValidations(context);
        });
        return controller;
      },
      child: _ControlScreenContent(
        metaLuz: metaLuz,
        metaAgua: metaAgua,
        onMetaLuzChanged: onMetaLuzChanged,
        onMetaAguaChanged: onMetaAguaChanged,
      ),
    );
  }
}

class _ControlScreenContent extends StatelessWidget {
  final int metaLuz;
  final int metaAgua;
  final void Function(int) onMetaLuzChanged;
  final void Function(int) onMetaAguaChanged;

  const _ControlScreenContent({
    required this.metaLuz,
    required this.metaAgua,
    required this.onMetaLuzChanged,
    required this.onMetaAguaChanged,
  });

  Color _parseColor(String hex) => Color(int.parse(hex.replaceAll('#', '0xFF')));

  @override
  Widget build(BuildContext context) {
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
                  Text('Jefe de Familia', style: TextStyle(color: AppTheme.green200, fontSize: 12)),
                  Text('Panel de Control', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.amber400, borderRadius: BorderRadius.circular(20)),
                child: const Text('Admin', style: TextStyle(color: Color(0xFF5D4037), fontSize: 11, fontWeight: FontWeight.w900)),
              ),
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
                  _sectionTitle(Icons.gps_fixed, 'Seteo de Metas de Ahorro'),
                  const SizedBox(height: 10),
                  _metaSlider('Reducir Luz', metaLuz, AppTheme.amber400, onMetaLuzChanged),
                  const SizedBox(height: 10),
                  _metaSlider('Reducir Agua', metaAgua, AppTheme.blue700, onMetaAguaChanged),
                  const SizedBox(height: 20),
                  _sectionTitle(Icons.check_circle, 'Validación de Retos'),
                  const SizedBox(height: 10),
                  Consumer<TaskProvider>(
                    builder: (context, taskProvider, _) {
                      if (taskProvider.isLoading) {
                        return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppTheme.green500)));
                      }
                      if (taskProvider.pendingValidations.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppTheme.green50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.green200)),
                          child: const Text('No hay retos pendientes', style: TextStyle(color: AppTheme.green600, fontSize: 13), textAlign: TextAlign.center),
                        );
                      }
                      return Column(
                        children: taskProvider.pendingValidations.map((v) => _buildRetoCard(context, v)).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.green600, size: 18),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(color: AppTheme.textDark, fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _metaSlider(String label, int value, Color color, void Function(int) onChange) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withAlpha(13), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withAlpha(51))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w700)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)), child: Text('$value%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
            ],
          ),
          Slider(value: value.toDouble(), min: 5, max: 15, divisions: 10, activeColor: color, onChanged: (v) => onChange(v.round())),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('5%', style: TextStyle(color: Colors.grey, fontSize: 10)),
            Text('15%', style: TextStyle(color: Colors.grey, fontSize: 10)),
          ]),
        ],
      ),
    );
  }

  Widget _buildRetoCard(BuildContext context, PendingValidation t) {
    final controller = context.read<ControlController>();
    final isCanje = t.evidencias.length == 1 && t.evidencias.first == 'Canje';
    final imageList = t.evidencias.where((e) => e.contains('/') || e.contains('\\')).toList();
    final textEvidence = t.evidencias.where((e) => !e.contains('/') && !e.contains('\\')).where((e) => e != 'Canje').join(', ');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCanje ? AppTheme.amber400.withValues(alpha: 0.3) : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(radius: 20, backgroundColor: _parseColor(t.color), child: Text(t.avatar, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.usuario, style: const TextStyle(color: AppTheme.textDark, fontSize: 14, fontWeight: FontWeight.w800)),
                    Text(t.reto, style: TextStyle(color: isCanje ? AppTheme.amber400 : AppTheme.green600, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(t.hora, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isCanje)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.amber400.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                      child: Text('+${t.xp} XP', style: const TextStyle(color: AppTheme.amber400, fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: isCanje ? Colors.red.withAlpha(30) : AppTheme.green100, borderRadius: BorderRadius.circular(10)),
                    child: Text(isCanje ? '-${t.monedas} 🪙' : '+${t.monedas} 🪙', style: TextStyle(color: isCanje ? Colors.redAccent : AppTheme.green700, fontSize: 11, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ],
          ),
          if (t.requiereEvidencia && imageList.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imageList.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) => GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (dlgCtx) => Dialog(
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          imageList[i].startsWith('http') 
                          ? Image.network(
                              imageList[i], 
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Padding(
                                padding: EdgeInsets.all(40),
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Imagen no disponible', style: TextStyle(color: Colors.grey)),
                                ]),
                              ),
                            )
                          : Image.file(
                              File(imageList[i]), 
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Padding(
                                padding: EdgeInsets.all(40),
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Imagen no disponible', style: TextStyle(color: Colors.grey)),
                                ]),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black, size: 30),
                            onPressed: () => Navigator.pop(dlgCtx),
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: imageList[i].startsWith('http')
                        ? Image.network(
                            imageList[i], 
                            width: 110, height: 110, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 110, height: 110,
                              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.broken_image, color: Colors.grey, size: 32),
                            ),
                          )
                        : Image.file(
                            File(imageList[i]), 
                            width: 110, height: 110, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 110, height: 110,
                              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.broken_image, color: Colors.grey, size: 32),
                            ),
                          ),
                      ),
                      Positioned(
                        bottom: 4, right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                          child: Text('${i + 1}/${imageList.length}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (t.requiereEvidencia && textEvidence.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.green50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.green200),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.green600, borderRadius: BorderRadius.circular(6)),
                  child: const Text('📎 EVIDENCIA', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    textEvidence, 
                    style: const TextStyle(color: AppTheme.green700, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.aprobar(context, t.id),
                  icon: const Icon(Icons.check, size: 16, color: Colors.white),
                  label: const Text('Aprobar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRechazoModal(context, t.id, t.userId, t.reto),
                  icon: const Icon(Icons.close, size: 16, color: Colors.white),
                  label: const Text('Rechazar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRechazoModal(BuildContext context, int id, String userId, String reto) {
    final controller = context.read<ControlController>();
    controller.iniciarRechazo(id, userId, reto);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Consumer<ControlController>(
        builder: (ctx, ctrl, _) => Padding(
          padding: const EdgeInsets.all(20).copyWith(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Motivo de Rechazo', style: TextStyle(color: AppTheme.textDark, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Explica por que no cumple:', style: TextStyle(color: AppTheme.green500, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ej: La foto no muestra las luces apagadas...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                onChanged: ctrl.setRechazoMotivo,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (ctrl.rechazoMotivo != null && ctrl.rechazoMotivo!.trim().isNotEmpty) 
                      ? () => ctrl.confirmarRechazo(context) 
                      : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Confirmar Rechazo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
