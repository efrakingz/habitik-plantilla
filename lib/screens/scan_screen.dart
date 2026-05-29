import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import '../config/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/bill_provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../providers/task_provider.dart';
import '../providers/achievement_provider.dart';

const String googleVisionApiKey = String.fromEnvironment(
  'GOOGLE_VISION_API_KEY',
  defaultValue: 'AIzaSyA9eM963NObsOTwwP8qBiSzSAf1Rz9N4AI',
);

class ScanScreen extends StatefulWidget {
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
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _editando = false;
  bool _saving = false;
  final _consumoCtrl = TextEditingController(text: '380');
  final _montoCtrl = TextEditingController(text: '24050');
  final _periodoCtrl = TextEditingController(text: 'Abr-May 2026');
  final _cuentaCtrl = TextEditingController();
  final _empresaCtrl = TextEditingController();

  @override
  void dispose() {
    _consumoCtrl.dispose();
    _montoCtrl.dispose();
    _periodoCtrl.dispose();
    _cuentaCtrl.dispose();
    _empresaCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmarBoleta() async {
    if (_saving) return;
    setState(() => _saving = true);

    final auth = context.read<AuthProvider>();
    final billProvider = context.read<BillProvider>();
    final notifProvider = context.read<NotificationProvider>();

    final isLuz = widget.tab == 0;
    final tipo = isLuz ? 'luz' : 'agua';
    final empresa = _empresaCtrl.text.trim().isNotEmpty 
        ? _empresaCtrl.text.trim() 
        : (isLuz ? 'Enel' : 'Esval');
    final cuenta = _cuentaCtrl.text.trim();
    final tarifa = isLuz ? 'BT1' : 'Tarifa Normal';

    final bill = BillData(
      familyId: auth.profile?.familyId,
      tipo: tipo,
      consumo: _consumoCtrl.text.replaceAll(RegExp(r'\D'), ''),
      monto: _montoCtrl.text.replaceAll(RegExp(r'\D'), ''),
      periodo: _periodoCtrl.text.trim(),
      empresa: empresa,
      cuenta: cuenta,
      tarifa: tarifa,
    );

    final ok = await billProvider.addBill(
      bill,
      achievementProvider: context.read<AchievementProvider>(),
      authProvider: auth,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      final change = billProvider.consumoChangePercent(tipo);
      final xp = billProvider.xpForBill(tipo);
      final emoji = isLuz ? '⚡' : '💧';

      if (change != null && change > 0) {
        notifProvider.addNotification(NotificationItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: '⚠️ Consumo ${isLuz ? 'de luz' : 'de agua'} aumentó',
          desc: 'Tu consumo subió ${change.toStringAsFixed(0)}% vs el período anterior.',
          time: 'Recién',
          iconCode: isLuz ? 'bolt' : 'water_drop',
          colorHex: '#E53935',
          read: false,
        ));
      } else {
        notifProvider.addNotification(NotificationItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: '$emoji Boleta registrada',
          desc: 'Ganaste +$xp XP por registrar tu boleta de ${isLuz ? 'luz' : 'agua'}.',
          time: 'Recién',
          iconCode: 'check_circle',
          colorHex: '#388E3C',
          read: false,
        ));
      }

      if (auth.profile != null) {
        context.read<TaskProvider>().rewardUser(auth.profile!.id, xp, 0);
        auth.refreshProfile();
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Boleta registrada. +$xp XP'),
        backgroundColor: AppTheme.green600,
      ));

      setState(() {
        _editando = false;
        _periodoCtrl.clear();
        _consumoCtrl.clear();
        _montoCtrl.clear();
        _cuentaCtrl.clear();
        _empresaCtrl.clear();
      });
      widget.onStateChange(0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al guardar la boleta'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLuz = widget.tab == 0;
    final empresa = _empresaCtrl.text.isNotEmpty 
        ? _empresaCtrl.text 
        : (isLuz ? 'Enel' : 'Esval');
    final cuenta = _cuentaCtrl.text;
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
                        _tabButton(0, Icons.bolt, 'Luz', AppTheme.amber400),
                        _tabButton(1, Icons.water_drop, 'Agua', AppTheme.blue700),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (widget.state == 0) ...[
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
                        Expanded(child: _cameraButton()),
                        const SizedBox(width: 8),
                        Expanded(child: _pdfButton()),
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
                      ...bills.take(4).map((b) => _billHistoryCard(b, isLuz)),
                    ],
                  ],

                  if (widget.state == 1)
                    const SizedBox(
                      height: 200,
                      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        SizedBox(width: 48, height: 48, child: CircularProgressIndicator(color: AppTheme.green700)),
                        SizedBox(height: 12),
                        Text('Procesando...', style: TextStyle(color: AppTheme.green700, fontWeight: FontWeight.w700)),
                        Text('Extrayendo datos de la boleta', style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
                      ])),
                    ),

                  if (widget.state == 2) ...[
                    Row(children: [
                      const Icon(Icons.check_circle, color: AppTheme.green600, size: 20),
                      const SizedBox(width: 6),
                      Text('Datos extraídos — $empresa', style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 14)),
                    ]),
                    if (!_editando)
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
                    if (_editando) ...[
                      _editField('Empresa', _empresaCtrl),
                      _editField('Cuenta', _cuentaCtrl),
                      _editField('Período', _periodoCtrl),
                      _editField('Consumo (${isLuz ? 'kWh' : 'm³'})', _consumoCtrl),
                      _editField(r'Monto ($)', _montoCtrl),
                    ] else ...[
                      _dataRow('Empresa', empresa),
                      _dataRow('Cuenta', cuenta.isEmpty ? 'No detectada' : cuenta),
                      _dataRow('Período', _periodoCtrl.text.isEmpty ? 'No detectado' : _periodoCtrl.text),
                      _dataRow('Consumo', _formatConsumo(_consumoCtrl.text, isLuz)),
                      _dataRow('Monto', _formatMontoCL(_montoCtrl.text)),
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
                    _editando
                        ? Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => setState(() => _editando = false),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.grey.shade700),
                                  child: const Text('Cancelar Edición', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _montoCtrl.text = _formatMontoCL(_montoCtrl.text);
                                      _editando = false;
                                    });
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
                                        setState(() {
                                          _editando = false;
                                          _periodoCtrl.clear();
                                          _consumoCtrl.clear();
                                          _montoCtrl.clear();
                                          _cuentaCtrl.clear();
                                          _empresaCtrl.clear();
                                        });
                                        widget.onStateChange(0);
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red),
                                      child: const Text('Descartar PDF', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => setState(() => _editando = true),
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
                                  onPressed: _saving ? null : _confirmarBoleta,
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green700, foregroundColor: Colors.white),
                                  child: _saving
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

  Widget _billHistoryCard(BillData b, bool isLuz) {
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
                    if (ok && mounted) {
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
                  Text(_formatConsumo(b.consumo, isLuz), style: const TextStyle(color: AppTheme.textLight, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppTheme.green100, borderRadius: BorderRadius.circular(8)),
              child: Text(_formatMontoCL(b.monto), style: const TextStyle(color: AppTheme.green700, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(int value, IconData icon, String label, Color color) {
    final selected = widget.tab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (widget.tab != value) {
            widget.onStateChange(0);
            setState(() {
              _editando = false;
              _periodoCtrl.clear();
              _consumoCtrl.clear();
              _montoCtrl.clear();
              _cuentaCtrl.clear();
              _empresaCtrl.clear();
            });
            widget.onTabChange(value);
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

  Widget _cameraButton() {
    return GestureDetector(
      onTap: () async {
        final picker = ImagePicker();
        XFile? image;
        try {
          image = await picker.pickImage(source: ImageSource.camera, maxWidth: 800);
        } catch (e) {
          try {
            image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
          } catch (e2) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al abrir cámara/galería: $e2')));
            }
          }
        }
        
        if (image != null) {
          widget.onStateChange(1);
          try {
            String text = '';
            // Try Cloud Vision OCR first for extremely accurate results if a key is available
            if (googleVisionApiKey.isNotEmpty) {
              try {
                text = await _performCloudVisionOcr(File(image.path));
              } catch (e) {
                debugPrint('Google Cloud Vision OCR failed: $e. Falling back to local ML Kit.');
              }
            }
            
            // Local ML Kit OCR fallback
            if (text.isEmpty) {
              final inputImage = InputImage.fromFilePath(image.path);
              final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
              final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
              text = recognizedText.text;
              await textRecognizer.close();
            }
            
            _parseText(text, widget.tab == 0);
            
            if (mounted) widget.onStateChange(2);
          } catch (e) {
            if (mounted) {
              widget.onStateChange(0);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al analizar texto: $e')));
            }
          }
        }
      },
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

  Widget _pdfButton() {
    return GestureDetector(
      onTap: () async {
        FilePickerResult? result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (result != null) {
          widget.onStateChange(1);
          try {
            File file = File(result.files.single.path!);
            final PdfDocument document = PdfDocument(inputBytes: file.readAsBytesSync());
            String text = PdfTextExtractor(document).extractText();
            document.dispose();
            
            if (text.trim().isEmpty) {
              throw Exception('El archivo PDF no contiene texto digital. Por favor, sube una foto de la boleta o usa la cámara.');
            }
            
            _parseText(text, widget.tab == 0);
            
            if (mounted) widget.onStateChange(2);
          } catch (e) {
            if (mounted) {
              widget.onStateChange(0);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al analizar PDF: $e')));
            }
          }
        }
      },
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

  bool _isEmissionOrExpiry(String contextText) {
    return contextText.contains('vence') || 
           contextText.contains('vencimiento') || 
           contextText.contains('emisión') || 
           contextText.contains('emision') || 
           contextText.contains('límite') || 
           contextText.contains('limite') || 
           contextText.contains('expedición') || 
           contextText.contains('expedicion') || 
           contextText.contains('pago') || 
           contextText.contains('vto');
  }

  void _parseText(String text, bool isLuz) {
    String montoStr = '';
    String consumoStr = '';
    String periodoStr = '';
    String cuentaStr = '';
    String empresaStr = isLuz ? 'Enel' : 'Esval';

    // Normalize text and split into lines
    final lines = text.split('\n').map((l) => l.trim()).toList();
    final lowerText = text.toLowerCase();

    // --- 1. DETECTAR EMPRESA ---
    if (lowerText.contains('enel')) {
      empresaStr = 'Enel';
    } else if (lowerText.contains('cge')) {
      empresaStr = 'CGE';
    } else if (lowerText.contains('chilquinta')) {
      empresaStr = 'Chilquinta';
    } else if (lowerText.contains('saesa')) {
      empresaStr = 'Saesa';
    } else if (lowerText.contains('esval')) {
      empresaStr = 'Esval';
    } else if (lowerText.contains('aguas andinas') || lowerText.contains('andinas')) {
      empresaStr = 'Aguas Andinas';
    } else if (lowerText.contains('essbio')) {
      empresaStr = 'Essbio';
    } else if (lowerText.contains('essal')) {
      empresaStr = 'Essal';
    } else if (lowerText.contains('aguas del valle') || lowerText.contains('del valle')) {
      empresaStr = 'Aguas del Valle';
    }

    // --- 2. DETECTAR CUENTA / CLIENTE ---
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      if (line.contains('cliente') || 
          line.contains('servicio') || 
          line.contains('cuenta') || 
          line.contains('ruta') || 
          line.contains('contrato') ||
          line.contains('nº') ||
          line.contains('n°')) {
        
        final sameLineMatch = RegExp(r'\b\d{5,10}[-\s]?[0-9kK]?\b').firstMatch(lines[i]);
        if (sameLineMatch != null) {
          cuentaStr = sameLineMatch.group(0)!.trim();
          break;
        }
        
        bool found = false;
        for (int j = 1; j <= 2 && (i + j) < lines.length; j++) {
          final nextLine = lines[i + j].trim();
          final nextLineMatch = RegExp(r'^\b\d{5,10}[-\s]?[0-9kK]?\b$').firstMatch(nextLine);
          if (nextLineMatch != null) {
            cuentaStr = nextLineMatch.group(0)!;
            found = true;
            break;
          }
        }
        if (found) break;
      }
    }
    
    if (cuentaStr.isEmpty) {
      final fallbackCuenta = RegExp(r'\b\d{5,9}-[0-9kK]\b').firstMatch(text);
      if (fallbackCuenta != null) {
        cuentaStr = fallbackCuenta.group(0)!;
      }
    }

    // Si sigue vacío, buscar en el historial de esta empresa para pre-cargar la cuenta anterior (conocimiento previo)
    if (cuentaStr.isEmpty) {
      try {
        final billProvider = context.read<BillProvider>();
        final historicalBills = billProvider.bills.where((b) => 
          b.empresa?.toLowerCase() == empresaStr.toLowerCase() && 
          b.cuenta != null && 
          b.cuenta!.isNotEmpty
        ).toList();
        
        if (historicalBills.isNotEmpty) {
          cuentaStr = historicalBills.first.cuenta ?? '';
        }
      } catch (e) {
        debugPrint('Error al buscar cuenta histórica: $e');
      }
    }

    // --- 3. DETECTAR MONTO ---
    int? maxMonto;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      if (line.contains('total') || 
          line.contains('pagar') || 
          line.contains('pago') || 
          line.contains('monto') || 
          line.contains('cobrado') || 
          line.contains('neto')) {
        
        for (int j = 0; j <= 1 && (i + j) < lines.length; j++) {
          final checkLine = lines[i + j];
          final matches = RegExp(r'\$?\s*(\d{1,3}(?:[\.,\s]\d{3})+|\d{4,6})').allMatches(checkLine);
          for (final m in matches) {
            final cleanVal = m.group(1)!.replaceAll(RegExp(r'[\.,\s]'), '');
            final val = int.tryParse(cleanVal);
            if (val != null && val >= 1000 && val <= 800000) {
              if (maxMonto == null || val > maxMonto) {
                maxMonto = val;
              }
            }
          }
        }
      }
    }

    if (maxMonto == null) {
      final allMatches = RegExp(r'\$?\s*(\d{1,3}(?:[\.,\s]\d{3})+|\d{4,6})').allMatches(text);
      for (final m in allMatches) {
        final cleanVal = m.group(1)!.replaceAll(RegExp(r'[\.,\s]'), '');
        final val = int.tryParse(cleanVal);
        if (val != null && val >= 1000 && val <= 500000) {
          if (maxMonto == null || val > maxMonto) {
            maxMonto = val;
          }
        }
      }
    }
    
    if (maxMonto != null) {
      montoStr = maxMonto.toString();
    }

    // --- 4. DETECTAR CONSUMO ---
    final unitRegex = isLuz 
        ? RegExp(r'(\d+[\.,]?\d*)\s*(?:kwh|kw|k.w.h|energy|energia)', caseSensitive: false)
        : RegExp(r'(\d+[\.,]?\d*)\s*(?:m3|m³|metros|mts|agua)', caseSensitive: false);
    
    final matchUnit = unitRegex.firstMatch(lowerText);
    if (matchUnit != null) {
      consumoStr = _parseConsumoValue(matchUnit.group(1)!);
    } else {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].toLowerCase();
        if (line.contains('consumo') || line.contains('diferencia') || line.contains('cantidad')) {
          final matches = RegExp(r'\b\d{1,4}(?:[\.,]\d{1,2})?\b').allMatches(lines[i]);
          if (matches.isNotEmpty) {
            consumoStr = _parseConsumoValue(matches.last.group(0)!);
            break;
          }
        }
      }
    }

    // --- 5. DETECTAR PERIODO (RANGO DE FECHAS DE LECTURA) ---
    // Buscamos primero en líneas que hablen de "lectura", "período", "desde", "hasta", "consumo"
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      if (line.contains('lectura') || 
          line.contains('periodo') || 
          line.contains('período') || 
          line.contains('desde') || 
          line.contains('hasta') || 
          line.contains('factur')) {
        
        for (int j = 0; j <= 1 && (i + j) < lines.length; j++) {
          final checkLine = lines[i + j];
          final matchRange = RegExp(
            r'\b(\d{2})[\/\-\.](\d{2})[\/\-\.](\d{4}|\d{2})\b[\s\S]{0,40}?\b(\d{2})[\/\-\.](\d{2})[\/\-\.](\d{4}|\d{2})\b',
          ).firstMatch(checkLine);
          if (matchRange != null) {
            final fullMatch = matchRange.group(0)!;
            final idx = checkLine.indexOf(fullMatch);
            final ctxText = checkLine.substring(
              (idx - 30).clamp(0, checkLine.length),
              (idx + fullMatch.length + 30).clamp(0, checkLine.length),
            ).toLowerCase();
            
            if (_isEmissionOrExpiry(ctxText)) {
              continue;
            }
            
            final d1 = matchRange.group(1);
            final m1 = matchRange.group(2);
            var y1 = matchRange.group(3) ?? '';
            if (y1.length == 2) y1 = '20$y1';
            final d2 = matchRange.group(4);
            final m2 = matchRange.group(5);
            var y2 = matchRange.group(6) ?? '';
            if (y2.length == 2) y2 = '20$y2';
            periodoStr = '$d1/$m1/$y1 al $d2/$m2/$y2';
            break;
          }
        }
        if (periodoStr.isNotEmpty) break;
      }
    }

    // Fallback A: Buscar cualquier rango de dos fechas en todo el texto si no se encontró en líneas específicas
    if (periodoStr.isEmpty) {
      RegExp dateRangeRegExp = RegExp(
        r'\b(\d{2})[\/\-\.](\d{2})[\/\-\.](\d{4}|\d{2})\b[\s\S]{0,50}?\b(\d{2})[\/\-\.](\d{2})[\/\-\.](\d{4}|\d{2})\b',
      );
      final matches = dateRangeRegExp.allMatches(text);
      for (final m in matches) {
        final fullMatch = m.group(0)!;
        final idx = text.indexOf(fullMatch);
        final ctxText = text.substring(
          (idx - 30).clamp(0, text.length),
          (idx + fullMatch.length + 30).clamp(0, text.length),
        ).toLowerCase();
        
        if (_isEmissionOrExpiry(ctxText)) {
          continue;
        }
        
        final d1 = m.group(1);
        final m1 = m.group(2);
        var y1 = m.group(3) ?? '';
        if (y1.length == 2) y1 = '20$y1';
        final d2 = m.group(4);
        final m2 = m.group(5);
        var y2 = m.group(6) ?? '';
        if (y2.length == 2) y2 = '20$y2';
        periodoStr = '$d1/$m1/$y1 al $d2/$m2/$y2';
        break;
      }
    }

    // Fallback B: buscar una fecha única y estimar un período mensual hacia atrás (evitando fechas de vencimiento/emisión)
    if (periodoStr.isEmpty) {
      RegExp singleDateRegExp = RegExp(r'\b(\d{2})[\/\-\.](\d{2})[\/\-\.](\d{4}|\d{2})\b');
      final matches = singleDateRegExp.allMatches(text);
      for (final m in matches) {
        final fullMatch = m.group(0)!;
        final index = text.indexOf(fullMatch);
        final contextText = text.substring((index - 20).clamp(0, text.length), (index + 20).clamp(0, text.length)).toLowerCase();
        if (_isEmissionOrExpiry(contextText)) {
          continue;
        }
        final d = m.group(1);
        final mGroup = m.group(2);
        var y = m.group(3) ?? '';
        if (y.length == 2) y = '20$y';
        final monthInt = int.tryParse(mGroup ?? '') ?? 1;
        final dayInt = int.tryParse(d ?? '') ?? 1;
        final yearInt = int.tryParse(y) ?? 2026;
        final date = DateTime(yearInt, monthInt, dayInt);
        final prevDate = date.subtract(const Duration(days: 30));
        
        final d1 = prevDate.day.toString().padLeft(2, '0');
        final m1 = prevDate.month.toString().padLeft(2, '0');
        final y1 = prevDate.year.toString();
        
        periodoStr = '$d1/$m1/$y1 al $d/$mGroup/$y';
        break;
      }
    }

    setState(() {
      _montoCtrl.text = _formatMontoCL(montoStr);
      _consumoCtrl.text = consumoStr;
      _periodoCtrl.text = periodoStr;
      _empresaCtrl.text = empresaStr;
      if (cuentaStr.isNotEmpty) _cuentaCtrl.text = cuentaStr;
      _editando = true;
    });
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

  Widget _editField(String label, TextEditingController ctrl) {
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
              textAlign: TextAlign.center, // Justifica el texto al medio
              readOnly: isPeriodo,
              onTap: isPeriodo ? () => _selectPeriodo(context) : null,
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

  Future<void> _selectPeriodo(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Selecciona período de facturación',
      locale: const Locale('es', 'CL'), // Calendario en español
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.green600, // Color de cabecera y rango seleccionado
              onPrimary: Colors.white, // Texto en cabecera
              surface: Colors.white, // Fondo de la tarjeta
              onSurface: AppTheme.textDark, // Texto de días
            ),
          ),
          child: Align(
            alignment: Alignment.center,
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 460,
                maxHeight: 600,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: child,
              ),
            ),
          ),
        );
      },
    );
    if (picked != null) {
      final start = picked.start;
      final end = picked.end;
      final startStr = "${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}";
      final endStr = "${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}";
      setState(() {
        _periodoCtrl.text = '$startStr al $endStr';
      });
    }
  }

  Future<String> _performCloudVisionOcr(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    
    final url = Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$googleVisionApiKey');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'TEXT_DETECTION'}
            ]
          }
        ]
      }),
    );
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final responses = jsonResponse['responses'] as List;
      if (responses.isNotEmpty && responses[0]['fullTextAnnotation'] != null) {
        return responses[0]['fullTextAnnotation']['text'] as String;
      }
    }
    throw Exception('Cloud Vision failed: ${response.statusCode} - ${response.body}');
  }

  String _formatMontoCL(String value) {
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return r'$ 0';
    var parsed = int.tryParse(clean) ?? 0;
    
    // Round to the nearest 10 (Chilean Rounding Law)
    final remainder = parsed % 10;
    if (remainder != 0) {
      parsed = (parsed / 10).round() * 10;
    }

    final formatted = parsed.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '\$ $formatted';
  }

  String _formatConsumo(String value, bool isLuz) {
    // Permite dígitos y puntos decimales
    final normalized = value.replaceAll(',', '.');
    final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(normalized);
    if (match == null) return '0 ${isLuz ? 'kWh' : 'm³'}';
    final parsedStr = match.group(0)!;
    return '$parsedStr ${isLuz ? 'kWh' : 'm³'}';
  }

  String _parseConsumoValue(String val) {
    // Reemplaza coma por punto decimal
    final normalized = val.replaceAll(',', '.');
    final dVal = double.tryParse(normalized);
    if (dVal != null) {
      // Si es entero (ej: 5.0 o 5.00), devuelve "5"
      if (dVal == dVal.roundToDouble()) {
        return dVal.round().toString();
      }
      return dVal.toString();
    }
    // Si no es un decimal válido, limpia todo lo que no sea dígito
    return val.replaceAll(RegExp(r'\D'), '');
  }
}
