import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/login_prompt.dart';
import '../cart/cart_screen.dart';
import '../checkout/checkout_screen.dart';

Widget _detailImage(String url) {
  final isReal = url.isNotEmpty && !url.contains('picsum');
  if (!isReal) {
    return Container(
      color: AppColors.veryLightBlue,
      child: const Icon(Icons.home_repair_service_rounded,
          size: 80, color: AppColors.lightBlue),
    );
  }
  return CachedNetworkImage(
    imageUrl: url,
    fit: BoxFit.cover,
    placeholder: (_, _) => Container(color: AppColors.veryLightBlue),
    errorWidget: (_, _, _) => Container(
      color: AppColors.veryLightBlue,
      child: const Icon(Icons.home_repair_service_rounded,
          size: 80, color: AppColors.lightBlue),
    ),
  );
}

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;

  Product get p => widget.product;

  void _goToCart() {
    ScaffoldMessenger.of(context).clearSnackBars();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  void _addToCart() {
    if (!context.read<AuthProvider>().isLoggedIn) {
      showLoginPrompt(context);
      return;
    }
    context.read<CartProvider>().addItem(p, quantity: _qty);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${p.name} added to cart'),
      backgroundColor: AppColors.primaryBlue,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.navyBlue,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Consumer<CartProvider>(
                builder: (_, cart, _) => Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined,
                          color: Colors.white),
                      onPressed: _goToCart,
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: AppColors.red, shape: BoxShape.circle),
                          child: Text('${cart.itemCount}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _detailImage(p.imageUrl),
                  // Gradient overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black26],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price + badges
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(p.formattedPrice,
                              style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          if (p.originalPrice != null) ...[
                            Text(p.formattedOriginalPrice,
                                style: const TextStyle(
                                    color: AppColors.grey,
                                    fontSize: 16,
                                    decoration: TextDecoration.lineThrough)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('-${p.discountPercent}%',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(p.name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGrey,
                              height: 1.3)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: p.rating,
                            itemBuilder: (_, _) => const Icon(
                                Icons.star_rounded,
                                color: Colors.amber),
                            itemCount: 5,
                            itemSize: 18,
                          ),
                          const SizedBox(width: 6),
                          Text('${p.rating}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkGrey)),
                          Text(' (${p.reviewCount} reviews)',
                              style: const TextStyle(
                                  color: AppColors.grey, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _badgeChip(Icons.sell_outlined,
                              '${p.soldCount} sold', AppColors.skyBlue),
                          const SizedBox(width: 8),
                          if (p.freeShipping) ...[
                            _badgeChip(Icons.local_shipping_outlined,
                                'Free Shipping', AppColors.green),
                            const SizedBox(width: 8),
                          ],
                          if (p.stock == 0)
                            _badgeChip(Icons.remove_shopping_cart_outlined,
                                'Out of Stock', AppColors.red)
                          else
                            _badgeChip(Icons.inventory_2_outlined,
                                '${p.stock} in stock', AppColors.primaryBlue),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Description
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Product Description',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyBlue)),
                      const Divider(height: 16),
                      Text(p.description,
                          style: const TextStyle(
                              color: AppColors.darkGrey,
                              fontSize: 14,
                              height: 1.6)),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Specs
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Specifications',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyBlue)),
                      const Divider(height: 16),
                      _specRow('Category', p.category),
                      _specRow('Rating', '${p.rating} / 5.0'),
                      _specRow('Stock', '${p.stock} units'),
                      _specRow(
                          'Shipping', p.freeShipping ? 'Free' : 'Standard'),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Customer Ratings breakdown
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Customer Ratings',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyBlue)),
                      const Divider(height: 16),
                      if (p.reviewCount == 0)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.star_border_rounded,
                                  color: AppColors.grey, size: 28),
                              SizedBox(width: 10),
                              Text('No ratings yet',
                                  style: TextStyle(
                                      color: AppColors.grey, fontSize: 14)),
                            ],
                          ),
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left: big average + stars + count
                            SizedBox(
                              width: 88,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    p.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.navyBlue,
                                        height: 1),
                                  ),
                                  const SizedBox(height: 6),
                                  RatingBarIndicator(
                                    rating: p.rating,
                                    itemBuilder: (_, _) => const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber),
                                    itemCount: 5,
                                    itemSize: 14,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${p.reviewCount} rating${p.reviewCount == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Right: per-star percentage bars
                            Expanded(
                              child: Column(
                                children: List.generate(5, (i) {
                                  final star = 5 - i;
                                  final count =
                                      p.ratingBreakdown[star] ?? 0;
                                  final pct = p.reviewCount > 0
                                      ? count / p.reviewCount
                                      : 0.0;
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 5),
                                    child: Row(
                                      children: [
                                        Text('$star',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.darkGrey,
                                                fontWeight:
                                                    FontWeight.w600)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.star_rounded,
                                            size: 11,
                                            color: Colors.amber),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: pct,
                                              minHeight: 8,
                                              backgroundColor:
                                                  AppColors.veryLightBlue,
                                              valueColor:
                                                  AlwaysStoppedAnimation<
                                                      Color>(
                                                star >= 4
                                                    ? AppColors.green
                                                    : star == 3
                                                        ? Colors.amber
                                                        : AppColors.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        SizedBox(
                                          width: 34,
                                          child: Text(
                                            '${(pct * 100).round()}%',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.grey),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        SizedBox(
                                          width: 22,
                                          child: Text(
                                            '($count)',
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.grey),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Individual customer reviews
                _ReviewsSection(productId: p.id),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      // Bottom bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Compact quantity selector
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightBlue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: _qty > 1 ? () => setState(() => _qty--) : null,
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(8)),
                    child: SizedBox(
                      width: 32,
                      height: 44,
                      child: Icon(Icons.remove, size: 16,
                          color: _qty > 1
                              ? AppColors.primaryBlue
                              : AppColors.lightBlue),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('$_qty',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                  InkWell(
                    onTap: _qty < p.stock
                        ? () => setState(() => _qty++)
                        : null,
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(8)),
                    child: SizedBox(
                      width: 32,
                      height: 44,
                      child: Icon(Icons.add, size: 16,
                          color: _qty < p.stock
                              ? AppColors.primaryBlue
                              : AppColors.lightBlue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: ElevatedButton(
                onPressed: p.stock == 0 ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyBlue,
                  disabledBackgroundColor: Colors.grey[300],
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 16,
                        color: p.stock == 0 ? Colors.grey : Colors.white),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                          p.stock == 0 ? 'Out of Stock' : 'Add to Cart',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: p.stock == 0
                                  ? Colors.grey
                                  : Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: p.stock == 0
                    ? null
                    : () {
                        if (!context.read<AuthProvider>().isLoggedIn) {
                          showLoginPrompt(context);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(
                              directItems: [
                                CartItem(
                                  productId: p.id,
                                  quantity: _qty,
                                  product: p,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.skyBlue,
                  disabledBackgroundColor: Colors.grey[300],
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt_rounded,
                        size: 16,
                        color: p.stock == 0 ? Colors.grey : Colors.white),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text('Buy Now',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: p.stock == 0
                                  ? Colors.grey
                                  : Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeChip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _specRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.grey, fontSize: 13)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: AppColors.darkGrey,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
}

// ── Reviews section ───────────────────────────────────────────────────────────

class _ReviewsSection extends StatefulWidget {
  final String productId;
  const _ReviewsSection({required this.productId});

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection>
    with RouteAware {
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  // RouteObserver is looked up from the nearest NavigatorState.
  static final _routeObserver = RouteObserver<ModalRoute<void>>();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route events so we refresh when navigating back to this page.
    final route = ModalRoute.of(context);
    if (route != null) _routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// Called when the user pops back to this screen (e.g. after submitting a review).
  @override
  void didPopNext() => _fetch();

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final data = await ProductService.getReviews(widget.productId);
    if (mounted) setState(() { _reviews = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              const Text('Customer Reviews',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyBlue)),
              const Spacer(),
              if (_loading)
                const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primaryBlue))
              else
                GestureDetector(
                  onTap: _fetch,
                  child: const Icon(Icons.refresh_rounded,
                      size: 18, color: AppColors.primaryBlue),
                ),
            ],
          ),
          const Divider(height: 16),

          // ── Body ────────────────────────────────────────────────────────
          if (!_loading && _reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.rate_review_outlined,
                        size: 36, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    const Text('No reviews yet.',
                        style: TextStyle(
                            color: AppColors.grey, fontSize: 13)),
                    const SizedBox(height: 2),
                    const Text('Be the first to review this product!',
                        style: TextStyle(
                            color: AppColors.lightBlue, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            ..._reviews.map((r) => _ReviewCard(review: r)),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final name = review['reviewer_name']?.toString() ?? 'Anonymous';
    final text = review['review_text']?.toString() ?? '';
    final rating = (review['rating'] as num?)?.toDouble() ?? 0;
    final rawDate = review['created_at']?.toString();
    final date = rawDate != null ? DateTime.tryParse(rawDate) : null;
    final dateStr = date != null
        ? '${date.day} ${_month(date.month)} ${date.year}'
        : '';

    // Star label colour
    final starColor = rating >= 4
        ? AppColors.green
        : rating >= 3
            ? Colors.amber
            : AppColors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: avatar + name + date ──────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 17,
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
                const SizedBox(width: 8),
                Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                if (dateStr.isNotEmpty)
                  Text(dateStr,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.grey)),
              ],
            ),
            const SizedBox(height: 8),

            // ── Stars + numeric label ───────────────────────────────────
            Row(
              children: [
                RatingBarIndicator(
                  rating: rating,
                  itemBuilder: (_, _) =>
                      const Icon(Icons.star_rounded, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 16,
                  unratedColor: Colors.grey[300],
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: starColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    rating.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: starColor),
                  ),
                ),
              ],
            ),

            // ── Review text ─────────────────────────────────────────────
            if (text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(text,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.darkGrey,
                      height: 1.55)),
            ],
          ],
        ),
      ),
    );
  }

  static String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}
