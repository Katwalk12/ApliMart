// ignore_for_file: avoid_print
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/message.dart';

class MessageService {
  static SupabaseClient get _db => Supabase.instance.client;
  static const _table = 'messages';

  // ── User: load their own conversation ────────────────────────────────────

  static Future<List<Message>> loadForUser(String userId) async {
    if (!SupabaseConfig.isConfigured) return [];
    try {
      final data = await _db
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true)
          .limit(100);
      return (data as List)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('MessageService.loadForUser: $e');
      return [];
    }
  }

  // ── User: send a message ──────────────────────────────────────────────────

  static Future<void> sendMessage({
    required String userId,
    required String userName,
    required String content,
  }) async {
    if (!SupabaseConfig.isConfigured) return;
    await _db.from(_table).insert({
      'user_id': userId,
      'user_name': userName,
      'sender': 'user',
      'content': content,
    });
  }

  // ── Admin: load all conversations (one entry per user, latest message) ───

  static Future<List<Map<String, dynamic>>> loadConversations() async {
    if (!SupabaseConfig.isConfigured) return [];
    try {
      final data = await _db
          .from(_table)
          .select('user_id, user_name, content, created_at, sender')
          .order('created_at', ascending: false)
          .limit(300);
      // Keep only the first (latest) message per user_id
      final Map<String, Map<String, dynamic>> seen = {};
      for (final row in (data as List)) {
        final uid = row['user_id']?.toString() ?? '';
        if (uid.isNotEmpty && !seen.containsKey(uid)) {
          seen[uid] = Map<String, dynamic>.from(row as Map);
        }
      }
      return seen.values.toList();
    } catch (e) {
      print('MessageService.loadConversations: $e');
      return [];
    }
  }

  // ── Admin: load full conversation for a user ──────────────────────────────

  static Future<List<Message>> loadConversationForUser(
      String userId) async {
    if (!SupabaseConfig.isConfigured) return [];
    try {
      final data = await _db
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true)
          .limit(100);
      return (data as List)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('MessageService.loadConversationForUser: $e');
      return [];
    }
  }

  // ── Admin: reply to a user ────────────────────────────────────────────────

  static Future<void> replyToUser({
    required String userId,
    required String userName,
    required String content,
  }) async {
    if (!SupabaseConfig.isConfigured) return;
    await _db.from(_table).insert({
      'user_id': userId,
      'user_name': userName,
      'sender': 'support',
      'content': content,
    });
  }
}
