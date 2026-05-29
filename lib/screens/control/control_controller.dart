import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/models.dart';
import '../../../models/notification_model.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/family_provider.dart';
import '../../../providers/evidence_provider.dart';
import '../../../providers/achievement_provider.dart';

class ControlController extends ChangeNotifier {
  String? rechazoMotivo;
  int? rechazandoId;
  String? rechazandoUserId;
  String? rechazandoReto;

  Future<void> refreshValidations(BuildContext context) async {
    await context.read<TaskProvider>().refreshValidations();
  }

  Future<void> aprobar(BuildContext context, int id) async {
    final taskProvider = context.read<TaskProvider>();
    final authProvider = context.read<AuthProvider>();
    final familyProvider = context.read<FamilyProvider>();
    final evidenceProvider = context.read<EvidenceProvider>();
    final achievementProvider = context.read<AchievementProvider>();

    final index = taskProvider.pendingValidations.indexWhere((v) => v.id == id);
    if (index == -1) return;
    
    final validation = taskProvider.pendingValidations[index];
    final leveledUp = await taskProvider.approveValidation(id);
    
    if (!context.mounted) return;
    
    final authProfile = authProvider.profile;
    if (authProfile?.familyId != null) {
      familyProvider.loadFamilyMembers(authProfile!.familyId!);
    }

    final isCanje = validation.evidencias.length == 1 && validation.evidencias.first == 'Canje';
    String? error;
    if (isCanje) {
      error = await evidenceProvider.addEvidence(
        Evidence(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          familyId: authProfile?.familyId,
          userId: validation.userId,
          autor: validation.usuario,
          avatar: validation.avatar,
          color: '#F57C00',
          accion: validation.reto,
          desc: '¡Canje aprobado por el Jefe de Hogar! 🎉',
          xp: 0,
          tiempo: 'Recién',
          emoji: '🎁',
          imagen: null,
          likes: 0,
        ),
        achievementProvider: achievementProvider,
        authProvider: authProvider,
      );
    } else {
      final firstImage = validation.evidencias.firstWhere(
        (e) => e.contains('/') || e.contains('\\'),
        orElse: () => '',
      );
      error = await evidenceProvider.addEvidence(
        Evidence(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          familyId: authProfile?.familyId,
          userId: validation.userId,
          autor: validation.usuario,
          avatar: validation.avatar,
          color: validation.color,
          accion: validation.reto,
          desc: 'Reto aprobado exitosamente',
          xp: validation.xp,
          tiempo: 'Recién',
          emoji: '🎯',
          imagen: firstImage.isNotEmpty ? firstImage : null,
          likes: 0,
        ),
        achievementProvider: achievementProvider,
        authProvider: authProvider,
      );
    }

    if (error == null && authProfile != null) {
      achievementProvider.checkAndUnlock(
        authProfile.id,
        'jefe_aprobador',
        authProvider: authProvider,
      ).ignore();
    }
    
    if (!context.mounted) return;
    
    final now = DateTime.now().toIso8601String();
    
    if (isCanje) {
      NotificationProvider.writeNotificationForUser(
        validation.userId,
        NotificationItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_canje',
          title: '✅ Canje aprobado',
          desc: 'Tu canje de "${validation.reto}" ha sido aprobado.',
          time: now,
          iconCode: 'card_giftcard',
          colorHex: '#4CAF50',
        ),
      );
    } else {
      NotificationProvider.writeNotificationForUser(
        validation.userId,
        NotificationItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_reto',
          title: '✅ Reto aprobado',
          desc: 'Tu evidencia para "${validation.reto}" fue aprobada. +${validation.xp} XP',
          time: now,
          iconCode: 'check_circle',
          colorHex: '#4CAF50',
        ),
      );
    }

    if (leveledUp) {
      NotificationProvider.writeNotificationForUser(
        validation.userId,
        NotificationItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_nivel',
          title: '¡Subiste de nivel!',
          desc: '¡Felicidades! Has alcanzado un nuevo nivel.',
          time: now,
          iconCode: 'emoji_events',
          colorHex: '#F9A825',
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error != null ? 'Error DB: $error' : (isCanje ? 'Canje aprobado.' : (leveledUp ? 'Evidencia aprobada. ¡El usuario subió de nivel!' : 'Evidencia aprobada.'))),
        backgroundColor: error != null ? Colors.red : const Color(0xFF43A047),
        duration: const Duration(seconds: 6),
      )
    );
  }

  void iniciarRechazo(int id, String userId, String reto) {
    rechazandoId = id;
    rechazandoUserId = userId;
    rechazandoReto = reto;
    rechazoMotivo = '';
    notifyListeners();
  }

  void setRechazoMotivo(String motivo) {
    rechazoMotivo = motivo;
    notifyListeners();
  }

  void confirmarRechazo(BuildContext context) {
    if (rechazandoId != null && rechazoMotivo != null && rechazoMotivo!.trim().isNotEmpty) {
      context.read<TaskProvider>().rejectValidation(rechazandoId!, rechazoMotivo!);

      if (rechazandoUserId != null) {
        final jefeName = context.read<AuthProvider>().profile?.nombre ?? 'El Jefe';
        final reto = rechazandoReto ?? 'tu solicitud';
        NotificationProvider.writeNotificationForUser(
          rechazandoUserId!,
          NotificationItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: '❌ Solicitud rechazada',
            desc: '"$reto" fue rechazada por $jefeName. Motivo: ${rechazoMotivo!.trim()}',
            time: DateTime.now().toIso8601String(),
            iconCode: 'cancel',
            colorHex: '#E53935',
            read: false,
          ),
        );
      }

      rechazandoId = null;
      rechazandoUserId = null;
      rechazandoReto = null;
      rechazoMotivo = null;
      notifyListeners();
      Navigator.pop(context);
    }
  }
}
