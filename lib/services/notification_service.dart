import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _client = Supabase.instance.client;

  // To prevent the stream() C++ engine crash on Windows (due to schema/primary key mismatches),
  // we use a safe query + manual realtime channel instead of SupabaseStreamBuilder.
  
  Stream<List<NotificationItem>> streamNotifications(String userId) async* {
    // 1. Initial fetch
    final initialData = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
        
    List<NotificationItem> currentItems = initialData
        .map((e) => NotificationItem.fromJson(e))
        .toList();
        
    yield currentItems;

    // 2. Listen to changes safely via Channels
    final channel = _client.channel('public:notifications');
    final streamController = StreamController<List<NotificationItem>>.broadcast();
    
    // Pass the initial data into the controller as well just in case
    streamController.add(currentItems);

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        // When a change occurs, fetch the freshest data (safest approach)
        _client
            .from('notifications')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .then((newData) {
          currentItems = newData.map((e) => NotificationItem.fromJson(e)).toList();
          streamController.add(currentItems);
        }).catchError((e) {
          // ignore
        });
      },
    ).subscribe();

    yield* streamController.stream;
  }

  Future<void> sendNotification({
    required String targetUserId,
    required NotificationItem notification,
  }) async {
    await _client.from('notifications').insert({
      'user_id': targetUserId,
      'title': notification.title,
      'desc_text': notification.desc,
      'icon_code': notification.iconCode,
      'color_hex': notification.colorHex,
      'is_read': notification.read,
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _client.from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }
}
