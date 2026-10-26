import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/product_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;
  final bool fromCheckout;

  const OrderDetailScreen({
    super.key,
    required this.order,
    this.fromCheckout = false,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  // Mutable local copy so status updates (e.g. cancel_requested) are reflected
  // immediately without needing to pop and re-open the screen.
  late Order _localOrder;
  Order get order => _localOrder;

  // productId → selected star rating (1–5)
  final Map<String, double> _selectedRating = {};
  // productId → already submitted
  final Map<String, bool> _alreadyRated = {};
  // productId → submitting in progress
  final Map<String, bool> _submitting = {};
  // productId → review text controller
  final Map<String, TextEditingController> _reviewCtrl = {};
  bool _loadingRated = true;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _localOrder = widget.order;
    if (order.status == OrderStatus.delivered) {
      _loadRatedState();
    } else {
      _loadingRated = false;
    }
  }

  @override
  void dispose() {
    for (final c in _reviewCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrlFor(String productId) =>
      _reviewCtrl.putIfAbsent(productId, TextEditingController.new);

  bool get _canCancel =>
      order.status == OrderStatus.pending ||
      order.status == OrderStatus.processing;

  static const _cancelReasons = [
    'Changed my mind',
    'Found a better price elsewhere',
    'Ordered by mistake',
    'Delivery takes too long',
    'Other',
  ];

  /// All cancellations go through the reason dialog regardless of status —
  /// the request is sent to admin for confirmation before anything is cancelled.
  Future<String?> _showCancelDialog() => showDialog<String>(
        context: context,
        builder: (ctx) => _CancelReasonDialog(reasons: _cancelReasons),
      );

  Future<void> _cancelOrder() async {
    final reason = await _showCancelDialog();
    if (reason == null || !mounted) return;

    setState(() => _cancelling = true);
    try {
      final updated = await context
          .read<OrderProvider>()
          .cancelOrder(order.id, reason: reason.isEmpty ? null : reason);

      if (!mounted) return;

      // Stock is NOT restored here — admin must approve the cancellation first.
      // Stay on this screen showing the cancel_requested status.
      setState(() {
        if (updated != null) _localOrder = updated;
        _cancelling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Cancellation request submitted. Waiting for admin review.'),
          backgroundColor: Color(0xFFFF8F00),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit cancellation. Please try again.'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Future<void> _loadRatedState() async {
    final rated = <String, bool>{};
    final ratings = <String, double>{};
    for (final item in order.items) {
      final existing = await ProductService.getUserRating(item.productId);
      final isRated = existing != null;
      rated[item.productId] = isRated;
      if (isRated) {
        ratings[item.productId] =
            (existing['rating'] as num).toDouble();
        // Pre-fill the text controller so the user's existing review shows
        final text = existing['review_text']?.toString() ?? '';
        if (text.isNotEmpty) _ctrlFor(item.productId).text = text;
      } else {
        ratings[item.productId] = 5.0;
      }
    }
    if (!mounted) return;
    setState(() {
      _alreadyRated.addAll(rated);
      _selectedRating.addAll(ratings);
      _loadingRated = false;
    });
  }

  Future<void> _submitRating(OrderItem item) async {
    final rating = _selectedRating[item.productId] ?? 5.0;
    final reviewText = _ctrlFor(item.productId).text.trim();
    final reviewerName =
        context.read<AuthProvider>().displayName;
    setState(() => _submitting[item.productId] = true);
    try {
      await ProductService.submitRating(
        item.productId,
        rating,
        reviewText: reviewText,
        reviewerName: reviewerName,
      );
      if (!mounted) return;
      setState(() {
        _alreadyRated[item.productId] = true;
        _selectedRating[item.productId] = rating;
        _submitting[item.productId] = false;
      });
      context.read<ProductProvider>().load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your rating!'),
          backgroundColor: AppColors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting[item.productId] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit rating. Please try again.'),
          backgroundColor: AppColors.red,
        ),
      );
    }
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
        title: Text(order.orderNumber,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Success banner (only right after checkout)
          if (widget.fromCheckout) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Placed!',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text('Your order has been confirmed.',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Cancel-requested banner
          if (order.status == OrderStatus.cancelRequested) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCC02)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.pending_actions_outlined,
                      color: Color(0xFFFF8F00), size: 26),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cancellation Pending',
                            style: TextStyle(
                                color: Color(0xFFE65100),
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        Text(
                            'Your request is under admin review. '
                            'You will be notified once it is processed.',
                            style: TextStyle(
                                color: Color(0xFFBF360C),
                                fontSize: 12,
                                height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Status & timeline
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
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
                              color: order.status.color, size: 14),
                          const SizedBox(width: 4),
                          Text(order.status.label,
                              style: TextStyle(
                                  color: order.status.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(_formatDate(order.createdAt),
                        style: const TextStyle(
                            color: AppColors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                _statusTimeline(),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Items
          _sectionHeader(Icons.shopping_bag_outlined, 'Items Ordered'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: order.items
                  .map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.veryLightBlue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                  Icons.home_repair_service_rounded,
                                  color: AppColors.lightBlue,
                                  size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text(
                                      '${Order.formatPrice(item.price)} × ${item.quantity}',
                                      style: const TextStyle(
                                          color: AppColors.grey,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(Order.formatPrice(item.subtotal),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBlue,
                                    fontSize: 13)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Rating section — only for delivered orders
          if (order.status == OrderStatus.delivered) ...[
            const SizedBox(height: 12),
            _sectionHeader(Icons.star_rounded, 'Rate Your Items'),
            const SizedBox(height: 8),
            if (_loadingRated)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          color: AppColors.primaryBlue)))
            else
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...order.items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final rated = _alreadyRated[item.productId] ?? false;
                      final submitting =
                          _submitting[item.productId] ?? false;
                      final stars =
                          _selectedRating[item.productId] ?? 5.0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (idx > 0)
                            const Divider(height: 24),
                          Text(item.productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.darkGrey)),
                          const SizedBox(height: 10),
                          if (rated) ...[
                            Row(
                              children: [
                                RatingBarIndicator(
                                  rating: stars,
                                  itemBuilder: (_, _) => const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber),
                                  itemCount: 5,
                                  itemSize: 22,
                                  unratedColor: Colors.grey[300],
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.green
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                        color: AppColors.green
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_outline,
                                          size: 12, color: AppColors.green),
                                      SizedBox(width: 4),
                                      Text('Rated',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.green,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Show their existing review text
                            Builder(builder: (_) {
                              final existingText =
                                  _ctrlFor(item.productId).text;
                              if (existingText.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.grey[200]!),
                                  ),
                                  child: Text(
                                    existingText,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.darkGrey,
                                        height: 1.4),
                                  ),
                                ),
                              );
                            }),
                          ] else ...[
                            RatingBar.builder(
                              initialRating: stars,
                              minRating: 1,
                              itemCount: 5,
                              itemSize: 32,
                              allowHalfRating: false,
                              glow: false,
                              itemBuilder: (_, _) => const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber),
                              unratedColor: Colors.grey[300],
                              onRatingUpdate: (r) => setState(
                                  () => _selectedRating[item.productId] = r),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _ctrlFor(item.productId),
                              maxLines: 3,
                              maxLength: 300,
                              decoration: InputDecoration(
                                hintText: 'Write a review (optional)…',
                                hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.grey[300]!),
                                ),
                                counterStyle: const TextStyle(fontSize: 10),
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 38,
                              child: ElevatedButton(
                                onPressed: submitting
                                    ? null
                                    : () => _submitRating(item),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.navyBlue,
                                  disabledBackgroundColor: Colors.grey[300],
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                ),
                                child: submitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Text('Submit Review',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                              ),
                            ),
                          ],
                        ],
                      );
                    }),
                  ],
                ),
              ),
          ],

          const SizedBox(height: 12),

          // Delivery info
          _sectionHeader(Icons.location_on_outlined, 'Delivery Address'),
          const SizedBox(height: 8),
          _card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.home_outlined,
                    color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(order.address,
                      style: const TextStyle(
                          color: AppColors.darkGrey, height: 1.5)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Payment
          _sectionHeader(Icons.payment_outlined, 'Payment'),
          const SizedBox(height: 8),
          _card(
            child: Row(
              children: [
                const Icon(Icons.credit_card_outlined,
                    color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 10),
                Text(order.paymentMethod,
                    style: const TextStyle(
                        color: AppColors.darkGrey,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Price breakdown
          _sectionHeader(Icons.receipt_outlined, 'Price Breakdown'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                _priceRow('Subtotal (${order.itemCount} items)',
                    Order.formatPrice(order.subtotal)),
                const SizedBox(height: 6),
                _taxRow('VAT (12%)',
                    Order.formatPrice(order.vatAmount),
                    const Color(0xFFE65100)),
                const SizedBox(height: 6),
                _taxRow('Platform Fee (1%)',
                    Order.formatPrice(order.serviceFee),
                    const Color(0xFF1976D2)),
                const SizedBox(height: 6),
                _priceRow('Shipping Fee',
                    order.shippingFee == 0
                        ? 'Free'
                        : Order.formatPrice(order.shippingFee)),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.navyBlue)),
                    Text(order.formattedTotal,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: AppColors.primaryBlue)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.veryLightBlue,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.lightBlue
                            .withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 12, color: AppColors.primaryBlue),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'VAT (12%) per BIR regulations · '
                          'Platform fee covers e-commerce processing',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.darkGrey,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cancellation reason card
          if ((order.status == OrderStatus.cancelled ||
                  order.status == OrderStatus.cancelRequested) &&
              (order.cancellationReason?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 12),
            _sectionHeader(
                Icons.info_outline, 'Cancellation Reason'),
            const SizedBox(height: 8),
            _card(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.comment_outlined,
                      color: AppColors.red, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(order.cancellationReason!,
                        style: const TextStyle(
                            color: AppColors.darkGrey, height: 1.5)),
                  ),
                ],
              ),
            ),
          ],

          // Cancel button — only for pending / processing orders
          if (_canCancel) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _cancelling ? null : _cancelOrder,
                icon: _cancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: AppColors.red, strokeWidth: 2))
                    : const Icon(Icons.cancel_outlined,
                        color: AppColors.red, size: 20),
                label: Text(
                  _cancelling ? 'Cancelling...' : 'Cancel Order',
                  style: const TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statusTimeline() {
    final steps = [
      (OrderStatus.pending, 'Order Placed'),
      (OrderStatus.processing, 'Processing'),
      (OrderStatus.shipped, 'Shipped'),
      (OrderStatus.delivered, 'Delivered'),
    ];
    final currentIdx = steps.indexWhere((s) => s.$1 == order.status);
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIdx = i ~/ 2;
          final active = stepIdx < (currentIdx < 0 ? 0 : currentIdx);
          return Expanded(
            child: Container(
              height: 2,
              color: active ? AppColors.navyBlue : AppColors.lightBlue,
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final done = currentIdx < 0 ? false : stepIdx <= currentIdx;
        final (_, label) = steps[stepIdx];
        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.navyBlue : AppColors.lightBlue,
              ),
              child: Icon(
                done ? Icons.check : Icons.circle,
                size: done ? 14 : 6,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    color: done ? AppColors.navyBlue : AppColors.grey,
                    fontWeight:
                        done ? FontWeight.bold : FontWeight.normal)),
          ],
        );
      }),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
            )
          ],
        ),
        child: child,
      );

  Widget _sectionHeader(IconData icon, String title) => Row(
        children: [
          Icon(icon, color: AppColors.navyBlue, size: 18),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.navyBlue)),
        ],
      );

  Widget _priceRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.grey, fontSize: 13)),
          Text(value,
              style: const TextStyle(color: AppColors.darkGrey, fontSize: 13)),
        ],
      );

  Widget _taxRow(String label, String value, Color color) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const SizedBox(width: 10),
              Icon(Icons.add_circle_outline, size: 12, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      );

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ── Cancel-reason dialog (used when order is already admin-approved) ──────────

class _CancelReasonDialog extends StatefulWidget {
  final List<String> reasons;
  const _CancelReasonDialog({required this.reasons});

  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  String? _selected;
  final _otherCtrl = TextEditingController();
  bool _otherEmpty = false;

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  bool get _isOther => _selected == 'Other';

  String? get _result {
    if (_selected == null) return null;
    if (_isOther) {
      final t = _otherCtrl.text.trim();
      return t.isEmpty ? null : t;
    }
    return _selected;
  }

  void _submit() {
    if (_selected == null) return;
    if (_isOther && _otherCtrl.text.trim().isEmpty) {
      setState(() => _otherEmpty = true);
      return;
    }
    Navigator.pop(context, _result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      title: const Row(
        children: [
          Icon(Icons.cancel_outlined, color: AppColors.red, size: 24),
          SizedBox(width: 10),
          Text('Cancel Approved Order', style: TextStyle(fontSize: 16)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.red.withValues(alpha: 0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This order has been approved by the admin. '
                      'Please tell us why you want to cancel it.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.red,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('Select a reason:',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.darkGrey)),
            const SizedBox(height: 6),
            ...widget.reasons.map((r) => RadioListTile<String>(
                  value: r,
                  groupValue: _selected,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.red,
                  title: Text(r,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.darkGrey)),
                  onChanged: (v) => setState(() {
                    _selected = v;
                    _otherEmpty = false;
                  }),
                )),
            if (_isOther) ...[
              const SizedBox(height: 6),
              TextField(
                controller: _otherCtrl,
                maxLines: 2,
                onChanged: (_) => setState(() => _otherEmpty = false),
                decoration: InputDecoration(
                  hintText: 'Please describe your reason…',
                  hintStyle: const TextStyle(fontSize: 12),
                  errorText: _otherEmpty ? 'Please enter a reason' : null,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.red),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
      actionsPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Go Back',
              style: TextStyle(color: AppColors.grey)),
        ),
        ElevatedButton(
          onPressed: _selected == null ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red,
            disabledBackgroundColor: Colors.grey[300],
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Submit Cancellation',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
