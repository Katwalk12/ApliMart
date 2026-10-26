// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/message.dart';
import '../services/message_service.dart';

class MessageProvider extends ChangeNotifier {
  List<Message> _messages = [];
  bool _loading = false;
  String? _loadedFor;
  RealtimeChannel? _channel;
  bool _disposed = false;
  int _unseenCount = 0;

  List<Message> get messages => List.unmodifiable(_messages);
  bool get loading => _loading;
  int get unseenCount => _unseenCount;

  @override
  void dispose() {
    _disposed = true;
    _unsubscribe();
    super.dispose();
  }

  Future<void> load(String userId, {bool force = false}) async {
    if (!force && _loadedFor == userId) return;

    if (_loadedFor != userId) {
      _unsubscribe();
      if (SupabaseConfig.isConfigured) {
        _channel = Supabase.instance.client
            .channel('messages-$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: _onNewMessage,
            )
            .subscribe();
      }
    }

    _loading = true;
    notifyListeners();
    _messages = await MessageService.loadForUser(userId);
    _loadedFor = userId;
    _loading = false;
    notifyListeners();
  }

  void _onNewMessage(PostgresChangePayload payload) {
    if (_disposed) return;
    try {
      final newMsg = Message.fromJson(
          Map<String, dynamic>.from(payload.newRecord as Map));
      if (newMsg.id.isEmpty) return;
      if (_messages.any((m) => m.id == newMsg.id)) return;
      _messages = [..._messages, newMsg];
      if (!newMsg.isFromUser) {
        _unseenCount++;
      }
      notifyListeners();
    } catch (e) {
      print('MessageProvider._onNewMessage: $e');
    }
  }

  Future<void> sendMessage({
    required String userId,
    required String userName,
    required String content,
  }) async {
    await MessageService.sendMessage(
      userId: userId,
      userName: userName,
      content: content,
    );
    // Full reload as fallback in case realtime doesn't fire for the sender
    final msgs = await MessageService.loadForUser(userId);
    if (_disposed) return;
    _messages = msgs;
    notifyListeners();
  }

  void markSeen() {
    if (_unseenCount == 0) return;
    _unseenCount = 0;
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
    _messages = [];
    _loadedFor = null;
    _unseenCount = 0;
    notifyListeners();
  }
}
