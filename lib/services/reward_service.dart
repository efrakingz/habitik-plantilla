import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class RewardService {
  final SupabaseClient _client = Supabase.instance.client;
  static const _table = 'family_rewards';

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<List<RewardItem>> getRewards(String familyId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('family_id', familyId)
        .order('created_at', ascending: true);

    return _parseList(response as List);
  }

  /// Realtime stream — jefe and miembro both listen; any change propagates instantly.
  Stream<List<RewardItem>> streamRewards(String familyId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .order('created_at', ascending: true)
        .map((rows) => _parseList(rows));
  }

  List<RewardItem> _parseList(List rows) => rows.map((e) => RewardItem(
    id: e['id'] as int,
    titulo: e['titulo'] as String,
    descripcion: e['descripcion'] as String? ?? '',
    emoji: e['emoji'] as String? ?? '🎁',
    costo: e['costo'] as int? ?? 100,
    disponible: e['disponible'] as bool? ?? true,
    creador: e['creador'] as String? ?? '',
    lastRedeemedAt: e['last_redeemed_at'] != null
        ? DateTime.tryParse(e['last_redeemed_at'] as String)
        : null,
  )).toList();

  // ── Seed defaults on first run ────────────────────────────────────────────

  Future<void> seedDefaults(String familyId) async {
    final existing = await getRewards(familyId);
    if (existing.isNotEmpty) return; // already seeded
    final defaults = [
      {'id': 1, 'titulo': 'Cena favorita', 'descripcion': 'Elige la cena del viernes', 'emoji': '🍕', 'costo': 200, 'disponible': true, 'creador': 'Jefe'},
      {'id': 2, 'titulo': 'Día sin tareas', 'descripcion': 'Un día libre de tareas del hogar', 'emoji': '🛌', 'costo': 350, 'disponible': true, 'creador': 'Jefe'},
      {'id': 3, 'titulo': 'Salida al cine', 'descripcion': 'Boletos para toda la familia', 'emoji': '🎬', 'costo': 500, 'disponible': true, 'creador': 'Jefe'},
      {'id': 4, 'titulo': 'Hora extra videojuegos', 'descripcion': '30 min adicionales', 'emoji': '🎮', 'costo': 150, 'disponible': true, 'creador': 'Jefe'},
    ];
    for (final d in defaults) {
      await _client.from(_table).insert({...d, 'family_id': familyId});
    }
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<void> upsertReward(RewardItem r, String familyId) async {
    await _client.from(_table).upsert({
      'id': r.id,
      'family_id': familyId,
      'titulo': r.titulo,
      'descripcion': r.descripcion,
      'emoji': r.emoji,
      'costo': r.costo,
      'disponible': r.disponible,
      'creador': r.creador,
      'last_redeemed_at': r.lastRedeemedAt?.toIso8601String(),
    });
  }

  Future<void> deleteReward(int id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  /// Update only availability after redemption
  Future<void> markRedeemed(int id, {required bool disponible}) async {
    await _client.from(_table).update({
      'disponible': disponible,
      'last_redeemed_at': disponible ? null : DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> resetDailyAvailability(String familyId) async {
    // Called client-side on load — resets rewards whose lastRedeemedAt is not today
    final today = DateTime.now();
    final rewards = await getRewards(familyId);
    for (final r in rewards) {
      if (!r.disponible && r.lastRedeemedAt != null) {
        final rd = r.lastRedeemedAt!;
        if (rd.year != today.year || rd.month != today.month || rd.day != today.day) {
          await markRedeemed(r.id, disponible: true);
        }
      }
    }
  }

  // ── Historial de Canjes (Supabase) ──────────────────────────────────────────

  Future<void> createRedemption(String userId, String familyId, String titulo, int costo) async {
    await _client.from('reward_redemptions').insert({
      'user_id': userId,
      'family_id': familyId,
      'titulo': titulo,
      'costo': costo,
    });
  }

  Future<List<Map<String, dynamic>>> getRedemptionHistory(String userId) async {
    final response = await _client
        .from('reward_redemptions')
        .select('titulo, costo, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => {
      'titulo': e['titulo'] as String,
      'costo': e['costo'] as int,
      'fecha': DateTime.tryParse(e['created_at'] as String? ?? '') ?? DateTime.now(),
    }).toList();
  }
}
