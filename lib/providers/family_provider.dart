import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/auth_service.dart';

class FamilyProvider with ChangeNotifier {
  final FamilyService _familyService = FamilyService();
  
  List<FamilyMember> _members = [];
  String _familyName = 'Familia';
  String _familyCode = '';
  String? _familyAvatar;
  bool _isLoading = false;
  String? _error;

  List<FamilyMember> get members => _members;
  String get familyName => _familyName;
  String get familyCode => _familyCode;
  String? get familyAvatar => _familyAvatar;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFamilyMembers(String familyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Single SP instance for the whole load
      final prefs = await SharedPreferences.getInstance();

      final details = await _familyService.getFamilyDetails(familyId);
      if (details != null) {
        _familyName = details['nombre'] ?? 'Familia';
        _familyCode = details['family_code'] ?? '';
        // Try DB first, fallback to SP
        _familyAvatar = details['avatar_url']?.toString() ?? prefs.getString('family_avatar_url_$familyId');
      }

      final rawMembers = await _familyService.getFamilyMembers(familyId);
      // DB now has avatar_url, but we fallback to SP if it's missing just in case
      _members = rawMembers.map((m) {
        final url = m.avatarUrl ?? prefs.getString('avatar_url_${m.id}');
        return m.withAvatarUrl(url);
      }).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Called immediately after a successful avatar upload so the UI
  /// updates without waiting for the next loadFamilyMembers call.
  void setLocalFamilyAvatar(String url) {
    _familyAvatar = url;
    notifyListeners();
  }

  void clear() {
    _members = [];
    _familyName = '';
    _familyCode = '';
    _familyAvatar = null;
    notifyListeners();
  }
}
