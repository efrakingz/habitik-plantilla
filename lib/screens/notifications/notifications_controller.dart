import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/notification_provider.dart';

class NotificationsController extends ChangeNotifier {
  Color parseColor(String hex) {
    try {
      if (hex.isEmpty) return AppTheme.green600;
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppTheme.green600;
    }
  }

  IconData getIcon(String code) {
    switch (code) {
      case 'emoji_events': return Icons.emoji_events;
      case 'close': return Icons.close;
      case 'card_giftcard': return Icons.card_giftcard;
      case 'favorite': return Icons.favorite;
      case 'check_circle': return Icons.check_circle;
      case 'local_fire_department': return Icons.local_fire_department;
      case 'lightbulb': return Icons.lightbulb;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'home': return Icons.home;
      default: return Icons.notifications;
    }
  }

  void markAsRead(BuildContext context, String id) {
    context.read<NotificationProvider>().markAsRead(id);
  }
}
