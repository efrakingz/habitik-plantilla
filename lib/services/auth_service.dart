import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../models/models.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<UserProfile?> signInWithEmail(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) return null;
    return _fetchProfile(response.user!.id);
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<UserProfile?> signUp(String email, String password, String nombre) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'nombre': nombre},
    );
    if (response.user == null) return null;
    return _fetchProfile(response.user!.id);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<UserProfile?> _fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return UserProfile.fromJson(data);
  }

  Future<UserProfile?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _fetchProfile(user.id);
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> deductCoins(String userId, int currentCoins, int cost) async {
    await _client.from('profiles').update({'monedas': currentCoins - cost}).eq('id', userId);
  }

  Future<void> updateTriviaScore(String userId, int count, String todayDate) async {
    await _client.from('profiles').update({
      'trivia_correct_count': count,
      'trivia_last_updated': todayDate,
    }).eq('id', userId);
  }

  Future<void> updateDailyBonusClaimedAt(String userId, String date) async {
    await _client.from('profiles').update({
      'daily_bonus_claimed_at': date,
    }).eq('id', userId);
  }
}

class FamilyService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String?> createFamily(String userId, int personas) async {
    final code = 'HAB-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase().substring(0, 8)}';
    final response = await _client.from('families').insert({
      'jefe_id': userId,
      'nombre': 'Mi Hogar',
      'family_code': code,
    }).select('id').single();

    final familyId = response['id'] as String;

    await _client.from('profiles').update({
      'family_id': familyId,
      'rol': 'jefe',
    }).eq('id', userId);

    return familyId;
  }

  Future<Map<String, dynamic>> getOrGenerateActiveQRToken(String familyId, {bool forceNew = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final tokenKey = 'active_qr_token_$familyId';
    final expiryKey = 'active_qr_expiry_$familyId';

    if (forceNew) {
      await prefs.remove(tokenKey);
      await prefs.remove(expiryKey);
    } else {
      final cachedToken = prefs.getString(tokenKey);
      final cachedExpiryStr = prefs.getString(expiryKey);

      if (cachedToken != null && cachedExpiryStr != null) {
        final expiry = DateTime.parse(cachedExpiryStr).toUtc();
        final nowUtc = DateTime.now().toUtc();
        if (expiry.isAfter(nowUtc)) {
          final remainingSeconds = expiry.difference(nowUtc).inSeconds;
          return {
            'token': cachedToken,
            'timeLeft': remainingSeconds,
          };
        }
      }
    }

    // Generar nuevo código con formato HAB-XXXXXXXX (donde XXXXXXXX son 8 caracteres aleatorios de letras mayúsculas y números)
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    final randomSuffix = List.generate(8, (index) => chars[rand.nextInt(chars.length)]).join();
    final newToken = 'HAB-$randomSuffix';
    final expiryTime = DateTime.now().toUtc().add(const Duration(minutes: 10));

    await _client.from('qr_tokens').insert({
      'family_id': familyId,
      'token': newToken,
      'expires_at': expiryTime.toIso8601String(),
    });

    await prefs.setString(tokenKey, newToken);
    await prefs.setString(expiryKey, expiryTime.toIso8601String());

    return {
      'token': newToken,
      'timeLeft': 600,
    };
  }

  Future<String?> generateQRToken(String familyId) async {
    final res = await getOrGenerateActiveQRToken(familyId);
    return res['token'] as String?;
  }

  Future<String?> validateFamilyCode(String code) async {
    try {
      // First try as direct family_code
      final response = await _client
          .from('families')
          .select('id')
          .eq('family_code', code)
          .maybeSingle();

      if (response != null) {
        return response['id'];
      }

      // Fallback for older dynamic tokens if needed
      final tokenResponse = await _client
          .from('qr_tokens')
          .select('family_id')
          .eq('token', code)
          .eq('used', false)
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .maybeSingle();

      if (tokenResponse != null) {
        await _client.from('qr_tokens').update({'used': true}).eq('token', code);
        return tokenResponse['family_id'];
      }
    } catch (_) {}
    return null;
  }

  Future<void> linkMember(String userId, String familyId) async {
    await _client.from('profiles').update({
      'family_id': familyId,
      'rol': 'miembro',
    }).eq('id', userId);
  }

  Future<void> updateMetas(String familyId, int metaLuz, int metaAgua) async {
    await _client.from('families').update({
      'meta_luz': metaLuz,
      'meta_agua': metaAgua,
    }).eq('id', familyId);
  }

  Future<Map<String, dynamic>?> getFamilyDetails(String familyId) async {
    final response = await _client.from('families').select().eq('id', familyId).maybeSingle();
    return response;
  }

  Future<List<FamilyMember>> getFamilyMembers(String familyId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('family_id', familyId)
        .order('xp', ascending: false);

    return (response as List).map((data) => FamilyMember.fromJson(data)).toList();
  }

  Future<void> deductCoins(String userId, int currentCoins, int cost) async {
    await _client.from('profiles').update({'monedas': currentCoins - cost}).eq('id', userId);
  }
}