import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/family_provider.dart';
import '../../../services/auth_service.dart';

class ProfileController extends ChangeNotifier {
  bool showQr = false;
  String? qrToken;
  Timer? qrTimer;
  int qrTimeLeft = 600;
  bool uploadingAvatar = false;

  @override
  void dispose() {
    qrTimer?.cancel();
    super.dispose();
  }

  void loadActiveQrToken(String familyId, {bool forceNew = false}) async {
    showQr = true;
    qrToken = null;
    notifyListeners();

    try {
      final qrData = await FamilyService().getOrGenerateActiveQRToken(familyId, forceNew: forceNew);
      qrToken = qrData['token'] as String?;
      qrTimeLeft = qrData['timeLeft'] as int? ?? 600;
      notifyListeners();

      qrTimer?.cancel();
      qrTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (qrTimeLeft > 0) {
          qrTimeLeft--;
          notifyListeners();
        } else {
          timer.cancel();
          showQr = false;
          qrToken = null;
          notifyListeners();
        }
      });
    } catch (_) {
      showQr = false;
      notifyListeners();
    }
  }

  void generateQr(String familyId) {
    loadActiveQrToken(familyId, forceNew: false);
  }

  String get fmtQrTime {
    final m = (qrTimeLeft ~/ 60).toString().padLeft(2, '0');
    final s = (qrTimeLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> pickAndUploadAvatar(BuildContext context, String userId) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400);
    if (xFile == null) return;
    
    uploadingAvatar = true;
    notifyListeners();

    try {
      final bytes = await xFile.readAsBytes();
      final ext = xFile.path.split('.').last;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$ext';
      
      final client = Supabase.instance.client;
      await client.storage.from('avatars').uploadBinary(fileName, bytes);
      final url = client.storage.from('avatars').getPublicUrl(fileName);

      await client.from('profiles').update({
        'avatar_url': url,
      }).eq('id', userId);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('avatar_url_$userId', url);
      
      if (context.mounted) {
        context.read<AuthProvider>().setLocalAvatarUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir: $e')));
      }
    }
    
    uploadingAvatar = false;
    notifyListeners();
  }

  Future<void> updateMemberRole(BuildContext context, String memberId, String name, String newRole) async {
    try {
      await Supabase.instance.client.from('profiles').update({
        'nombre': name,
        'rol': newRole,
      }).eq('id', memberId);
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Miembro actualizado'), backgroundColor: Color(0xFF43A047)));
      
      final profile = context.read<AuthProvider>().profile;
      if (profile?.familyId != null) {
        context.read<FamilyProvider>().loadFamilyMembers(profile!.familyId!);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> updateFamilyName(BuildContext context, String familyId, String newName) async {
    try {
      await Supabase.instance.client.from('families').update({
        'nombre': newName,
      }).eq('id', familyId);
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre actualizado')));
      context.read<FamilyProvider>().loadFamilyMembers(familyId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> updateFamilyPhoto(BuildContext context, String familyId, Function(bool) setUploadingState) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (image == null) return;
    
    setUploadingState(true);
    try {
      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final filePath = 'families/$familyId/$fileName';

      await Supabase.instance.client.storage.from('avatars').upload(filePath, file);
      final imageUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(filePath);

      await Supabase.instance.client.from('families').update({
        'avatar_url': imageUrl,
      }).eq('id', familyId);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('family_avatar_url_$familyId', imageUrl);

      if (!context.mounted) return;
      context.read<FamilyProvider>().setLocalFamilyAvatar(imageUrl);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto actualizada')));
      context.read<FamilyProvider>().loadFamilyMembers(familyId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir foto: $e')));
    } finally {
      setUploadingState(false);
    }
  }
}
