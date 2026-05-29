import 'package:supabase_flutter/supabase_flutter.dart';

class TaskService {
  final SupabaseClient _client = Supabase.instance.client;

  // Note: Unused tasks table operations removed as of balanced economy cleanup.

  Future<bool> rewardUser(String userId, int xpToAdd, int monedasToAdd) async {
    final response = await _client.from('profiles').select('xp, nivel, monedas').eq('id', userId).single();
    
    int currentXp = response['xp'] ?? 0;
    int currentNivel = response['nivel'] ?? 1;
    int currentMonedas = response['monedas'] ?? 0;

    currentXp += xpToAdd;
    currentMonedas += monedasToAdd;

    bool leveledUp = false;
    final xpNeeded = currentNivel * 500;
    
    if (currentXp >= xpNeeded) {
      currentNivel++;
      currentXp -= xpNeeded; // or keep it cumulative? Let's assume cumulative, wait, if cumulative, level is just xp ~/ 500. Let's just do currentNivel++.
      leveledUp = true;
    }

    await _client.from('profiles').update({
      'xp': currentXp,
      'nivel': currentNivel,
      'monedas': currentMonedas,
    }).eq('id', userId);

    return leveledUp;
  }
}
