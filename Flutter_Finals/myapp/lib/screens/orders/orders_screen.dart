import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  final OrderStatus? initialTab;
  const OrdersScreen({super.key, this.initialTab});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const _tabs = [
    (null,                    'All'),
    (OrderStatus.pending,     'Pending'),
    (OrderStatus.processing,  'Processing'),
    (OrderStatus.shipped,     'Shipped'),
    (OrderStatus.delivered,   'Delivered'),
  ];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final uid = context.read<AuthProvider>().user?.id;
    if (uid != null) {
      await context.read<OrderProvider>().loadFromSupabase(uid);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final initialIndex = widget.initialTab == null
        ? 0
        : _tabs.indexWhere((t) => t.$1 == widget.initialTab);

    return DefaultTabController(
      length: _tabs.length,
      initialIndex: initialIndex < 0 ? 0 : initialIndex,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppColors.navyBlue, AppColors.darkBlue]),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('My Orders',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _load,
              tooltip: 'Refresh',
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: AppColors.skyBlue,
            indicatorWeight: 3,
            tabs: _tabs.map((t) => Tab(text: t.$2)).toList(),
          ),
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryBlue))
            : TabBarView(
                children: _tabs
                    .map((t) => _OrderList(
                          status: t.$1,
                          onRefresh: _load,
                        ))
                    .toList(),
              ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final OrderStatus? status;
  final VoidCallback onRefresh;

  const _OrderList({this.status, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final all = context.watch<OrderProvider>().orders;
    final list = status == null
        ? all
        : all.where((o) => o.status == status).toList();

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                  color: AppColors.veryLightBlue, shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long_outlined,
                  size: 44, color: AppColors.lightBlue),
            ),
            const SizedBox(height: 16),
            const Text('No orders here',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.darkGrey)),
            const SizedBox(height: 6),
            const Text('Your orders will appear here',
                style: TextStyle(color: AppColors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.primaryBlue,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _OrderCard(order: list[i]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(order.orderNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.navyBlue)),
                const Spacer(),
                _statusBadge(),
              ],
            ),
            const SizedBox(height: 4),
            Text(_formatDate(order.createdAt),
                style:
                    const TextStyle(color: AppColors.grey, fontSize: 11)),
            const Divider(height: 14),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.veryLightBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.home_repair_service_rounded,
                      color: AppColors.lightBlue, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.items.isNotEmpty
                            ? order.items.first.productName
                            : '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      if (order.items.length > 1)
                        Text(
                          '+${order.items.length - 1} more item(s)',
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${order.itemCount} item(s)',
                    style: const TextStyle(
                        color: AppColors.grey, fontSize: 12)),
                Text(order.formattedTotal,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.primaryBlue)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          OrderDetailScreen(order: order)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.navyBlue),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('View Details',
                    style: TextStyle(
                        color: AppColors.navyBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: order.status.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: order.status.color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(order.status.icon,
                color: order.status.color, size: 12),
            const SizedBox(width: 4),
            Text(order.status.label,
                style: TextStyle(
                    color: order.status.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11)),
          ],
        ),
      );

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
