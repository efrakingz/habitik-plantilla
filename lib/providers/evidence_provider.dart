import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/evidence_service.dart';
import 'achievement_provider.dart';
import 'auth_provider.dart';

class EvidenceProvider with ChangeNotifier {
  final EvidenceService _evidenceService = EvidenceService();
  
  List<Evidence> _evidences = [];
  bool _isLoading = false;
  String? _error;
  String? _currentFamilyId;

  List<Evidence> get evidences => _evidences;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Local cache helpers ────────────────────────────────────────────────────

  String _cacheKey(String familyId) => 'evidence_cache_$familyId';

  Future<void> _saveCache(String familyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_evidences.map((e) => {
        'id': e.id,
        'user_id': e.userId,
        'family_id': e.familyId,
        'autor': e.autor,
        'avatar': e.avatar,
        'color': e.color,
        'avatar_url': e.avatarUrl,
        'accion': e.accion,
        'desc': e.desc,
        'likes': e.likes,
        'tiempo': e.tiempo,
        'xp': e.xp,
        'emoji': e.emoji,
        'imagen': e.imagen,
      }).toList());
      await prefs.setString(_cacheKey(familyId), encoded);
    } catch (e) {
      debugPrint('EvidenceProvider: cache save error: $e');
    }
  }

  Future<List<Evidence>> _loadCache(String familyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(familyId));
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Evidence(
        id: e['id'] ?? '',
        userId: e['user_id'],
        familyId: e['family_id'],
        autor: e['autor'] ?? '',
        avatar: e['avatar'] ?? 'U',
        color: e['color'] ?? '#2e7d32',
        avatarUrl: e['avatar_url'],
        accion: e['accion'] ?? '',
        desc: e['desc'] ?? '',
        likes: e['likes'] ?? 0,
        tiempo: e['tiempo'] ?? '',
        xp: e['xp'] ?? 0,
        emoji: e['emoji'] ?? '🌟',
        imagen: e['imagen'],
      )).toList();
    } catch (e) {
      debugPrint('EvidenceProvider: cache load error: $e');
      return [];
    }
  }

  /// Injects cached SP avatar URLs into a list of evidences by userId
  /// ONLY if the database didn't provide one (e.g. for offline cache)
  Future<List<Evidence>> _injectAvatarUrls(List<Evidence> list) async {
    final prefs = await SharedPreferences.getInstance();
    return list.map((e) {
      if (e.userId == null) return e;
      // Prefer DB URL, fallback to local cache
      final url = e.avatarUrl ?? prefs.getString('avatar_url_${e.userId}');
      if (url == null) return e;
      return Evidence(
        id: e.id, userId: e.userId, familyId: e.familyId,
        autor: e.autor, avatar: e.avatar, color: e.color,
        avatarUrl: url,
        accion: e.accion, desc: e.desc, likes: e.likes,
        tiempo: e.tiempo, xp: e.xp, emoji: e.emoji, imagen: e.imagen,
      );
    }).toList();
  }

  // ── Load: cache-first, then merge with remote ──────────────────────────────

  Future<void> loadEvidences(String familyId) async {
    _currentFamilyId = familyId;

    // Step 1: show cache immediately so UI is never empty
    if (_evidences.isEmpty) {
      final cached = await _loadCache(familyId);
      if (cached.isNotEmpty) {
        _evidences = await _injectAvatarUrls(cached);
        notifyListeners();
      }
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final remote = await _evidenceService.getEvidences(familyId);

      if (remote.isNotEmpty) {
        // Remote has data → inject avatars and use as source of truth
        _evidences = await _injectAvatarUrls(remote);
      } else {
        // Remote returned empty — could be RLS issue or genuinely empty.
        // Keep local cache to avoid wiping locally-approved evidences.
        if (_evidences.isEmpty) {
          _evidences = [];
        }
        debugPrint('EvidenceProvider: remote returned empty for family $familyId — keeping local cache (${_evidences.length} items)');
      }

      // Always update cache with whatever we have
      await _saveCache(familyId);
    } catch (e) {
      _error = e.toString();
      debugPrint('EvidenceProvider: loadEvidences error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Add: optimistic + persist to cache immediately ─────────────────────────

  Future<String?> addEvidence(
    Evidence evidence, {
    AchievementProvider? achievementProvider,
    AuthProvider? authProvider,
  }) async {
    // Inject the current user's avatarUrl if not already set
    Evidence enriched = evidence;
    if (evidence.userId != null && evidence.avatarUrl == null) {
      final prefs = await SharedPreferences.getInstance();
      final url = prefs.getString('avatar_url_${evidence.userId}');
      if (url != null) {
        enriched = Evidence(
          id: evidence.id, userId: evidence.userId, familyId: evidence.familyId,
          autor: evidence.autor, avatar: evidence.avatar, color: evidence.color,
          avatarUrl: url,
          accion: evidence.accion, desc: evidence.desc, likes: evidence.likes,
          tiempo: evidence.tiempo, xp: evidence.xp, emoji: evidence.emoji,
          imagen: evidence.imagen,
        );
      }
    }

    // Optimistic: insert at top of list and cache right away
    _evidences.insert(0, enriched);
    notifyListeners();
    final familyId = enriched.familyId ?? _currentFamilyId;
    if (familyId != null) await _saveCache(familyId);

    try {
      if (familyId != null) {
        await _evidenceService.createEvidence(
          familyId: familyId,
          userId: enriched.userId ?? '',
          accion: enriched.accion,
          descripcion: enriched.desc,
          urlImagen: enriched.imagen,
        );
      }

      // Trigger achievements
      if (achievementProvider != null && authProvider != null && enriched.userId != null) {
        achievementProvider.checkAndUnlock(enriched.userId!, 'primer_registro', authProvider: authProvider).ignore();

        // Check for 10 evidences
        final userEvidences = _evidences.where((e) => e.userId == enriched.userId).length;
        if (userEvidences >= 10) {
          achievementProvider.checkAndUnlock(enriched.userId!, 'multiples_evidencias', authProvider: authProvider).ignore();
        }
      }

      return null;
    } catch (e) {
      _error = e.toString();
      debugPrint('EvidenceProvider: Supabase insert failed: $_error');
      notifyListeners();
      return _error;
    }
  }

  // ── Likes ──────────────────────────────────────────────────────────────────

  Set<String> _likedEvidenceIds = {};
  Set<String> get likedEvidenceIds => _likedEvidenceIds;

  Future<void> loadLikedEvidences(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('liked_evidences_$userId') ?? [];
      _likedEvidenceIds = list.toSet();
      notifyListeners();
    } catch (e) {
      debugPrint('EvidenceProvider: loadLikedEvidences error: $e');
    }
  }

  Future<void> _saveLikedEvidences(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('liked_evidences_$userId', _likedEvidenceIds.toList());
    } catch (e) {
      debugPrint('EvidenceProvider: _saveLikedEvidences error: $e');
    }
  }

  Future<void> toggleLike(Evidence evidence, String userId) async {
    final index = _evidences.indexWhere((e) => e.id == evidence.id);
    final isCurrentlyLiked = _likedEvidenceIds.contains(evidence.id);

    if (index != -1) {
      if (isCurrentlyLiked) {
        _evidences[index].likes--;
        _likedEvidenceIds.remove(evidence.id);
      } else {
        _evidences[index].likes++;
        _likedEvidenceIds.add(evidence.id);
      }
      notifyListeners();
      await _saveLikedEvidences(userId);
    }
    try {
      await _evidenceService.toggleLike(evidence.id, userId, isCurrentlyLiked);
    } catch (e) {
      // Revert optimistic update on error
      if (index != -1) {
        if (isCurrentlyLiked) {
          _evidences[index].likes++;
          _likedEvidenceIds.add(evidence.id);
        } else {
          _evidences[index].likes--;
          _likedEvidenceIds.remove(evidence.id);
        }
        notifyListeners();
        await _saveLikedEvidences(userId);
      }
    }
  }

  void clear() {
    _evidences = [];
    _likedEvidenceIds.clear();
    _currentFamilyId = null;
    notifyListeners();
  }
}
