import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/family_provider.dart';
import '../../../providers/evidence_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/bill_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/achievement_provider.dart';

class DashboardController extends ChangeNotifier {
  int currentIndex = 0;
  String activeChallenge = '';
  int scanTab = 0;
  int scanState = 0;
  int metaLuz = 15;
  int metaAgua = 15;

  void setTabIndex(int index) {
    currentIndex = index;
    notifyListeners();
  }

  void setActiveChallenge(String challengeId) {
    activeChallenge = challengeId;
    notifyListeners();
  }

  void setScanTab(int tab) {
    scanTab = tab;
    notifyListeners();
  }

  void setScanState(int state) {
    scanState = state;
    notifyListeners();
  }

  void setMetaLuz(int meta) {
    metaLuz = meta;
    notifyListeners();
  }

  void setMetaAgua(int meta) {
    metaAgua = meta;
    notifyListeners();
  }

  Future<void> initData(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final familyId = auth.profile?.familyId;
    final userId = auth.user?.id;
    
    final familyProv = context.read<FamilyProvider>();
    final evidenceProv = context.read<EvidenceProvider>();
    final taskProv = context.read<TaskProvider>();
    final billProv = context.read<BillProvider>();
    final notifProv = context.read<NotificationProvider>();
    final achievementProv = context.read<AchievementProvider>();

    if (familyId != null) {
      await familyProv.loadFamilyMembers(familyId);
      await evidenceProv.loadEvidences(familyId);
      if (userId != null) {
        await evidenceProv.loadLikedEvidences(userId);
      }
      await billProv.loadBills(familyId);
    }
    
    if (userId != null) {
      await taskProv.loadForUser(userId, familyId: familyId);
      await notifProv.loadForUser(userId);
      await achievementProv.loadForUser(userId);
      if (auth.profile != null) {
        achievementProv.checkProfileAchievements(auth.profile!, auth);
      }
    }
  }

  Future<void> refresh(BuildContext context) async {
    final a = context.read<AuthProvider>();
    if (a.profile?.familyId != null) {
      await a.refreshProfile();
      if (!context.mounted) return;
      await context.read<FamilyProvider>().loadFamilyMembers(a.profile!.familyId!);
      if (!context.mounted) return;
      await context.read<EvidenceProvider>().loadEvidences(a.profile!.familyId!);
    }
  }
}
