import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

class OrderProvider extends ChangeNotifier {
  String? _userId;
  final List<Order> _orders = [];
  RealtimeChannel? _channel;
  bool _disposed = false;

  OrderProvider();

  @override
  void dispose() {
    _disposed = true;
    _unsubscribe();
    super.dispose();
  }

  List<Order> get orders => List.unmodifiable(_orders);

  List<Order> byStatus(OrderStatus status) =>
      _orders.where((o) => o.status == status).toList();

  int get pendingCount =>
      _orders.where((o) => o.status == OrderStatus.pending).length;

  // ── Per-user local storage key ─────────────────────────────────────────────

  static String _key(String userId) => 'orders_v2_$userId';

  Future<void> _loadLocalForUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw != null && !_disposed) {
        final list = jsonDecode(raw) as List;
        _orders.addAll(
            list.map((o) => Order.fromJson(o as Map<String, dynamic>)));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveLocal() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key(uid), jsonEncode(_orders.map((o) => o.toJson()).toList()));
    } catch (_) {}
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Clears all in-memory orders and cancels real-time subscription.
  void clear() {
    _unsubscribe();
    if (_userId != null) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(_key(_userId!), '[]');
      });
    }
    _orders.clear();
    _userId = null;
    notifyListeners();
  }

  void _unsubscribe() {
    if (_channel != null && SupabaseConfig.isConfigured) {
      try { Supabase.instance.client.removeChannel(_channel!); } catch (_) {}
      _channel = null;
    }
  }

  /// Load orders for [userId] from Supabase, scoped strictly to that user.
  /// Starts a real-time subscription so admin status changes push instantly.
  Future<void> loadFromSupabase(String userId) async {
    if (_userId != userId) {
      _unsubscribe();
      _orders.clear();
      _userId = userId;
      await _loadLocalForUser(userId);
      notifyListeners();

      // Real-time: re-sync whenever any of this user's orders change
      if (SupabaseConfig.isConfigured) {
        _channel = Supabase.instance.client
            .channel('orders-$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'orders',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (_) => _syncFromServer(userId),
            )
            .subscribe();
      }
    }

    await _syncFromServer(userId);
  }

  Future<void> _syncFromServer(String userId) async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final data = await Supabase.instance.client
          .from('orders')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (_disposed || _userId != userId) return;

      final serverOrders =
          (data as List).map((o) => Order.fromSupabaseJson(o)).toList();
      final serverIds = serverOrders.map((o) => o.id).toSet();

      final localOnly =
          _orders.where((o) => !serverIds.contains(o.id)).toList();

      _orders
        ..clear()
        ..addAll(serverOrders)
        ..addAll(localOnly);
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      notifyListeners();
      await _saveLocal();
    } catch (_) {}
  }

  // ── UUID v4 helper ─────────────────────────────────────────────────────────

  static String _uuid() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20, 32)}';
  }

  /// Submits a cancellation request for any active order.
  /// All cancellations (pending or processing) become [cancelRequested] and
  /// must be reviewed and approved by the admin before the order is cancelled.
  Future<Order?> cancelOrder(String orderId, {String? reason}) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return null;

    final old = _orders[idx];
    const newStatus = OrderStatus.cancelRequested;

    final updated = Order(
      id: old.id,
      items: old.items,
      subtotal: old.subtotal,
      shippingFee: old.shippingFee,
      vatAmount: old.vatAmount,
      serviceFee: old.serviceFee,
      status: newStatus,
      address: old.address,
      paymentMethod: old.paymentMethod,
      createdAt: old.createdAt,
      cancellationReason: reason,
    );
    _orders[idx] = updated;
    notifyListeners();
    await _saveLocal();

    if (SupabaseConfig.isConfigured) {
      try {
        final payload = <String, dynamic>{
          'status': newStatus.supabaseValue,
        };
        if (reason != null && reason.isNotEmpty) {
          payload['cancellation_reason'] = reason;
        }
        await Supabase.instance.client
            .from('orders')
            .update(payload)
            .eq('id', orderId);
      } catch (_) {}
    }
    return updated;
  }

  Order placeOrder({
    required List<CartItem> cartItems,
    required String address,
    required String paymentMethod,
    double shippingFee = 150,
    double vatAmount = 0,
  }) {
    final id = _uuid();
    final sub = cartItems.fold<double>(0, (s, ci) => s + ci.subtotal);
    final order = Order(
      id: id,
      items: cartItems
          .map((ci) => OrderItem(
                productId: ci.productId,
                productName: ci.product.name,
                imageUrl: ci.product.imageUrl,
                price: ci.product.price,
                quantity: ci.quantity,
              ))
          .toList(),
      subtotal: sub,
      shippingFee: shippingFee,
      vatAmount: vatAmount,
      status: OrderStatus.pending,
      address: address,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
    );
    _orders.insert(0, order);
    _saveLocal();
    notifyListeners();
    return order;
  }
}
