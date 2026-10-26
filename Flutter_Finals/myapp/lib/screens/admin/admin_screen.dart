import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../models/app_notification.dart';
import '../../models/message.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../services/message_service.dart';
import '../../services/notification_service.dart';
import '../../services/product_service.dart';
import '../../services/rider_account_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.navyBlue, AppColors.darkBlue]),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Admin Dashboard',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.skyBlue,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tooltip(message: 'Dashboard', child: Tab(icon: Icon(Icons.dashboard_outlined, size: 22))),
            Tooltip(message: 'Products',  child: Tab(icon: Icon(Icons.inventory_2_outlined, size: 22))),
            Tooltip(message: 'Orders',    child: Tab(icon: Icon(Icons.receipt_long_outlined, size: 22))),
            Tooltip(message: 'Riders',    child: Tab(icon: Icon(Icons.delivery_dining, size: 22))),
            Tooltip(message: 'Messages',  child: Tab(icon: Icon(Icons.chat_outlined, size: 22))),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _DashboardTab(),
          _ProductsTab(),
          _OrdersTab(),
          _RidersTab(),
          _AdminMessagesTab(),
        ],
      ),
    );
  }
}

// ── Dashboard ─────────────────────────────────────────────────────────────────

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  int _productCount = 0;
  int _orderCount = 0;
  double _totalRevenue = 0;
  int _riderCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (SupabaseConfig.isConfigured) {
        final db = Supabase.instance.client;
        final products = await db.from('products').select('id');
        final orders =
            await db.from('orders').select('id, total_amount');
        final riders = await db.from('riders').select('user_id');
        _productCount = (products as List).length;
        _orderCount = (orders as List).length;
        _totalRevenue = (orders as List).fold(
            0.0,
            (s, o) =>
                s + ((o['total_amount'] as num?)?.toDouble() ?? 0));
        _riderCount = (riders as List).length;
      } else {
        final prods = await ProductService.getProducts();
        _productCount = prods.length;
        _orderCount = 0;
        _totalRevenue = 0;
      }
    } catch (_) {
      final prods = await ProductService.getProducts();
      _productCount = prods.length;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue));
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryBlue,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _banner(),
          const SizedBox(height: 20),
          _statGrid(),
          const SizedBox(height: 20),
          _quickActions(context),
          const SizedBox(height: 20),
          _supabaseNote(),
        ],
      ),
    );
  }

  Widget _banner() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.navyBlue, AppColors.primaryBlue]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white24,
              child: Icon(Icons.admin_panel_settings,
                  color: Colors.white, size: 28),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, Admin',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('ApliMart Control Panel',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ],
        ),
      );

  Widget _statGrid() => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          _statCard('Products', '$_productCount',
              Icons.inventory_2_outlined, AppColors.primaryBlue),
          _statCard('Orders', '$_orderCount',
              Icons.receipt_long_outlined, AppColors.skyBlue),
          _statCard(
              'Revenue',
              '₱${_fmt(_totalRevenue)}',
              Icons.payments_outlined,
              AppColors.green),
          _statCard('Riders', '$_riderCount', Icons.delivery_dining,
              AppColors.navyBlue),
        ],
      );

  String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    final start = s.length % 3;
    if (start > 0) buf.write(s.substring(0, start));
    for (int i = start; i < s.length; i += 3) {
      if (i > 0) buf.write(',');
      buf.write(s.substring(i, i + 3));
    }
    return buf.toString();
  }

  Widget _statCard(
          String label, String value, IconData icon, Color color) =>
      Container(
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.grey)),
              ],
            ),
          ],
        ),
      );

  Widget _quickActions(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyBlue)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                    Icons.add_box_outlined,
                    'Add Product',
                    AppColors.primaryBlue,
                    () => _showProductSheet(context, null, _load)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionBtn(
                    Icons.refresh_outlined,
                    'Refresh Stats',
                    AppColors.skyBlue,
                    _load),
              ),
            ],
          ),
        ],
      );

  Widget _actionBtn(
          IconData icon, String label, Color color, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
        ),
      );

  Widget _supabaseNote() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.veryLightBlue,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.lightBlue.withValues(alpha: 0.5)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline,
                color: AppColors.primaryBlue, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Admin access: Supabase → Auth → Users → Edit user → '
                'raw_user_meta_data: {"is_admin": true}',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.darkGrey,
                    height: 1.5),
              ),
            ),
          ],
        ),
      );
}

// ── Products Tab ──────────────────────────────────────────────────────────────

class _ProductsTab extends StatefulWidget {
  const _ProductsTab();

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  List<Product> _products = [];
  List<Product> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ProductService.getProducts();
    if (mounted) {
      setState(() {
        _products = data;
        _filtered = data;
        _loading = false;
      });
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _products
          : _products
              .where((p) =>
                  p.name.toLowerCase().contains(q) ||
                  p.category.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductSheet(context, null, _load),
        backgroundColor: AppColors.navyBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primaryBlue))
          : Column(
              children: [
                // Search bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            hintStyle:
                                const TextStyle(color: AppColors.grey),
                            prefixIcon: const Icon(Icons.search,
                                color: AppColors.grey, size: 20),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear,
                                        color: AppColors.grey, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      _filter();
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.primaryBlue),
                            ),
                            filled: true,
                            fillColor: AppColors.offWhite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Count row
                if (_products.isNotEmpty)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: Row(
                      children: [
                        Text(
                          _searchCtrl.text.isEmpty
                              ? '${_products.length} product${_products.length == 1 ? '' : 's'}'
                              : '${_filtered.length} of ${_products.length}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.grey),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 1),
                // List
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inventory_2_outlined,
                                  size: 48, color: AppColors.lightBlue),
                              const SizedBox(height: 12),
                              Text(
                                _products.isEmpty
                                    ? 'No products yet'
                                    : 'No results for "${_searchCtrl.text}"',
                                style: const TextStyle(
                                    color: AppColors.grey),
                              ),
                              if (_products.isEmpty) ...[
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _showProductSheet(
                                      context, null, _load),
                                  icon: const Icon(Icons.add),
                                  label:
                                      const Text('Add First Product'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppColors.navyBlue,
                                      foregroundColor: Colors.white),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.primaryBlue,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                                12, 12, 12, 80),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) => _ProductTile(
                              product: _filtered[i],
                              onRefresh: _load,
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onRefresh;

  const _ProductTile({required this.product, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final hasImage = product.imageUrl.isNotEmpty &&
        !product.imageUrl.contains('picsum');
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 54,
            height: 54,
            child: hasImage
                ? Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _tileIcon(),
                  )
                : _tileIcon(),
          ),
        ),
        title: Text(product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.darkGrey)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${product.formattedPrice}  •  ${product.category}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.primaryBlue),
            ),
            Row(
              children: [
                Text(
                  'Stock: ${product.stock}  •  Sold: ${product.soldCount}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.grey),
                ),
                if (product.reviewCount > 0) ...[
                  const Text('  •  ',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.grey)),
                  const Icon(Icons.star_rounded,
                      size: 12, color: Colors.amber),
                  Text(
                    ' ${product.rating.toStringAsFixed(1)}'
                    ' (${product.reviewCount})',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.grey),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (product.reviewCount > 0)
              IconButton(
                icon: const Icon(Icons.reviews_outlined,
                    color: AppColors.navyBlue, size: 20),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20))),
                  builder: (_) =>
                      _AdminReviewsSheet(product: product),
                ),
                tooltip: 'Reviews',
              ),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.primaryBlue, size: 20),
              onPressed: () =>
                  _showProductSheet(context, product, onRefresh),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.red, size: 20),
              onPressed: () =>
                  _deleteProduct(context, product, onRefresh),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  Widget _tileIcon() => Container(
        color: AppColors.veryLightBlue,
        child: const Icon(Icons.home_repair_service_rounded,
            color: AppColors.lightBlue, size: 26),
      );
}

// ── Admin Reviews Sheet ───────────────────────────────────────────────────────

class _AdminReviewsSheet extends StatefulWidget {
  final Product product;
  const _AdminReviewsSheet({required this.product});

  @override
  State<_AdminReviewsSheet> createState() => _AdminReviewsSheetState();
}

class _AdminReviewsSheetState extends State<_AdminReviewsSheet> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ProductService.getReviews(widget.product.id);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGrey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star_rounded,
                        size: 16, color: Colors.amber[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.product.rating.toStringAsFixed(1)}'
                      ' / 5.0  •  ${widget.product.reviewCount} rating'
                      '${widget.product.reviewCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.grey),
                    ),
                  ],
                ),
                const Divider(height: 20),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.navyBlue));
                }
                final reviews = snap.data ?? [];
                if (reviews.isEmpty) {
                  return const Center(
                    child: Text('No ratings yet',
                        style: TextStyle(color: AppColors.grey)),
                  );
                }
                return ListView.separated(
                  controller: ctrl,
                  padding:
                      const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: reviews.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 20),
                  itemBuilder: (_, i) =>
                      _AdminReviewRow(review: reviews[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminReviewRow extends StatelessWidget {
  final Map<String, dynamic> review;
  const _AdminReviewRow({required this.review});

  @override
  Widget build(BuildContext context) {
    final name =
        review['reviewer_name']?.toString() ?? 'Anonymous';
    final text = review['review_text']?.toString() ?? '';
    final rating = (review['rating'] as num?)?.toDouble() ?? 0;
    final rawDate = review['created_at']?.toString();
    final date =
        rawDate != null ? DateTime.tryParse(rawDate) : null;
    final dateStr = date != null
        ? '${date.day} ${_month(date.month)} ${date.year}'
        : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor:
              AppColors.navyBlue.withValues(alpha: 0.12),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.navyBlue,
                fontSize: 14),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.darkGrey)),
                  ),
                  if (dateStr.isNotEmpty)
                    Text(dateStr,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.grey)),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 14,
                    color: Colors.amber[600],
                  );
                }),
              ),
              if (text.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(text,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.darkGrey,
                        height: 1.5)),
              ] else ...[
                const SizedBox(height: 4),
                const Text('No comment',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                        fontStyle: FontStyle.italic)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

// ── Orders Tab ────────────────────────────────────────────────────────────────

class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  final Set<String> _busy = {};
  Map<String, String> _riderNames = {};
  RealtimeChannel? _ordersChannel;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeToOrders();
  }

  void _subscribeToOrders() {
    if (!SupabaseConfig.isConfigured) return;
    _ordersChannel = Supabase.instance.client
        .channel('admin-orders-watch')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) {
            if (mounted) _load();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_ordersChannel != null && SupabaseConfig.isConfigured) {
      try {
        Supabase.instance.client.removeChannel(_ordersChannel!);
      } catch (_) {}
      _ordersChannel = null;
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (SupabaseConfig.isConfigured) {
        final db = Supabase.instance.client;
        final data = await db
            .from('orders')
            .select(
                'id, total_amount, status, created_at, address, payment_method, user_id, rider_id, items, cancellation_reason')
            .order('created_at', ascending: false)
            .limit(100);
        _orders = List<Map<String, dynamic>>.from(data as List);
        // Build rider name lookup map
        final ridersData = await db
            .from('riders')
            .select('user_id, name');
        _riderNames = {
          for (final r in ridersData as List)
            r['user_id'].toString(): r['name']?.toString() ?? 'Rider',
        };
      } else {
        _orders = [];
        _riderNames = {};
      }
    } catch (e) {
      debugPrint('AdminOrders._load error: $e');
      _orders = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  // ── Status action with notification ──────────────────────────────────────

  Future<void> _doAction(
    Map<String, dynamic> order,
    String newStatus,
    NotifType? notifType,
  ) async {
    final orderId = order['id']?.toString() ?? '';
    final userId = order['user_id']?.toString();
    final shortId = orderId.length >= 8
        ? 'APM-${orderId.replaceAll('-', '').substring(0, 8).toUpperCase()}'
        : orderId;

    if (!SupabaseConfig.isConfigured) return;
    setState(() => _busy.add(orderId));
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

      if (notifType != null && userId != null && userId.isNotEmpty) {
        await NotificationService.notifyUser(
          userId: userId,
          orderId: orderId,
          orderNumber: shortId,
          type: notifType,
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 3),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(orderId));
    }
  }

  Future<void> _cancelOrder(Map<String, dynamic> order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Cancel Order'),
        content: const Text('Cancel this order and notify the customer?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _doAction(order, 'cancelled', NotifType.orderCancelled);
    }
  }

  Future<void> _acceptCancellation(Map<String, dynamic> order) async {
    final orderId = order['id']?.toString() ?? '';
    final userId = order['user_id']?.toString();
    final shortId = orderId.length >= 8
        ? 'APM-${orderId.replaceAll('-', '').substring(0, 8).toUpperCase()}'
        : orderId;
    final rawItems = order['items'];
    final itemsList = rawItems is List ? rawItems : [];

    if (!SupabaseConfig.isConfigured) return;
    setState(() => _busy.add(orderId));
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': 'cancelled'})
          .eq('id', orderId);

      // Restore stock and decrement sold_count for each cancelled item.
      // Reads fresh DB values to avoid stale in-memory data.
      for (final raw in itemsList) {
        try {
          final item = raw as Map<String, dynamic>;
          final productId = item['product_id']?.toString() ?? '';
          final qty = (item['quantity'] as num?)?.toInt() ?? 1;
          if (productId.isEmpty) continue;
          final pData = await Supabase.instance.client
              .from('products')
              .select('stock, sold_count')
              .eq('id', productId)
              .maybeSingle();
          if (pData == null) continue;
          final oldStock = (pData['stock'] as num?)?.toInt() ?? 0;
          final oldSold = (pData['sold_count'] as num?)?.toInt() ?? 0;
          await Supabase.instance.client.from('products').update({
            'stock': oldStock + qty,
            'sold_count': (oldSold - qty).clamp(0, oldSold),
          }).eq('id', productId);
        } catch (_) {}
      }

      if (userId != null && userId.isNotEmpty) {
        await NotificationService.notifyUser(
          userId: userId,
          orderId: orderId,
          orderNumber: shortId,
          type: NotifType.cancellationApproved,
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 3),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(orderId));
    }
  }

  void _showOrderDetail(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdminOrderDetailSheet(
        order: order,
        riderNames: _riderNames,
        busy: _busy.contains(order['id']?.toString() ?? ''),
        onDoAction: _doAction,
        onCancel: _cancelOrder,
        onAssignRider: _assignRider,
        onAcceptCancellation: _acceptCancellation,
      ),
    ).then((_) => setState(() {}));
  }

  Future<void> _assignRider(Map<String, dynamic> order) async {
    final orderId = order['id']?.toString() ?? '';
    final currentRiderId = order['rider_id']?.toString();

    final picked = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (_) => _RiderPickerDialog(currentRiderId: currentRiderId),
    );

    if (picked == null || !mounted) return;

    setState(() => _busy.add(orderId));
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'rider_id': picked['user_id']})
          .eq('id', orderId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 3),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(orderId));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue));
    }
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 48, color: AppColors.lightBlue),
            const SizedBox(height: 12),
            Text(
              SupabaseConfig.isConfigured
                  ? 'No orders yet'
                  : 'Connect Supabase to see orders',
              style: const TextStyle(color: AppColors.grey),
            ),
          ],
        ),
      );
    }
    final cancelPending =
        _orders.where((o) => o['status'] == 'cancel_requested').toList();

    return Column(
      children: [
        if (cancelPending.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFF8F00), width: 1.4),
            ),
            child: Row(
              children: [
                const Icon(Icons.pending_actions_outlined,
                    color: Color(0xFFFF8F00), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cancelPending.length == 1
                        ? '1 order is awaiting cancellation approval'
                        : '${cancelPending.length} orders are awaiting cancellation approval',
                    style: const TextStyle(
                      color: Color(0xFFE65100),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppColors.primaryBlue,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _OrderCard(
                order: _orders[i],
                riderNames: _riderNames,
                busy: _busy.contains(_orders[i]['id']?.toString() ?? ''),
                onDoAction: _doAction,
                onCancel: _cancelOrder,
                onAssignRider: _assignRider,
                onAcceptCancellation: _acceptCancellation,
                onTap: () => _showOrderDetail(_orders[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Order card ────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Map<String, String> riderNames;
  final bool busy;
  final Future<void> Function(
      Map<String, dynamic>, String, NotifType?) onDoAction;
  final Future<void> Function(Map<String, dynamic>) onCancel;
  final Future<void> Function(Map<String, dynamic>) onAssignRider;
  final Future<void> Function(Map<String, dynamic>) onAcceptCancellation;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.riderNames,
    required this.busy,
    required this.onDoAction,
    required this.onCancel,
    required this.onAssignRider,
    required this.onAcceptCancellation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString() ?? 'pending';
    final amount = (order['total_amount'] as num?)?.toDouble() ?? 0;
    final date =
        DateTime.tryParse(order['created_at']?.toString() ?? '');
    final orderId = order['id']?.toString() ?? '-';
    final shortId = orderId.length >= 8
        ? 'APM-${orderId.replaceAll('-', '').substring(0, 8).toUpperCase()}'
        : orderId;
    final statusColor = _statusColor(status);
    final riderId = order['rider_id']?.toString();
    final riderName = riderId != null ? riderNames[riderId] : null;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_statusIcon(status),
                    color: statusColor, size: 18),
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
                        '${date.day}/${date.month}/${date.year}  •  '
                        '${_pad(date.hour)}:${_pad(date.minute)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.grey),
                      ),
                  ],
                ),
              ),
              Text(
                '₱${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                    fontSize: 14),
              ),
            ],
          ),

          // ── Address ───────────────────────────────────────────────
          if ((order['address']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: AppColors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order['address']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.grey),
                  ),
                ),
              ],
            ),
          ],

          // ── Assigned rider ────────────────────────────────────────
          if (riderName != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.delivery_dining_outlined,
                    size: 13, color: AppColors.primaryBlue),
                const SizedBox(width: 4),
                Text(
                  'Rider: $riderName',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),

          // ── Status badge ──────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              _statusLabel(status),
              style: TextStyle(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.bold),
            ),
          ),

          // ── Cancel-requested quick-action ─────────────────────────
          if (status == 'cancel_requested') ...[
            const SizedBox(height: 10),
            if (busy)
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primaryBlue),
                ),
              )
            else
              _btn(
                label: 'Accept Cancellation',
                icon: Icons.check_circle_outline,
                color: AppColors.red,
                onTap: () => onAcceptCancellation(order),
              ),
          ],

          // ── Action buttons ────────────────────────────────────────
          if (status != 'delivered' && status != 'cancelled' && status != 'cancel_requested') ...[
            const SizedBox(height: 10),
            if (busy)
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primaryBlue),
                ),
              )
            else
              _actionButtons(status, order),
          ],
        ],
      ),
        ),
      ),
    );
  }

  Widget _actionButtons(String status, Map<String, dynamic> order) {
    switch (status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: _btn(
                label: 'Approve Order',
                icon: Icons.check_circle_outline,
                color: AppColors.green,
                onTap: () => onDoAction(
                    order, 'processing', NotifType.orderApproved),
              ),
            ),
            const SizedBox(width: 8),
            _iconBtn(
              icon: Icons.cancel_outlined,
              color: AppColors.red,
              tooltip: 'Cancel',
              onTap: () => onCancel(order),
            ),
          ],
        );

      case 'processing':
        final hasRider = order['rider_id'] != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _btn(
              label: hasRider ? 'Change Rider' : 'Assign Rider',
              icon: Icons.person_pin_circle_outlined,
              color: AppColors.navyBlue,
              onTap: () => onAssignRider(order),
            ),
            const SizedBox(height: 8),
            if (hasRider)
              _btn(
                label: 'Mark Picked Up',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFFFF9800),
                onTap: () => onDoAction(
                    order, 'picked_up', NotifType.orderPickedUp),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.offWhite,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline,
                        size: 13, color: AppColors.grey),
                    SizedBox(width: 4),
                    Text('Assign a rider first',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.grey)),
                  ],
                ),
              ),
          ],
        );

      case 'picked_up':
        return _btn(
          label: 'Mark On the Way',
          icon: Icons.local_shipping_outlined,
          color: const Color(0xFF29B6F6),
          onTap: () =>
              onDoAction(order, 'shipped', NotifType.orderOnTheWay),
        );

      case 'shipped':
        return _btn(
          label: 'Mark Delivered',
          icon: Icons.check_circle_rounded,
          color: AppColors.green,
          onTap: () =>
              onDoAction(order, 'delivered', NotifType.orderDelivered),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _btn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Material(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) =>
      Tooltip(
        message: tooltip,
        child: Material(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Icon(icon, size: 18, color: color),
            ),
          ),
        ),
      );

  String _pad(int n) => n.toString().padLeft(2, '0');

  Color _statusColor(String s) {
    switch (s) {
      case 'delivered':        return const Color(0xFF43A047);
      case 'processing':       return const Color(0xFF1976D2);
      case 'picked_up':        return const Color(0xFFFF9800);
      case 'shipped':          return const Color(0xFF29B6F6);
      case 'cancelled':        return const Color(0xFFE53935);
      case 'cancel_requested': return const Color(0xFFFF8F00);
      default:                 return const Color(0xFFFF6B2B);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'delivered':        return Icons.check_circle_outline_rounded;
      case 'processing':       return Icons.check_circle_outline;
      case 'picked_up':        return Icons.inventory_2_outlined;
      case 'shipped':          return Icons.local_shipping_outlined;
      case 'cancelled':        return Icons.cancel_outlined;
      case 'cancel_requested': return Icons.pending_actions_outlined;
      default:                 return Icons.hourglass_empty_rounded;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'delivered':        return 'Delivered';
      case 'processing':       return 'Approved';
      case 'picked_up':        return 'Picked Up';
      case 'shipped':          return 'On the Way';
      case 'cancelled':        return 'Cancelled';
      case 'cancel_requested': return 'Cancel Requested';
      default:                 return 'Pending';
    }
  }
}

// ── Admin Order Detail Sheet ──────────────────────────────────────────────────

class _AdminOrderDetailSheet extends StatelessWidget {
  final Map<String, dynamic> order;
  final Map<String, String> riderNames;
  final bool busy;
  final Future<void> Function(Map<String, dynamic>, String, NotifType?)
      onDoAction;
  final Future<void> Function(Map<String, dynamic>) onCancel;
  final Future<void> Function(Map<String, dynamic>) onAssignRider;
  final Future<void> Function(Map<String, dynamic>) onAcceptCancellation;

  const _AdminOrderDetailSheet({
    required this.order,
    required this.riderNames,
    required this.busy,
    required this.onDoAction,
    required this.onCancel,
    required this.onAssignRider,
    required this.onAcceptCancellation,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString() ?? 'pending';
    final amount = (order['total_amount'] as num?)?.toDouble() ?? 0;
    final date = DateTime.tryParse(order['created_at']?.toString() ?? '');
    final orderId = order['id']?.toString() ?? '-';
    final shortId = orderId.length >= 8
        ? 'APM-${orderId.replaceAll('-', '').substring(0, 8).toUpperCase()}'
        : orderId;
    final rawItems = order['items'];
    final itemsList = rawItems is List ? rawItems : [];
    final address = order['address']?.toString() ?? '';
    final payment = order['payment_method']?.toString() ?? '';
    final cancelReason = order['cancellation_reason']?.toString() ?? '';
    final riderId = order['rider_id']?.toString();
    final riderName = riderId != null ? riderNames[riderId] : null;

    Color statusColor(String s) {
      switch (s) {
        case 'delivered':        return const Color(0xFF43A047);
        case 'processing':       return const Color(0xFF1976D2);
        case 'picked_up':        return const Color(0xFFFF9800);
        case 'shipped':          return const Color(0xFF29B6F6);
        case 'cancelled':        return const Color(0xFFE53935);
        case 'cancel_requested': return const Color(0xFFFF8F00);
        default:                 return const Color(0xFFFF6B2B);
      }
    }

    String statusLabel(String s) {
      switch (s) {
        case 'delivered':        return 'Delivered';
        case 'processing':       return 'Approved';
        case 'picked_up':        return 'Picked Up';
        case 'shipped':          return 'On the Way';
        case 'cancelled':        return 'Cancelled';
        case 'cancel_requested': return 'Cancel Requested';
        default:                 return 'Pending';
      }
    }

    final sc = statusColor(status);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: sc.withValues(alpha: 0.12),
                      shape: BoxShape.circle),
                  child: Icon(Icons.receipt_long_outlined,
                      color: sc, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shortId,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.darkGrey)),
                      if (date != null)
                        Text(
                          '${date.day}/${date.month}/${date.year}  '
                          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.grey),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: sc.withValues(alpha: 0.3)),
                  ),
                  child: Text(statusLabel(status),
                      style: TextStyle(
                          fontSize: 11,
                          color: sc,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),

          // Scrollable body
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cancellation request banner + reason
                  if (status == 'cancel_requested') ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFCC02)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.pending_actions_outlined,
                                  color: Color(0xFFFF8F00), size: 18),
                              SizedBox(width: 8),
                              Text('Customer Requested Cancellation',
                                  style: TextStyle(
                                      color: Color(0xFFE65100),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ],
                          ),
                          if (cancelReason.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('Reason: $cancelReason',
                                style: const TextStyle(
                                    color: Color(0xFFBF360C),
                                    fontSize: 12,
                                    height: 1.4)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Items
                  if (itemsList.isNotEmpty) ...[
                    const Text('Items Ordered',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.navyBlue)),
                    const SizedBox(height: 8),
                    ...itemsList.map((raw) {
                      final item = raw as Map<String, dynamic>;
                      final name =
                          item['product_name']?.toString() ?? '—';
                      final price =
                          (item['price'] as num?)?.toDouble() ?? 0;
                      final qty =
                          (item['quantity'] as num?)?.toInt() ?? 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.veryLightBlue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                  Icons.home_repair_service_rounded,
                                  color: AppColors.lightBlue,
                                  size: 22),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                  Text(
                                      '₱${price.toStringAsFixed(0)} × $qty',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.grey)),
                                ],
                              ),
                            ),
                            Text(
                                '₱${(price * qty).toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBlue,
                                    fontSize: 13)),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 16),
                  ],

                  // Info rows
                  if (address.isNotEmpty)
                    _infoRow(Icons.location_on_outlined,
                        'Address', address),
                  if (payment.isNotEmpty)
                    _infoRow(Icons.payment_outlined, 'Payment', payment),
                  if (riderName != null)
                    _infoRow(Icons.delivery_dining_outlined,
                        'Rider', riderName),
                  _infoRow(Icons.payments_outlined, 'Total',
                      '₱${amount.toStringAsFixed(0)}'),
                ],
              ),
            ),
          ),

          // Footer actions
          if (status == 'cancel_requested')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: busy
                      ? null
                      : () {
                          Navigator.pop(context);
                          onAcceptCancellation(order);
                        },
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline,
                          size: 20),
                  label: const Text('Accept Cancellation',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Text('$label: ',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey,
                    fontWeight: FontWeight.w600)),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.darkGrey)),
            ),
          ],
        ),
      );
}

// ── Product Add / Edit Sheet ──────────────────────────────────────────────────

void _showProductSheet(
    BuildContext context, Product? existing, VoidCallback? onRefresh) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _ProductFormSheet(existing: existing, onRefresh: onRefresh),
  );
}

class _ProductFormSheet extends StatefulWidget {
  final Product? existing;
  final VoidCallback? onRefresh;

  const _ProductFormSheet({this.existing, this.onRefresh});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _origCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _stockCtrl;
  late String _cat;
  late bool _featured;
  late bool _freeShip;
  late String _imageUrl;
  bool _uploading = false;
  bool _saving = false;

  static const _cats = [
    'Television',
    'Refrigerator',
    'Washing Machine',
    'Air Conditioner',
    'Fan',
    'Microwave',
    'Vacuum Cleaner',
    'Dishwasher',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _priceCtrl = TextEditingController(
        text: e?.price != null ? e!.price.toStringAsFixed(0) : '');
    _origCtrl = TextEditingController(
        text: e?.originalPrice != null
            ? e!.originalPrice!.toStringAsFixed(0)
            : '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _stockCtrl = TextEditingController(
        text: e?.stock != null ? e!.stock.toString() : '');
    _cat = e?.category ?? 'Television';
    _featured = e?.isFeatured ?? false;
    _freeShip = e?.freeShipping ?? false;
    _imageUrl = e?.imageUrl ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _origCtrl.dispose();
    _descCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 75);
    if (xfile == null) return;

    setState(() => _uploading = true);
    try {
      final Uint8List bytes = await xfile.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('product-images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg'),
          );
      final url = Supabase.instance.client.storage
          .from('product-images')
          .getPublicUrl(fileName);
      if (mounted) setState(() { _imageUrl = url; _uploading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 3),
        ));
      }
    }
  }

  Widget _buildImagePicker() => GestureDetector(
        onTap: _uploading ? null : _pickAndUpload,
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.veryLightBlue,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.lightBlue),
          ),
          clipBehavior: Clip.antiAlias,
          child: _uploading
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                        color: AppColors.primaryBlue),
                    SizedBox(height: 8),
                    Text('Uploading...',
                        style: TextStyle(
                            color: AppColors.grey, fontSize: 12)),
                  ],
                )
              : _imageUrl.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          _imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _imagePlaceholder(),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.navyBlue
                                  .withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit,
                                    color: Colors.white, size: 13),
                                SizedBox(width: 4),
                                Text('Change',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : _imagePlaceholder(),
        ),
      );

  Widget _imagePlaceholder() => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              color: AppColors.lightBlue, size: 42),
          SizedBox(height: 6),
          Text('Tap to add product photo',
              style: TextStyle(color: AppColors.grey, fontSize: 12)),
          SizedBox(height: 2),
          Text('Choose from gallery',
              style: TextStyle(
                  color: AppColors.lightBlue, fontSize: 11)),
        ],
      );

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primaryBlue, size: 20),
        ),
      );

  String _clean(String s) => s.replaceAll(',', '').trim();

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_clean(_priceCtrl.text));
    final stock = int.tryParse(_clean(_stockCtrl.text));
    if (name.isEmpty || price == null || stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Name, price and stock are required'),
        backgroundColor: AppColors.red,
        duration: Duration(seconds: 2),
      ));
      return;
    }
    setState(() => _saving = true);
    final ok = await _doSave(
      context: context,
      existing: widget.existing,
      name: name,
      price: price,
      originalPrice: _origCtrl.text.isNotEmpty
          ? double.tryParse(_clean(_origCtrl.text))
          : null,
      description: _descCtrl.text.trim(),
      stock: stock,
      category: _cat,
      imageUrl: _imageUrl,
      isFeatured: _featured,
      freeShipping: _freeShip,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
      widget.onRefresh?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    isEdit ? Icons.edit_outlined : Icons.add_box_outlined,
                    color: AppColors.navyBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEdit ? 'Edit Product' : 'Add Product',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyBlue),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildImagePicker(),
              const SizedBox(height: 12),
              _field(_nameCtrl, 'Product Name *', Icons.label_outline),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _field(_priceCtrl, 'Price (₱) *',
                          Icons.payments_outlined,
                          keyboard: const TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _field(_origCtrl, 'Original Price (₱)',
                          Icons.sell_outlined,
                          keyboard: const TextInputType.numberWithOptions(decimal: true))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _cat,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        prefixIcon: Icon(Icons.category_outlined,
                            color: AppColors.primaryBlue, size: 20),
                      ),
                      items: _cats
                          .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => setState(() => _cat = v ?? _cat),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _field(_stockCtrl, 'Stock *',
                          Icons.inventory_outlined,
                          keyboard: const TextInputType.numberWithOptions())),
                ],
              ),
              const SizedBox(height: 10),
              _field(_descCtrl, 'Description',
                  Icons.description_outlined,
                  maxLines: 3),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      value: _featured,
                      onChanged: (v) =>
                          setState(() => _featured = v ?? false),
                      title: const Text('Featured',
                          style: TextStyle(fontSize: 13)),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primaryBlue,
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      value: _freeShip,
                      onChanged: (v) =>
                          setState(() => _freeShip = v ?? false),
                      title: const Text('Free Ship',
                          style: TextStyle(fontSize: 13)),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyBlue,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          isEdit ? 'Save Changes' : 'Add Product',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

// ── Admin Messages Tab ────────────────────────────────────────────────────────

class _AdminMessagesTab extends StatefulWidget {
  const _AdminMessagesTab();

  @override
  State<_AdminMessagesTab> createState() => _AdminMessagesTabState();
}

class _AdminMessagesTabState extends State<_AdminMessagesTab> {
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribe();
  }

  void _subscribe() {
    if (!SupabaseConfig.isConfigured) return;
    _channel = Supabase.instance.client
        .channel('admin-msgs-list')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (_) { if (mounted) _load(); },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_channel != null && SupabaseConfig.isConfigured) {
      try { Supabase.instance.client.removeChannel(_channel!); } catch (_) {}
      _channel = null;
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final convs = await MessageService.loadConversations();
    if (mounted) setState(() { _conversations = convs; _loading = false; });
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue));
    }
    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.lightBlue),
            const SizedBox(height: 12),
            Text(
              SupabaseConfig.isConfigured
                  ? 'No messages yet'
                  : 'Connect Supabase to see messages',
              style: const TextStyle(color: AppColors.grey),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryBlue,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _conversations.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final conv = _conversations[i];
          final userId = conv['user_id']?.toString() ?? '';
          final userName = conv['user_name']?.toString() ?? 'User';
          final preview = conv['content']?.toString() ?? '';
          final sender = conv['sender']?.toString() ?? 'user';
          final date = DateTime.tryParse(conv['created_at']?.toString() ?? '');
          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _AdminConversationScreen(
                  userId: userId,
                  userName: userName,
                ),
              ),
            ).then((_) => _load()),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person,
                        color: AppColors.primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(userName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.darkGrey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            if (date != null)
                              Text(_timeAgo(date),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.grey)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          sender == 'support' ? 'You: $preview' : preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.grey, size: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Admin Conversation Screen ─────────────────────────────────────────────────

class _AdminConversationScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const _AdminConversationScreen({
    required this.userId,
    required this.userName,
  });

  @override
  State<_AdminConversationScreen> createState() =>
      _AdminConversationScreenState();
}

class _AdminConversationScreenState
    extends State<_AdminConversationScreen> {
  List<Message> _messages = [];
  bool _loading = true;
  bool _sending = false;
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribe();
  }

  void _subscribe() {
    if (!SupabaseConfig.isConfigured) return;
    _channel = Supabase.instance.client
        .channel('admin-conv-${widget.userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: widget.userId,
          ),
          callback: _onNewMessage,
        )
        .subscribe();
  }

  void _onNewMessage(PostgresChangePayload payload) {
    if (!mounted) return;
    try {
      final newMsg = Message.fromJson(
          Map<String, dynamic>.from(payload.newRecord as Map));
      if (newMsg.id.isEmpty) return;
      if (_messages.any((m) => m.id == newMsg.id)) return;
      setState(() => _messages = [..._messages, newMsg]);
      _scrollToBottom();
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_channel != null && SupabaseConfig.isConfigured) {
      try { Supabase.instance.client.removeChannel(_channel!); } catch (_) {}
      _channel = null;
    }
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final msgs =
        await MessageService.loadConversationForUser(widget.userId);
    if (mounted) {
      setState(() { _messages = msgs; _loading = false; });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _reply() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      await MessageService.replyToUser(
        userId: widget.userId,
        userName: widget.userName,
        content: text,
      );
      // Silent reload as fallback; realtime also fires for this insert
      final msgs = await MessageService.loadConversationForUser(widget.userId);
      if (mounted) {
        setState(() { _messages = msgs; _sending = false; });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.userName,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const Text('Customer',
                style:
                    TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryBlue))
                : _messages.isEmpty
                    ? const Center(
                        child: Text('No messages',
                            style: TextStyle(color: AppColors.grey)))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) =>
                            _AdminBubble(message: _messages[i]),
                      ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: MediaQuery.of(context).padding.bottom + 8,
              top: 8,
            ),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Reply as ApliMart Support...',
                      hintStyle:
                          const TextStyle(color: AppColors.grey),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: AppColors.lightBlue),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: AppColors.lightBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: AppColors.primaryBlue, width: 1.5),
                      ),
                      filled: true,
                      fillColor: AppColors.offWhite,
                    ),
                    onSubmitted: (_) => _reply(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _reply,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _sending
                          ? AppColors.grey
                          : AppColors.navyBlue,
                      shape: BoxShape.circle,
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminBubble extends StatelessWidget {
  final Message message;
  const _AdminBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isSupport = !message.isFromUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment:
            isSupport ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72),
          decoration: BoxDecoration(
            color:
                isSupport ? AppColors.navyBlue : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft:
                  Radius.circular(isSupport ? 16 : 4),
              bottomRight:
                  Radius.circular(isSupport ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4),
            ],
          ),
          child: Text(
            message.content,
            style: TextStyle(
                color:
                    isSupport ? Colors.white : AppColors.darkGrey,
                fontSize: 14),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

Future<bool> _doSave({
  required BuildContext context,
  required Product? existing,
  required String name,
  required double price,
  double? originalPrice,
  required String description,
  required int stock,
  required String category,
  String imageUrl = '',
  bool isFeatured = false,
  bool freeShipping = false,
}) async {
  if (!SupabaseConfig.isConfigured) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Connect Supabase to save products'),
      backgroundColor: AppColors.primaryBlue,
      duration: Duration(seconds: 2),
    ));
    return false;
  }
  try {
    final db = Supabase.instance.client.from('products');
    final data = {
      'name': name,
      'price': price,
      'original_price': originalPrice,
      'description': description.isEmpty ? name : description,
      'stock': stock,
      'category': category,
      'image_url': imageUrl,
      'is_featured': isFeatured,
      'free_shipping': freeShipping,
    };
    if (existing == null) {
      await db.insert(data);
    } else {
      await db.update(data).eq('id', existing.id);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(existing == null
            ? 'Product added!'
            : 'Product updated!'),
        backgroundColor: AppColors.green,
        duration: const Duration(seconds: 2),
      ));
      context.read<ProductProvider>().load();
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.red,
        duration: const Duration(seconds: 3),
      ));
    }
    return false;
  }
}

// ── Riders Tab ────────────────────────────────────────────────────────────────

class _RidersTab extends StatefulWidget {
  const _RidersTab();

  @override
  State<_RidersTab> createState() => _RidersTabState();
}

class _RidersTabState extends State<_RidersTab> {
  List<Map<String, dynamic>> _riders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRiders();
  }

  Future<void> _loadRiders() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      if (SupabaseConfig.isConfigured) {
        final data = await Supabase.instance.client
            .from('riders')
            .select('user_id, email, name, added_at')
            .order('added_at', ascending: false);
        _riders = List<Map<String, dynamic>>.from(data as List);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _showAddRiderSheet() {
    if (!SupabaseConfig.hasServiceRole) {
      _snack('serviceRoleKey must start with sb_secret_... (new projects) or eyJ... (classic). Check supabase_config.dart.');
      return;
    }

    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscurePass = true;
    bool obscureConfirm = true;
    bool creating = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> create() async {
            final name = nameCtrl.text.trim();
            final email = emailCtrl.text.trim();
            final pass = passCtrl.text;
            final confirm = confirmCtrl.text;

            if (name.isEmpty || email.isEmpty || pass.isEmpty) {
              setSheet(() => error = 'All fields are required');
              return;
            }
            if (!email.contains('@')) {
              setSheet(() => error = 'Enter a valid email address');
              return;
            }
            if (pass.length < 6) {
              setSheet(() => error = 'Password must be at least 6 characters');
              return;
            }
            if (pass != confirm) {
              setSheet(() => error = 'Passwords do not match');
              return;
            }

            setSheet(() { creating = true; error = null; });
            try {
              await RiderAccountService.createRider(
                name: name, email: email, password: pass);
              _snack('Rider account created for $name!', ok: true);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadRiders();
            } catch (e) {
              setSheet(() {
                creating = false;
                error = e.toString().replaceFirst('Exception: ', '');
              });
            }
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF29B6F6).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person_add_outlined,
                            color: Color(0xFF0277BD), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Create Rider Account',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.navyBlue)),
                            Text('New account with rider role',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Name ────────────────────────────────────────────
                  _sheetField(
                    ctrl: nameCtrl,
                    hint: 'Full name',
                    icon: Icons.person_outline,
                    onChanged: () => setSheet(() => error = null),
                  ),
                  const SizedBox(height: 12),

                  // ── Email ────────────────────────────────────────────
                  _sheetField(
                    ctrl: emailCtrl,
                    hint: 'Email address',
                    icon: Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                    onChanged: () => setSheet(() => error = null),
                  ),
                  const SizedBox(height: 12),

                  // ── Password ─────────────────────────────────────────
                  _sheetField(
                    ctrl: passCtrl,
                    hint: 'Password (min. 6 characters)',
                    icon: Icons.lock_outline,
                    obscure: obscurePass,
                    toggleObscure: () =>
                        setSheet(() => obscurePass = !obscurePass),
                    onChanged: () => setSheet(() => error = null),
                  ),
                  const SizedBox(height: 12),

                  // ── Confirm password ──────────────────────────────────
                  _sheetField(
                    ctrl: confirmCtrl,
                    hint: 'Confirm password',
                    icon: Icons.lock_outline,
                    obscure: obscureConfirm,
                    toggleObscure: () =>
                        setSheet(() => obscureConfirm = !obscureConfirm),
                    onSubmitted: create,
                    onChanged: () => setSheet(() => error = null),
                  ),

                  // ── Error message ─────────────────────────────────────
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(error!,
                                style: const TextStyle(
                                    color: AppColors.red, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // ── Submit button ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: creating ? null : create,
                      icon: creating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.how_to_reg_outlined, size: 20),
                      label: Text(
                        creating ? 'Creating account…' : 'Create Rider Account',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.navyBlue.withValues(alpha: 0.5),
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      emailCtrl.dispose();
      passCtrl.dispose();
      confirmCtrl.dispose();
    });
  }

  Widget _sheetField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    VoidCallback? toggleObscure,
    VoidCallback? onSubmitted,
    VoidCallback? onChanged,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        obscureText: obscure,
        onSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
        onChanged: onChanged != null ? (_) => onChanged() : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.grey, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.grey, size: 20),
          suffixIcon: toggleObscure != null
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.grey,
                    size: 20,
                  ),
                  onPressed: toggleObscure,
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryBlue)),
          filled: true,
          fillColor: AppColors.offWhite,
        ),
      );

  Future<void> _removeRider(String userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Remove Rider'),
        content: Text('Remove rider role from $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Supabase.instance.client.from('riders').delete().eq('user_id', userId);
      if (mounted) { _snack('Rider removed', ok: true); await _loadRiders(); }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    }
  }

  void _snack(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? AppColors.green : AppColors.red,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRiderSheet,
        backgroundColor: AppColors.navyBlue,
        elevation: 3,
        icon: const Icon(Icons.person_add_outlined, color: Colors.white),
        label: const Text('Add Rider',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // ── Rider list ───────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryBlue))
                : _riders.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delivery_dining,
                                size: 52, color: AppColors.lightBlue),
                            SizedBox(height: 12),
                            Text('No riders yet',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkGrey)),
                            SizedBox(height: 6),
                            Text('Search for a user above to add them',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.grey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRiders,
                        color: AppColors.primaryBlue,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _riders.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final r = _riders[i];
                            final name = r['name']?.toString() ?? '—';
                            final email = r['email']?.toString() ?? '—';
                            final uid = r['user_id']?.toString() ?? '';
                            final initial = name.isNotEmpty
                                ? name[0].toUpperCase()
                                : '?';
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.04),
                                      blurRadius: 4)
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFF29B6F6)
                                        .withValues(alpha: 0.14),
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                          color: Color(0xFF0277BD),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: AppColors.darkGrey)),
                                        Text(email,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.grey)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: AppColors.red,
                                        size: 22),
                                    tooltip: 'Remove rider',
                                    onPressed: () =>
                                        _removeRider(uid, name),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),

          // ── Footer note ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: AppColors.veryLightBlue,
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: AppColors.primaryBlue),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'After granting or removing a rider role, the rider must sign out and sign back in.',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.darkGrey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _deleteProduct(
    BuildContext context, Product product, VoidCallback onRefresh) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Product'),
      content: Text(
          'Delete "${product.name}"? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.grey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Delete',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  if (!SupabaseConfig.isConfigured) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Connect Supabase to delete products'),
        backgroundColor: AppColors.primaryBlue,
        duration: Duration(seconds: 2),
      ));
    }
    return;
  }
  try {
    await Supabase.instance.client
        .from('products')
        .delete()
        .eq('id', product.id);
    onRefresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Product deleted'),
        backgroundColor: AppColors.green,
        duration: Duration(seconds: 2),
      ));
      context.read<ProductProvider>().load();
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.red,
        duration: const Duration(seconds: 3),
      ));
    }
  }
}

// ── Rider Picker Dialog ───────────────────────────────────────────────────────

class _RiderPickerDialog extends StatefulWidget {
  final String? currentRiderId;
  const _RiderPickerDialog({this.currentRiderId});

  @override
  State<_RiderPickerDialog> createState() => _RiderPickerDialogState();
}

class _RiderPickerDialogState extends State<_RiderPickerDialog> {
  List<Map<String, dynamic>> _riders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      if (SupabaseConfig.isConfigured) {
        final data = await Supabase.instance.client
            .from('riders')
            .select('user_id, name, email')
            .order('name');
        if (mounted) {
          setState(() {
            _riders = List<Map<String, dynamic>>.from(data as List);
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Row(
        children: [
          Icon(Icons.person_pin_circle_outlined,
              color: AppColors.navyBlue, size: 22),
          SizedBox(width: 8),
          Text('Assign Rider',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      content: _loading
          ? const SizedBox(
              height: 80,
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryBlue)))
          : _riders.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Text(
                    'No riders available.\nAdd a rider from the Riders tab first.',
                    style: TextStyle(color: AppColors.grey),
                  ),
                )
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _riders.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (_, i) {
                      final r = _riders[i];
                      final isAssigned =
                          r['user_id']?.toString() == widget.currentRiderId;
                      final initial =
                          (r['name']?.toString() ?? '?')[0].toUpperCase();
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.navyBlue.withValues(alpha: 0.12),
                          child: Text(initial,
                              style: const TextStyle(
                                  color: AppColors.navyBlue,
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text(r['name']?.toString() ?? 'Unknown',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(r['email']?.toString() ?? '',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.grey)),
                        trailing: isAssigned
                            ? const Icon(Icons.check_circle,
                                color: AppColors.green, size: 20)
                            : null,
                        onTap: () => Navigator.pop(context, r),
                      );
                    },
                  ),
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (widget.currentRiderId != null)
          TextButton(
            onPressed: () =>
                Navigator.pop(context, {'user_id': null}),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Unassign'),
          ),
      ],
    );
  }
}
