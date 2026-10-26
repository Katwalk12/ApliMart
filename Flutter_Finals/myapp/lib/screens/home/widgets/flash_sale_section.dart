import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../config/app_theme.dart';
import '../../../models/product.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../widgets/login_prompt.dart';
import '../../product/product_detail_screen.dart';

class FlashSaleSection extends StatefulWidget {
  const FlashSaleSection({super.key});

  @override
  State<FlashSaleSection> createState() => _FlashSaleSectionState();
}

class _FlashSaleSectionState extends State<FlashSaleSection> {
  // Countdown: 4 hours from now
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = const Duration(hours: 4, minutes: 23, seconds: 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds > 0) {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();
    final saleProducts = pp.flashSale;
    if (saleProducts.isEmpty && !pp.loading) return const SizedBox.shrink();
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded,
                    color: AppColors.saleOrange, size: 22),
                const SizedBox(width: 4),
                const Text('Flash Sale',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyBlue)),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.navyBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _timeBox(_pad(_remaining.inHours)),
                      const Text(' : ',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      _timeBox(_pad(_remaining.inMinutes.remainder(60))),
                      const Text(' : ',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      _timeBox(_pad(_remaining.inSeconds.remainder(60))),
                    ],
                  ),
                ),
                const Spacer(),
                const Text('See All',
                    style: TextStyle(
                        color: AppColors.primaryBlue, fontSize: 13)),
                const Icon(Icons.chevron_right,
                    color: AppColors.primaryBlue, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: pp.loading
                ? _shimmerList()
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: saleProducts.length,
                    itemBuilder: (_, i) =>
                        _FlashProductItem(product: saleProducts[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _timeBox(String val) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.saleOrange,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(val,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      );

  Widget _shimmerList() => ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 5,
        itemBuilder: (_, _) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 110,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
}

class _FlashProductItem extends StatelessWidget {
  final Product product;

  const _FlashProductItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product)),
      ),
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.veryLightBlue),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  child: _flashImage(product.imageUrl),
                ),
                if (product.discountPercent > 0)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text('-${product.discountPercent}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.darkGrey, height: 1.3)),
                  const SizedBox(height: 4),
                  Text(product.formattedPrice,
                      style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  Consumer2<CartProvider, AuthProvider>(
                    builder: (_, cart, auth, _) => SizedBox(
                      width: double.infinity,
                      height: 22,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!auth.isLoggedIn) {
                            showLoginPrompt(context);
                            return;
                          }
                          cart.addItem(product);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.saleOrange,
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text('Add',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _flashImage(String url) {
  final isReal = url.isNotEmpty && !url.contains('picsum');
  if (!isReal) {
    return Container(
      height: 100,
      width: double.infinity,
      color: AppColors.veryLightBlue,
      child: const Icon(Icons.home_repair_service_rounded,
          color: AppColors.lightBlue),
    );
  }
  return CachedNetworkImage(
    imageUrl: url,
    height: 100,
    width: double.infinity,
    fit: BoxFit.cover,
    placeholder: (_, _) => Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    ),
    errorWidget: (_, _, _) => Container(
      height: 100,
      width: double.infinity,
      color: AppColors.veryLightBlue,
      child: const Icon(Icons.home_repair_service_rounded,
          color: AppColors.lightBlue),
    ),
  );
}
