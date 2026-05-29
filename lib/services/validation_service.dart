import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// Handles cross-device reto validation delivery via Supabase.
/// Members INSERT validations; the Jefe reads and updates them.
class ValidationService {
  final SupabaseClient _client = Supabase.instance.client;
  static const _table = 'reto_validations';

  // ── Insert from member device ──────────────────────────────────────────────

  Future<void> insertValidation(PendingValidation pv, String familyId) async {
    await _client.from(_table).insert({
      'family_id': familyId,
      'user_id': pv.userId,
      'usuario': pv.usuario,
      'avatar': pv.avatar,
      'color': pv.color,
      'reto': pv.reto,
      'hora': pv.hora,
      'xp': pv.xp,
      'monedas': pv.monedas,
      'evidencias': pv.evidencias,
      'requiere_evidencia': pv.requiereEvidencia,
      'estado': 'pendiente',
    });
  }

  // ── Load for jefe ──────────────────────────────────────────────────────────

  Future<List<PendingValidation>> getPendingForFamily(String familyId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('family_id', familyId)
        .eq('estado', 'pendiente')
        .order('created_at', ascending: false);

    return (response as List).map((e) => PendingValidation(
      id: e['id'] as int,
      userId: e['user_id'] as String,
      usuario: e['usuario'] as String,
      avatar: e['avatar'] as String? ?? 'U',
      color: e['color'] as String? ?? '#2e7d32',
      reto: e['reto'] as String,
      hora: e['hora'] as String? ?? '',
      xp: e['xp'] as int? ?? 0,
      monedas: e['monedas'] as int? ?? 0,
      evidencias: List<String>.from(e['evidencias'] ?? []),
      requiereEvidencia: e['requiere_evidencia'] as bool? ?? false,
    )).toList();
  }

  // ── Approve / Reject from jefe device ─────────────────────────────────────

  Future<void> markApproved(int validationId) async {
    await _client.from(_table).update({'estado': 'aprobado'}).eq('id', validationId);
  }

  Future<void> markRejected(int validationId) async {
    await _client.from(_table).update({'estado': 'rechazado'}).eq('id', validationId);
  }

  Future<void> deleteValidation(int validationId) async {
    await _client.from(_table).delete().eq('id', validationId);
  }

  // ── Realtime stream for jefe (live updates) ───────────────────────────────

  Stream<List<PendingValidation>> streamPendingForFamily(String familyId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .order('created_at', ascending: false)
        .map((rows) => rows
            .where((e) => e['estado'] == 'pendiente')
            .map((e) => PendingValidation(
              id: e['id'] as int,
              userId: e['user_id'] as String,
              usuario: e['usuario'] as String,
              avatar: e['avatar'] as String? ?? 'U',
              color: e['color'] as String? ?? '#2e7d32',
              reto: e['reto'] as String,
              hora: e['hora'] as String? ?? '',
              xp: e['xp'] as int? ?? 0,
              monedas: e['monedas'] as int? ?? 0,
              evidencias: List<String>.from(e['evidencias'] ?? []),
              requiereEvidencia: e['requiere_evidencia'] as bool? ?? false,
            ))
            .toList());
  }
}
