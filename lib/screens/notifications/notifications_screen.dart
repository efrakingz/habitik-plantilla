import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/notification_provider.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationsController(),
      child: const _NotificationsScreenContent(),
    );
  }
}

class _NotificationsScreenContent extends StatelessWidget {
  const _NotificationsScreenContent();

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final controller = context.watch<NotificationsController>();
    final notifs = notificationProvider.notifications;

    return Scaffold(
      body: Container(
        color: AppTheme.green700,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(width: 32, height: 32, decoration: const BoxDecoration(color: AppTheme.green600, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 18)),
                    ),
                    const SizedBox(width: 12),
                    const Text('Notificaciones', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: notifs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final n = notifs[i];
                      return GestureDetector(
                        onTap: () {
                          if (!n.read) {
                            controller.markAsRead(context, n.id);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: n.read ? Colors.white : AppTheme.green50,
                            border: Border.all(color: n.read ? Colors.grey.shade200 : AppTheme.green200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: controller.parseColor(n.colorHex).withValues(alpha: 0.2),
                                child: Icon(controller.getIcon(n.iconCode), color: controller.parseColor(n.colorHex), size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.title, style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w700)),
                                    Text(n.desc, style: const TextStyle(color: AppTheme.green600, fontSize: 11)),
                                    const SizedBox(height: 4),
                                    Text(n.time, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                                  ],
                                ),
                              ),
                              if (!n.read) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.amber400, shape: BoxShape.circle)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
