// ignore_for_file: avoid_print
//
// ── Supabase table required ───────────────────────────────────────────────────
//
// Run once in Supabase SQL Editor:
//
// create table if not exists notifications (
//   id         uuid default gen_random_uuid() primary key,
//   user_id    uuid not null references auth.users(id) on delete cascade,
//   order_id   text not null default '',
//   type       text not null,
//   title      text not null,
//   body       text not null,
//   is_read    boolean not null default false,
//   created_at timestamptz default now()
// );
//
// alter table notifications enable row level security;
//
// create policy "users read own" on notifications
//   for select using (auth.uid() = user_id);
//
// create policy "service insert" on notifications
//   for insert with check (true);
//
// create policy "users mark read" on notifications
//   for update using (auth.uid() = user_id);

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/app_notification.dart';

class NotificationService {
  static SupabaseClient get _db => Supabase.instance.client;
  static const _table = 'notifications';

  // ── Notify a user of an order status change ───────────────────────────────

  static Future<void> notifyUser({
    required String userId,
    required String orderId,
    required String orderNumber,
    required NotifType type,
  }) async {
    if (!SupabaseConfig.isConfigured) return;
    final (title, body) = _copyFor(type, orderNumber);
    try {
      await _db.from(_table).insert({
        'user_id':  userId,
        'order_id': orderId,
        'type':     type.value,
        'title':    title,
        'body':     body,
        'is_read':  false,
      });
    } catch (e) {
      print('NotificationService.notifyUser: $e');
    }
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  static Future<List<AppNotification>> loadForUser(String userId) async {
    if (!SupabaseConfig.isConfigured) return [];
    try {
      final data = await _db
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(60);
      return (data as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('NotificationService.loadForUser: $e');
      return [];
    }
  }

  // ── Mark read ─────────────────────────────────────────────────────────────

  static Future<void> markAllRead(String userId) async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      await _db
          .from(_table)
          .update({'is_read': true})
          .eq('user_id', userId);
    } catch (_) {}
  }

  static Future<void> markOneRead(String notifId) async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      await _db
          .from(_table)
          .update({'is_read': true})
          .eq('id', notifId);
    } catch (_) {}
  }

  // ── Copy ──────────────────────────────────────────────────────────────────

  static (String title, String body) _copyFor(
      NotifType type, String orderNumber) {
    switch (type) {
      case NotifType.orderApproved:
        return (
          'Order Approved!',
          'Your order $orderNumber has been approved and is being prepared.',
        );
      case NotifType.orderPickedUp:
        return (
          'Rider Picked Up Your Order',
          'A rider has collected your items for order $orderNumber.',
        );
      case NotifType.orderOnTheWay:
        return (
          'Your Order is On the Way!',
          'Order $orderNumber is heading to your address. Get ready!',
        );
      case NotifType.orderDelivered:
        return (
          'Order Delivered!',
          'Order $orderNumber has been delivered. Enjoy your purchase!',
        );
      case NotifType.orderCancelled:
        return (
          'Order Cancelled',
          'Order $orderNumber has been cancelled.',
        );
      case NotifType.cancellationApproved:
        return (
          'Cancellation Approved',
          'Your cancellation request for order $orderNumber has been approved.',
        );
    }
  }
}
