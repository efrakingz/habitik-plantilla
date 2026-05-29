import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class EvidenceService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Evidence>> getEvidences(String familyId) async {
    final response = await _client
        .from('evidences')
        .select('''
          *,
          profiles (nombre, avatar_letra, avatar_color, avatar_url),
          evidence_likes (count)
        ''')
        .eq('family_id', familyId)
        .order('created_at', ascending: false);

    return (response as List).map((data) {
      final profile = data['profiles'] ?? {};
      final likesCount = data['evidence_likes']?[0]?['count'] ?? 0;
      
      return Evidence(
        id: data['id'] ?? '',
        userId: data['user_id'],
        familyId: data['family_id'],
        autor: profile['nombre'] ?? 'Usuario',
        avatar: profile['avatar_letra'] ?? 'U',
        color: profile['avatar_color'] ?? '#2e7d32',
        avatarUrl: profile['avatar_url'],
        accion: data['accion'] ?? '',
        desc: data['descripcion'] ?? '',
        likes: likesCount,
        tiempo: data['created_at'] ?? '',
        xp: 0, // evidences table has no xp column; XP is tracked in profiles
        emoji: '🌟', // Default for now
        imagen: data['imagen_url'],
      );
    }).toList();
  }

  Future<void> createEvidence({
    required String familyId,
    required String userId,
    required String accion,
    required String descripcion,
    String? urlImagen,
  }) async {
    final payload = <String, dynamic>{
      'family_id': familyId,
      'user_id': userId,
      'accion': accion,
      'descripcion': descripcion,
    };
    // Only include imagen_url when there's a real URL — avoids NOT NULL violation
    // for retos that don't require a photo (shower, trivia, puzzle, etc.)
    if (urlImagen != null && urlImagen.isNotEmpty) {
      payload['imagen_url'] = urlImagen;
    }
    await _client.from('evidences').insert(payload);
  }

  Future<void> toggleLike(String evidenceId, String userId, bool isLiked) async {
    if (isLiked) {
      await _client.from('evidence_likes').delete().eq('evidence_id', evidenceId).eq('user_id', userId);
    } else {
      await _client.from('evidence_likes').insert({
        'evidence_id': evidenceId,
        'user_id': userId,
      });
    }
  }
}
