import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .order('created_at', ascending: false);

      return response.map((json) => AppNotification.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  Future<void> sendNotification(AppNotification notification) async {
    try {
      await _supabase.from('notifications').insert(notification.toJson());
    } catch (e) {
      throw Exception('Failed to send notification: $e');
    }
  }

  Future<void> dismissNotification(String notificationId) async {
    try {
      await _supabase.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to dismiss notification: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }
}
