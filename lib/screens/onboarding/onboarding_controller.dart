import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/auth_service.dart';
import '../../../providers/notification_provider.dart';
import '../../../models/notification_model.dart';

class OnboardingController extends ChangeNotifier {
  final FamilyService _familyService = FamilyService();
  int step = 0;
  String? rol;
  int? personas;
  String? qrToken;
  bool creatingFamily = false;
  bool scanning = false;
  final Map<String, String> encuesta = {};
  final TextEditingController codeCtrl = TextEditingController(text: 'HAB-');
  Timer? qrTimer;
  int qrTimeLeft = 600;
  String? familyCode;

  OnboardingController() {
    codeCtrl.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    codeCtrl.removeListener(_onCodeChanged);
    codeCtrl.dispose();
    qrTimer?.cancel();
    super.dispose();
  }

  void _onCodeChanged() {
    final currentText = codeCtrl.text;
    if (!currentText.toUpperCase().startsWith('HAB-')) {
      codeCtrl.value = codeCtrl.value.copyWith(
        text: 'HAB-',
        selection: const TextSelection.collapsed(offset: 4),
      );
    } else {
      final upperText = currentText.toUpperCase();
      if (currentText != upperText) {
        final selectionIndex = codeCtrl.selection.baseOffset;
        codeCtrl.value = codeCtrl.value.copyWith(
          text: upperText,
          selection: TextSelection.collapsed(offset: selectionIndex),
        );
      }
    }
  }

  String get fmtQrTime {
    final m = (qrTimeLeft ~/ 60).toString().padLeft(2, '0');
    final s = (qrTimeLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void setRol(String? newRol) {
    rol = newRol;
    notifyListeners();
  }

  void setPersonas(int? newPersonas) {
    personas = newPersonas;
    notifyListeners();
  }

  void setEncuesta(String key, String value) {
    encuesta[key] = value;
    notifyListeners();
  }

  Future<void> nextStep(BuildContext context) async {
    if (step == 1 && rol == 'jefe') {
      creatingFamily = true;
      notifyListeners();
      try {
        final profile = context.read<AuthProvider>().profile;
        if (profile != null) {
          await _familyService.createFamily(profile.id, personas ?? 1);
          if (!context.mounted) return;
          await context.read<AuthProvider>().refreshProfile();
          if (!context.mounted) return;
          
          final updatedProfile = context.read<AuthProvider>().profile;
          if (updatedProfile?.familyId != null) {
            final qrData = await _familyService.getOrGenerateActiveQRToken(updatedProfile!.familyId!);
            qrToken = qrData['token'] as String?;
            qrTimeLeft = qrData['timeLeft'] as int? ?? 600;
            familyCode = qrToken;

            qrTimer?.cancel();
            qrTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (qrTimeLeft > 0) {
                qrTimeLeft--;
                notifyListeners();
              } else {
                timer.cancel();
                qrToken = null;
                notifyListeners();
              }
            });
          }
        }
      } catch (_) {}
      if (!context.mounted) return;
      creatingFamily = false;
      notifyListeners();
    }

    step++;
    notifyListeners();
  }

  Future<void> iniciarScan(BuildContext context) async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      if (!context.mounted) return;
      scanning = true;
      notifyListeners();
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se requiere permiso de cámara para escanear'), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> onQRScan(BuildContext context, String data) async {
    scanning = false;
    notifyListeners();
    try {
      String tokenToValidate = data;
      try {
        final json = jsonDecode(data);
        if (json.containsKey('token')) {
          tokenToValidate = json['token'];
        }
      } catch (_) {}

      final familyId = await _familyService.validateFamilyCode(tokenToValidate);
      if (familyId != null) {
        if (!context.mounted) return;
        final profile = context.read<AuthProvider>().profile;
        if (profile != null) {
          await _familyService.linkMember(profile.id, familyId);
          if (!context.mounted) return;
          await context.read<AuthProvider>().refreshProfile();
          
          try {
            final jefes = await _familyService.getFamilyMembers(familyId);
            for (var jefe in jefes.where((m) => m.rol.toLowerCase().contains('jefe'))) {
              NotificationProvider.writeNotificationForUser(
                jefe.id,
                NotificationItem(
                  id: '${DateTime.now().millisecondsSinceEpoch}_join',
                  title: '¡Nuevo miembro!',
                  desc: '${profile.nombre.split(' ')[0]} se ha unido al hogar.',
                  time: DateTime.now().toIso8601String(),
                  iconCode: 'person_add',
                  colorHex: '#4CAF50',
                ),
              );
            }
          } catch (e) {
            debugPrint('Failed to notify jefes: $e');
          }

          if (context.mounted) {
            step = 2;
            notifyListeners();
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR invalido o expirado'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al leer QR'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, String>> getRetosRecomendados() {
    final recomendados = <Map<String, String>>[];

    final ducha = encuesta['ducha'] ?? '';
    if (ducha == '10 a 15 min' || ducha == 'Más de 15 min') {
      recomendados.add({'emoji': '🚿', 'titulo': 'Speedrun de la Ducha', 'desc': 'Ducharte en menos de 10 min', 'xp': '50', 'id': 'ducha'});
    }

    final reciclaje = encuesta['reciclaje'] ?? '';
    if (reciclaje == 'No reciclamos' || reciclaje == 'Separamos lo básico') {
      recomendados.add({'emoji': '🎯', 'titulo': 'Eco-Puzzle', 'desc': 'Clasifica residuos en 60 segundos', 'xp': '120', 'id': 'puzzle'});
    }

    final urgencia = encuesta['urgencia'] ?? '';
    if (urgencia == 'Gasto de Luz') {
      recomendados.add({'emoji': '🧠', 'titulo': 'Trivia Infinita', 'desc': '3 vidas · preguntas de ecología', 'xp': '150', 'id': 'trivia'});
    } else if (urgencia == 'Gasto de Agua') {
      recomendados.add({'emoji': '🔍', 'titulo': 'Inspección del Día', 'desc': 'Sube una foto de la misión de hoy', 'xp': '100', 'id': 'inspeccion'});
    } else if (urgencia == 'Falta de Reciclaje') {
      if (!recomendados.any((r) => r['id'] == 'puzzle')) {
        recomendados.add({'emoji': '🎯', 'titulo': 'Eco-Puzzle', 'desc': 'Clasifica residuos en 60 segundos', 'xp': '120', 'id': 'puzzle'});
      } else {
        recomendados.add({'emoji': '🔍', 'titulo': 'Inspección del Día', 'desc': 'Sube una foto de la misión de hoy', 'xp': '100', 'id': 'inspeccion'});
      }
    }

    final defaults = [
      {'emoji': '🚿', 'titulo': 'Speedrun de la Ducha', 'desc': 'Ducharte en menos de 10 min', 'xp': '50', 'id': 'ducha'},
      {'emoji': '🧠', 'titulo': 'Trivia Infinita', 'desc': '3 vidas · preguntas de ecología', 'xp': '150', 'id': 'trivia'},
      {'emoji': '🎯', 'titulo': 'Eco-Puzzle', 'desc': 'Clasifica residuos en 60 segundos', 'xp': '120', 'id': 'puzzle'},
      {'emoji': '🔍', 'titulo': 'Inspección del Día', 'desc': 'Sube una foto de la misión de hoy', 'xp': '100', 'id': 'inspeccion'},
    ];
    for (final d in defaults) {
      if (recomendados.length >= 3) break;
      if (!recomendados.any((r) => r['titulo'] == d['titulo'])) recomendados.add(d);
    }

    return recomendados.take(3).toList();
  }
}
