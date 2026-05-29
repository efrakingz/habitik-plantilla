import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/bill_provider.dart';
import 'scan_controller.dart';

class ScanScreen extends StatelessWidget {
  final int tab;
  final int state;
  final void Function(int) onTabChange;
  final void Function(int) onStateChange;

  const ScanScreen({
    super.key,
    required this.tab,
    required this.state,
    required this.onTabChange,
    required this.onStateChange,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScanController(),
      child: _ScanScreenContent(
        tab: tab,
        state: state,
        onTabChange: onTabChange,
        onStateChange: onStateChange,
      ),
    );
  }
}

class _ScanScreenContent extends StatelessWidget {
  final int tab;
  final int state;
  final void Function(int) onTabChange;
  final void Function(int) onStateChange;

  const _ScanScreenContent({
    required this.tab,
    required this.state,
    required this.onTabChange,
    required this.onStateChange,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ScanController>();
    final isLuz = tab == 0;
    final empresa = controller.empresaCtrl.text.isNotEmpty 
        ? controller.empresaCtrl.text 
        : (isLuz ? 'Enel' : 'Esval');
    final cuenta = controller.cuentaCtrl.text;
    final billProvider = context.watch<BillProvider>();
    final bills = billProvider.bills.where((b) => b.tipo == (isLuz ? 'luz' : 'agua')).toList();
    final change = billProvider.consumoChangePercent(isLuz ? 'luz' : 'agua');
    final xp = billProvider.xpForBill(isLuz ? 'luz' : 'agua');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Registro', style: TextStyle(color: AppTheme.green200, fontSize: 12)),
              const Text('Auditoría de Boletas', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: AppTheme.green50, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        _tabButton(context, controller, 0, Icons.bolt, 'Luz', AppTheme.amber400),
                        _tabButton(context, controller, 1, Icons.water_drop, 'Agua', AppTheme.blue700),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (state == 0) ...[
                    Container(
                      height: 150,
                      decoration: BoxDecoration(border: Border.all(color: AppTheme.green300, style: BorderStyle.solid), borderRadius: BorderRadius.circular(14), color: AppTheme.green50),
                      child: Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(isLuz ? Icons.bolt : Icons.water_drop, color: isLuz ? AppTheme.amber400 : AppTheme.blue700, size: 40),
                          const SizedBox(height: 6),
                          const Text('Encuadra tu boleta', style: TextStyle(color: AppTheme.green600, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _cameraButton(context, controller)),
                        const SizedBox(width: 8),
                        Expanded(child: _pdfButton(context, controller)),
                      ],
                    ),
                    if (bills.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Icon(Icons.history, color: AppTheme.green600, size: 16),
                          SizedBox(width: 6),
                          Text('Historial de Boletas', style: TextStyle(color: AppTheme.textDark, fontSize: 14, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...bills.take(4).map((b) => _billHistoryCard(context, b, isLuz)),
                    ],
                  ],

                  if (state == 1)
                    const SizedBox(
                      height: 200,
                      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        SizedBox(width: 48, height: 48, child: CircularProgressIndicator(color: AppTheme.green700)),
                        SizedBox(height: 12),
                        Text('Procesando...', style: TextStyle(color: AppTheme.green700, fontWeight: FontWeight.w700)),
                        Text('Extrayendo datos de la boleta', style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
                      ])),
                    ),

                  if (state == 2) ...[
                    Row(children: [
                      const Icon(Icons.check_circle, color: AppTheme.green600, size: 20),
                      const SizedBox(width: 6),
                      Text('Datos extraídos — $empresa', style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 14)),
                    ]),
                    if (!controller.editando)
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.shade200)),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('💡', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('¿Detectaste algún error?', style: TextStyle(color: Color(0xFF1565C0), fontSize: 12, fontWeight: FontWeight.w700)),
                                  Text('Puedes corregir manualmente los datos antes de confirmar.', style: TextStyle(color: Color(0xFF1E88E5), fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppTheme.amber400.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.amber400.withValues(alpha: 0.3))),
                        child: const Row(
                          children: [
                            Text('✏️', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 8),
                            Expanded(child: Text('Modo edición activo - Corrige los valores y guarda los cambios', style: TextStyle(color: AppTheme.amber400, fontSize: 12, fontWeight: FontWeight.w700))),
                          ],
                        ),
                      ),
                    if (controller.editando) ...[
                      _editField(context, controller, 'Empresa', controller.empresaCtrl),
                      _editField(context, controller, 'Cuenta', controller.cuentaCtrl),
                      _editField(context, controller, 'Período', controller.periodoCtrl),
                      _editField(context, controller, 'Consumo (${isLuz ? 'kWh' : 'm³'})', controller.consumoCtrl),
                      _editField(context, controller, r'Monto ($)', controller.montoCtrl),
                    ] else ...[
                      _dataRow('Empresa', empresa),
                      _dataRow('Cuenta', cuenta.isEmpty ? 'No detectada' : cuenta),
                      _dataRow('Período', controller.periodoCtrl.text.isEmpty ? 'No detectado' : controller.periodoCtrl.text),
                      _dataRow('Consumo', controller.formatConsumo(controller.consumoCtrl.text, isLuz)),
                      _dataRow('Monto', controller.formatMontoCL(controller.montoCtrl.text)),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.green50, borderRadius: BorderRadius.circular(10)),
                          child: Column(children: [
                            Icon(
                              change != null && change < 0 ? Icons.trending_down : Icons.trending_up,
                              color: change != null && change < 0 ? AppTheme.green600 : Colors.redAccent,
                            ),
                            Text(
                              change != null ? '${change < 0 ? '' : '+'}${change.toStringAsFixed(0)}%' : '--',
                              style: TextStyle(
                                color: change != null && change < 0 ? AppTheme.green600 : Colors.redAccent,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text('vs anterior', style: TextStyle(fontSize: 10)),
                          ]),
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.amber400.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Column(children: [
                            const Icon(Icons.emoji_events, color: AppTheme.amber400),
                            Text('+$xp XP', style: const TextStyle(color: AppTheme.amber400, fontWeight: FontWeight.w900)),
                            const Text('Por registrar', style: TextStyle(fontSize: 10)),
                          ]),
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    controller.editando
                        ? Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => controller.setEditando(false),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.grey.shade700),
                                  child: const Text('Cancelar Edición', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    controller.montoCtrl.text = controller.formatMontoCL(controller.montoCtrl.text);
                                    controller.setEditando(false);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green600, foregroundColor: Colors.white),
                                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Icon(Icons.check, size: 16),
                                    SizedBox(width: 4),
                                    Text('Guardar', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ]),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        controller.discard();
                                        onStateChange(0);
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red),
                                      child: const Text('Descartar PDF', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => controller.setEditando(true),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.amber400.withValues(alpha: 0.2), foregroundColor: AppTheme.amber400),
                                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Icon(Icons.settings, size: 16),
                                        SizedBox(width: 4),
                                        Text('Corregir', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                      ]),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: controller.saving ? null : () => controller.confirmarBoleta(context, tab, onStateChange),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green700, foregroundColor: Colors.white),
                                  child: controller.saving
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                          Icon(Icons.check, size: 16),
                                          SizedBox(width: 4),
                                          Text('Confirmar Boleta', style: TextStyle(fontWeight: FontWeight.w700)),
                                        ]),
                                ),
                              ),
                            ],
                          ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabButton(BuildContext context, ScanController controller, int value, IconData icon, String label, Color color) {
    final selected = tab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (tab != value) {
            onStateChange(0);
            controller.discard();
            onTabChange(value);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: selected ? AppTheme.green700 : AppTheme.textLight, size: 18),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: selected ? AppTheme.textDark : AppTheme.textLight, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
      ),
    );
  }

  Widget _cameraButton(BuildContext context, ScanController controller) {
    return GestureDetector(
      onTap: () => controller.handleCameraAction(context, tab, onStateChange),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppTheme.green700, borderRadius: BorderRadius.circular(12)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text('Cámara', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _pdfButton(BuildContext context, ScanController controller) {
    return GestureDetector(
      onTap: () => controller.handlePdfAction(context, tab, onStateChange),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppTheme.green200, borderRadius: BorderRadius.circular(12)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, color: AppTheme.green700, size: 20),
            SizedBox(width: 6),
            Text('Subir PDF', style: TextStyle(color: AppTheme.green700, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 12)),
        Text(value, style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    );
  }

  Widget _editField(BuildContext context, ScanController controller, String label, TextEditingController ctrl) {
    final isPeriodo = label.toLowerCase() == 'período';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 12))),
          SizedBox(
            width: 195,
            child: TextField(
              controller: ctrl,
              textAlign: TextAlign.center,
              readOnly: isPeriodo,
              onTap: isPeriodo ? () => controller.selectPeriodo(context) : null,
              style: TextStyle(fontSize: isPeriodo ? 11 : 12, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _billHistoryCard(BuildContext context, BillData b, bool isLuz) {
    return GestureDetector(
      onLongPress: () {
        if (b.id.isNotEmpty) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Eliminar Boleta'),
              content: const Text('¿Estás seguro de que quieres eliminar esta boleta del historial?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final billProvider = context.read<BillProvider>();
                    final ok = await billProvider.deleteBill(b.id);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Boleta eliminada')));
                    }
                  },
                  child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.green50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.green100),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: isLuz ? AppTheme.amber400.withValues(alpha: 0.15) : AppTheme.blue700.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Icon(isLuz ? Icons.bolt : Icons.water_drop, color: isLuz ? AppTheme.amber400 : AppTheme.blue700, size: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.periodo.isEmpty ? 'Sin período' : b.periodo, style: const TextStyle(color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.w700)),
                  Text(context.read<ScanController>().formatConsumo(b.consumo, isLuz), style: const TextStyle(color: AppTheme.textLight, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppTheme.green100, borderRadius: BorderRadius.circular(8)),
              child: Text(context.read<ScanController>().formatMontoCL(b.monto), style: const TextStyle(color: AppTheme.green700, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
