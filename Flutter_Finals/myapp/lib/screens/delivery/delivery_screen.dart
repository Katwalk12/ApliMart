// ignore_for_file: avoid_print
//
// ── Supabase migration required ───────────────────────────────────────────────
// Run once in Supabase SQL Editor:
//
//   alter table orders
//     add column if not exists rider_id uuid references auth.users(id);
//
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  RealtimeChannel? _channel;

  List<Map<String, dynamic>> _available = [];
  List<Map<String, dynamic>> _active = [];
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
    _subscribe();
  }

  void _subscribe() {
    if (!SupabaseConfig.isConfigured) return;
    _channel = Supabase.instance.client
        .channel('delivery-orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) {
            if (mounted && _busy.isEmpty) _load();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _tabs.dispose();
    if (_channel != null && SupabaseConfig.isConfigured) {
      try { Supabase.instance.client.removeChannel(_channel!); } catch (_) {}
    }
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    if (!SupabaseConfig.isConfigured) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (!mounted) return;
    setState(() => _loading = true);
    final riderId = context.read<AuthProvider>().user?.id ?? '';
    try {
      final db = Supabase.instance.client;

      // Orders approved by admin, not yet claimed by any rider
      final avail = await db
          .from('orders')
          .select(
              'id, total_amount, status, created_at, address, user_id, rider_id')
          .eq('status', 'processing')
          .filter('rider_id', 'is', null)
          .order('created_at', ascending: true)
          .limit(50);

      // Orders this rider has accepted (in-progress)
      final active = await db
          .from('orders')
          .select(
              'id, total_amount, status, created_at, address, user_id, rider_id')
          .eq('rider_id', riderId)
          .inFilter('status', ['picked_up', 'shipped'])
          .order('created_at', ascending: false)
          .limit(50);

      // Completed deliveries by this rider
      final hist = await db
          .from('orders')
          .select(
              'id, total_amount, status, created_at, address, user_id, rider_id')
          .eq('rider_id', riderId)
          .eq('status', 'delivered')
          .order('created_at', ascending: false)
          .limit(30);

      if (mounted) {
        setState(() {
          _available = List<Map<String, dynamic>>.from(avail as List);
          _active = List<Map<String, dynamic>>.from(active as List);
          _history = List<Map<String, dynamic>>.from(hist as List);
          _loading = false;
        });
      }
    } catch (e) {
      print('DeliveryScreen._load: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    final orderId = order['id']?.toString() ?? '';
    final userId = order['user_id']?.toString() ?? '';
    final riderId = context.read<AuthProvider>().user?.id ?? '';
    final shortId = _shortId(orderId);

    setState(() => _busy.add(orderId));
    try {
      await Supabase.instance.client.from('orders').update({
        'status': 'picked_up',
        'rider_id': riderId,
      }).eq('id', orderId);

      await NotificationService.notifyUser(
        userId: userId,
        orderId: orderId,
        orderNumber: shortId,
        type: NotifType.orderPickedUp,
      );

      await _load();
      if (mounted) _tabs.animateTo(1);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy.remove(orderId));
    }
  }

  Future<void> _markOnTheWay(Map<String, dynamic> order) async {
    final orderId = order['id']?.toString() ?? '';
    final userId = order['user_id']?.toString() ?? '';
    final shortId = _shortId(orderId);

    setState(() => _busy.add(orderId));
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': 'shipped'})
          .eq('id', orderId);

      await NotificationService.notifyUser(
        userId: userId,
        orderId: orderId,
        orderNumber: shortId,
        type: NotifType.orderOnTheWay,
      );

      await _load();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy.remove(orderId));
    }
  }

  Future<void> _markDelivered(Map<String, dynamic> order) async {
    final orderId = order['id']?.toString() ?? '';
    final userId = order['user_id']?.toString() ?? '';
    final shortId = _shortId(orderId);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Confirm Delivery'),
        content:
            Text('Mark order $shortId as delivered to the customer?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white),
            child: const Text('Yes, Delivered'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy.add(orderId));
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': 'delivered'})
          .eq('id', orderId);

      await NotificationService.notifyUser(
        userId: userId,
        orderId: orderId,
        orderNumber: shortId,
        type: NotifType.orderDelivered,
      );

      await _load();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy.remove(orderId));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.navyBlue, AppColors.darkBlue]),
          ),
        ),
        title: const Text('Delivery Dashboard',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.skyBlue,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              icon: const Icon(Icons.inventory_2_outlined, size: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Available'),
                  if (_available.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.saleOrange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${_available.length}',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              icon: const Icon(Icons.local_shipping_outlined, size: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Active'),
                  if (_active.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF29B6F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${_active.length}',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(
              icon: Icon(Icons.check_circle_outline, size: 18),
              text: 'History',
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : TabBarView(
              controller: _tabs,
              children: [
                _OrderList(
                  orders: _available,
                  emptyIcon: Icons.inbox_outlined,
                  emptyText: 'No orders available for pickup',
                  emptySubtext: 'Check back soon for new deliveries',
                  onRefresh: _load,
                  itemBuilder: (order) => _AvailableCard(
                    order: order,
                    busy: _busy.contains(order['id']?.toString() ?? ''),
                    onAccept: () => _acceptOrder(order),
                  ),
                ),
                _OrderList(
                  orders: _active,
                  emptyIcon: Icons.local_shipping_outlined,
                  emptyText: 'No active deliveries',
                  emptySubtext: 'Accept an order from the Available tab',
                  onRefresh: _load,
                  itemBuilder: (order) => _ActiveCard(
                    order: order,
                    busy: _busy.contains(order['id']?.toString() ?? ''),
                    onMarkOnTheWay: () => _markOnTheWay(order),
                    onMarkDelivered: () => _markDelivered(order),
                  ),
                ),
                _OrderList(
                  orders: _history,
                  emptyIcon: Icons.history,
                  emptyText: 'No delivery history yet',
                  emptySubtext: 'Completed deliveries will appear here',
                  onRefresh: _load,
                  itemBuilder: (order) => _HistoryCard(order: order),
                ),
              ],
            ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _shortId(String id) =>
      id.length >= 8 ? 'APM-${id.replaceAll('-', '').substring(0, 8).toUpperCase()}' : id;

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Error: $e'),
      backgroundColor: AppColors.red,
    ));
  }
}

// ── Generic order list ────────────────────────────────────────────────────────

class _OrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final IconData emptyIcon;
  final String emptyText;
  final String emptySubtext;
  final Future<void> Function() onRefresh;
  final Widget Function(Map<String, dynamic>) itemBuilder;

  const _OrderList({
    required this.orders,
    required this.emptyIcon,
    required this.emptyText,
    required this.emptySubtext,
    required this.onRefresh,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.primaryBlue,
        child: ListView(
          children: [
            SizedBox(
              height: 340,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(emptyIcon, size: 52, color: AppColors.lightBlue),
                  const SizedBox(height: 14),
                  Text(emptyText,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGrey)),
                  const SizedBox(height: 6),
                  Text(emptySubtext,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.grey)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryBlue,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => itemBuilder(orders[i]),
      ),
    );
  }
}

// ── Available order card ──────────────────────────────────────────────────────

class _AvailableCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool busy;
  final VoidCallback onAccept;

  const _AvailableCard(
      {required this.order, required this.busy, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final orderId = order['id']?.toString() ?? '';
    final shortId = orderId.length >= 8
        ? 'APM-${orderId.replaceAll('-', '').substring(0, 8).toUpperCase()}'
        : orderId;
    final amount = (order['total_amount'] as num?)?.toDouble() ?? 0;
    final date = DateTime.tryParse(order['created_at']?.toString() ?? '');
    final address = order['address']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    color: AppColors.primaryBlue, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shortId,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.darkGrey)),
                    if (date != null)
                      Text(
                          '${date.day}/${date.month}/${date.year}  •  ${_pad(date.hour)}:${_pad(date.minute)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.grey)),
                  ],
                ),
              ),
              Text('₱${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                      fontSize: 14)),
            ],
          ),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(address,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.darkGrey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          busy
              ? const Center(
                  child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryBlue)))
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.delivery_dining, size: 18),
                    label: const Text('Accept & Pick Up'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

// ── Active delivery card ──────────────────────────────────────────────────────

class _ActiveCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool busy;
  final VoidCallback onMarkOnTheWay;
  final VoidCallback onMarkDelivered;

  const _ActiveCard({
    required this.order,
    required this.busy,
    required this.onMarkOnTheWay,
    required this.onMarkDelivered,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString() ?? '';
    final orderId = order['id']?.toString() ?? '';
    final shortId = orderId.length >= 8
        ? 'APM-${orderId.replaceAll('-', '').substring(0, 8).toUpperCase()}'
        : orderId;
    final amount = (order['total_amount'] as num?)?.toDouble() ?? 0;
    final address = order['address']?.toString() ?? '';

    final isPickedUp = status == 'picked_up';
    final statusColor =
        isPickedUp ? const Color(0xFFFF9800) : const Color(0xFF29B6F6);
    final statusLabel = isPickedUp ? 'Picked Up' : 'On the Way';
    final statusIcon = isPickedUp
        ? Icons.inventory_2_outlined
        : Icons.local_shipping_outlined;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shortId,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.darkGrey)),
                    Text('₱${amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.primaryBlue)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(address,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.darkGrey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (busy)
            const Center(
              child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primaryBlue)),
            )
          else if (isPickedUp)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onMarkOnTheWay,
                icon: const Icon(Icons.local_shipping_outlined, size: 18),
                label: const Text('Mark On the Way'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF29B6F6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 42),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onMarkDelivered,
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Mark Delivered'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 42),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── History card ──────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _HistoryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final orderId = order['id']?.toString() ?? '';
    final shortId = orderId.length >= 8
        ? 'APM-${orderId.replaceAll('-', '').substring(0, 8).toUpperCase()}'
        : orderId;
    final amount = (order['total_amount'] as num?)?.toDouble() ?? 0;
    final date = DateTime.tryParse(order['created_at']?.toString() ?? '');
    final address = order['address']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shortId,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.darkGrey)),
                if (date != null)
                  Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.grey)),
                if (address.isNotEmpty)
                  Text(address,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₱${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.green,
                      fontSize: 13)),
              const Text('Delivered',
                  style: TextStyle(fontSize: 10, color: AppColors.green)),
            ],
          ),
        ],
      ),
    );
  }
}
