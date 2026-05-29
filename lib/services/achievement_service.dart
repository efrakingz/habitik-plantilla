import 'package:supabase_flutter/supabase_flutter.dart';

class AchievementService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getUnlockedAchievements(String userId) async {
    final response = await _client
        .from('achievements')
        .select('logro_key, desbloqueado_en')
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> unlockAchievement(String userId, String key) async {
    await _client.from('achievements').insert({
      'user_id': userId,
      'logro_key': key,
    });
  }
}
