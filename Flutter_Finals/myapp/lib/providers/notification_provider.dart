import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _items = [];
  bool _loading = false;
  String? _loadedFor;
  RealtimeChannel? _channel;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _unsubscribe();
    super.dispose();
  }

  List<AppNotification> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  int get unreadCount => _items.where((n) => !n.isRead).length;

  Future<void> load(String userId, {bool force = false}) async {
    if (!force && _loadedFor == userId) return;

    // Subscribe once per user — fires silently on new notifications
    if (_loadedFor != userId) {
      _unsubscribe();
      if (SupabaseConfig.isConfigured) {
        _channel = Supabase.instance.client
            .channel('notifs-$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'notifications',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (_) => _silentRefresh(userId),
            )
            .subscribe();
      }
    }

    _loading = true;
    notifyListeners();
    _items = await NotificationService.loadForUser(userId);
    _loadedFor = userId;
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh(String userId) => load(userId, force: true);

  Future<void> _silentRefresh(String userId) async {
    if (_loadedFor != userId) return;
    final items = await NotificationService.loadForUser(userId);
    if (_disposed || _loadedFor != userId) return;
    _items = items;
    notifyListeners();
  }

  Future<void> markAllRead(String userId) async {
    await NotificationService.markAllRead(userId);
    _items = _items.map((n) => n.isRead
        ? n
        : AppNotification(
            id: n.id, userId: n.userId, orderId: n.orderId,
            type: n.type, title: n.title, body: n.body,
            isRead: true, createdAt: n.createdAt,
          )).toList();
    notifyListeners();
  }

  Future<void> markOneRead(String notifId) async {
    await NotificationService.markOneRead(notifId);
    _items = _items.map((n) => n.id == notifId && !n.isRead
        ? AppNotification(
            id: n.id, userId: n.userId, orderId: n.orderId,
            type: n.type, title: n.title, body: n.body,
            isRead: true, createdAt: n.createdAt,
          )
        : n).toList();
    notifyListeners();
  }

  void _unsubscribe() {
    if (_channel != null && SupabaseConfig.isConfigured) {
      try {
        Supabase.instance.client.removeChannel(_channel!);
      } catch (_) {}
      _channel = null;
    }
  }

  void clear() {
    _unsubscribe();
    _items = [];
    _loadedFor = null;
    notifyListeners();
  }
}
