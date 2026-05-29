import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _service = NotificationService();
  StreamSubscription<List<NotificationItem>>? _sub;
  
  List<NotificationItem> _notifications = [];
  String? _currentUserId;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  Future<void> loadForUser(String userId) async {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    
    _sub?.cancel();
    _sub = _service.streamNotifications(userId).listen((data) {
      _notifications = data;
      notifyListeners();
    }, onError: (error) {
      debugPrint('NotificationProvider: Stream error: $error');
      // Non-fatal, just log it so the app doesn't crash
    });
  }

  static Future<void> writeNotificationForUser(
    String targetUserId,
    NotificationItem item,
  ) async {
    final service = NotificationService();
    try {
      await service.sendNotification(targetUserId: targetUserId, notification: item);
      debugPrint('NotificationProvider: wrote notification for user $targetUserId');
    } catch (e) {
      debugPrint('NotificationProvider: ERROR writing for user $targetUserId: $e');
    }
  }

  void markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].read) {
      // Optimistic update
      _notifications[index].read = true;
      notifyListeners();
      
      try {
        await _service.markAsRead(id);
      } catch (e) {
        debugPrint('NotificationProvider: Error marking read: $e');
        _notifications[index].read = false;
        notifyListeners();
      }
    }
  }

  // Fallback for legacy calls - actually just sends to current user
  Future<void> addNotification(NotificationItem item) async {
    if (_currentUserId != null) {
      await writeNotificationForUser(_currentUserId!, item);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void clear() {
    _notifications = [];
    _currentUserId = null;
    _sub?.cancel();
    _sub = null;
    notifyListeners();
  }
}
