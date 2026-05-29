import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme.dart';
import '../../../models/models.dart';
import '../../../models/notification_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/bill_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/achievement_provider.dart';

const String googleVisionApiKey = String.fromEnvironment(
  'GOOGLE_VISION_API_KEY',
  defaultValue: 'AIzaSyA9eM963NObsOTwwP8qBiSzSAf1Rz9N4AI',
);

class ScanController extends ChangeNotifier {
  bool editando = false;
  bool saving = false;
  
  final TextEditingController consumoCtrl = TextEditingController(text: '380');
  final TextEditingController montoCtrl = TextEditingController(text: '24050');
  final TextEditingController periodoCtrl = TextEditingController(text: 'Abr-May 2026');
  final TextEditingController cuentaCtrl = TextEditingController();
  final TextEditingController empresaCtrl = TextEditingController();

  @override
  void dispose() {
    consumoCtrl.dispose();
    montoCtrl.dispose();
    periodoCtrl.dispose();
    cuentaCtrl.dispose();
    empresaCtrl.dispose();
    super.dispose();
  }

  void setEditando(bool value) {
    if (editando != value) {
      editando = value;
      notifyListeners();
    }
  }

  void discard() {
    editando = false;
    periodoCtrl.clear();
    consumoCtrl.clear();
    montoCtrl.clear();
    cuentaCtrl.clear();
    empresaCtrl.clear();
    notifyListeners();
  }

  Future<void> confirmarBoleta(BuildContext context, int tab, void Function(int) onStateChange) async {
    if (saving) return;
    
    saving = true;
    notifyListeners();

    final auth = context.read<AuthProvider>();
    final billProvider = context.read<BillProvider>();
    final notifProvider = context.read<NotificationProvider>();

    final isLuz = tab == 0;
    final tipo = isLuz ? 'luz' : 'agua';
    final empresa = empresaCtrl.text.trim().isNotEmpty 
        ? empresaCtrl.text.trim() 
        : (isLuz ? 'Enel' : 'Esval');
    final cuenta = cuentaCtrl.text.trim();
    final tarifa = isLuz ? 'BT1' : 'Tarifa Normal';

    final bill = BillData(
      familyId: auth.profile?.familyId,
      tipo: tipo,
      consumo: consumoCtrl.text.replaceAll(RegExp(r'\D'), ''),
      monto: montoCtrl.text.replaceAll(RegExp(r'\D'), ''),
      periodo: periodoCtrl.text.trim(),
      empresa: empresa,
      cuenta: cuenta,
      tarifa: tarifa,
    );

    final ok = await billProvider.addBill(
      bill,
      achievementProvider: context.read<AchievementProvider>(),
      authProvider: auth,
    );

    saving = false;
    notifyListeners();

    if (!context.mounted) return;

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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Boleta registrada. +$xp XP'),
          backgroundColor: AppTheme.green600,
        ));
      }

      editando = false;
      periodoCtrl.clear();
      consumoCtrl.clear();
      montoCtrl.clear();
      cuentaCtrl.clear();
      empresaCtrl.clear();
      notifyListeners();
      
      onStateChange(0);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error al guardar la boleta'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  Future<void> selectPeriodo(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Selecciona período de facturación',
      locale: const Locale('es', 'CL'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.green600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textDark,
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
      
      periodoCtrl.text = '$startStr al $endStr';
      notifyListeners();
    }
  }

  Future<void> handleCameraAction(BuildContext context, int tab, void Function(int) onStateChange) async {
    final picker = ImagePicker();
    XFile? image;
    try {
      image = await picker.pickImage(source: ImageSource.camera, maxWidth: 800);
    } catch (e) {
      try {
        image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
      } catch (e2) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al abrir cámara/galería: $e2')));
        }
      }
    }
    
    if (image != null) {
      onStateChange(1);
      try {
        String text = '';
        if (googleVisionApiKey.isNotEmpty) {
          try {
            text = await _performCloudVisionOcr(File(image.path));
          } catch (e) {
            debugPrint('Google Cloud Vision OCR failed: $e. Falling back to local ML Kit.');
          }
        }
        
        if (text.isEmpty) {
          final inputImage = InputImage.fromFilePath(image.path);
          final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
          final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
          text = recognizedText.text;
          await textRecognizer.close();
        }
        
        _parseText(context, text, tab == 0);
        
        if (context.mounted) onStateChange(2);
      } catch (e) {
        if (context.mounted) {
          onStateChange(0);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al analizar texto: $e')));
        }
      }
    }
  }

  Future<void> handlePdfAction(BuildContext context, int tab, void Function(int) onStateChange) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      onStateChange(1);
      try {
        File file = File(result.files.single.path!);
        final PdfDocument document = PdfDocument(inputBytes: file.readAsBytesSync());
        String text = PdfTextExtractor(document).extractText();
        document.dispose();
        
        if (text.trim().isEmpty) {
          throw Exception('El archivo PDF no contiene texto digital. Por favor, sube una foto de la boleta o usa la cámara.');
        }
        
        _parseText(context, text, tab == 0);
        
        if (context.mounted) onStateChange(2);
      } catch (e) {
        if (context.mounted) {
          onStateChange(0);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al analizar PDF: $e')));
        }
      }
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

  void _parseText(BuildContext context, String text, bool isLuz) {
    String montoStr = '';
    String consumoStr = '';
    String periodoStr = '';
    String cuentaStr = '';
    String empresaStr = isLuz ? 'Enel' : 'Esval';

    final lines = text.split('\n').map((l) => l.trim()).toList();
    final lowerText = text.toLowerCase();

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

    montoCtrl.text = formatMontoCL(montoStr);
    consumoCtrl.text = consumoStr;
    periodoCtrl.text = periodoStr;
    empresaCtrl.text = empresaStr;
    if (cuentaStr.isNotEmpty) cuentaCtrl.text = cuentaStr;
    editando = true;
    notifyListeners();
  }

  String formatMontoCL(String value) {
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return r'$ 0';
    var parsed = int.tryParse(clean) ?? 0;
    
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

  String formatConsumo(String value, bool isLuz) {
    final normalized = value.replaceAll(',', '.');
    final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(normalized);
    if (match == null) return '0 ${isLuz ? 'kWh' : 'm³'}';
    final parsedStr = match.group(0)!;
    return '$parsedStr ${isLuz ? 'kWh' : 'm³'}';
  }

  String _parseConsumoValue(String val) {
    final normalized = val.replaceAll(',', '.');
    final dVal = double.tryParse(normalized);
    if (dVal != null) {
      if (dVal == dVal.roundToDouble()) {
        return dVal.round().toString();
      }
      return dVal.toString();
    }
    return val.replaceAll(RegExp(r'\D'), '');
  }
}
