import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../config/app_theme.dart';
import '../../../models/cart_item.dart';
import '../../../models/product.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/login_prompt.dart';
import '../../checkout/checkout_screen.dart';
import '../../product/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _productImage(product.imageUrl),
                  ),
                ),
                if (product.discountPercent > 0)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-${product.discountPercent}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                if (product.freeShipping)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Free Ship',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkGrey,
                          height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Text(
                      product.formattedPrice,
                      style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    if (product.originalPrice != null)
                      Text(
                        product.formattedOriginalPrice,
                        style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: product.rating,
                          itemBuilder: (_, _) => const Icon(
                              Icons.star_rounded,
                              color: Colors.amber),
                          itemCount: 5,
                          itemSize: 12,
                          unratedColor: Colors.grey[300],
                        ),
                        const SizedBox(width: 2),
                        if (product.reviewCount > 0)
                          Text(
                            '(${product.reviewCount})',
                            style: const TextStyle(
                                color: AppColors.grey, fontSize: 10),
                          ),
                        const Spacer(),
                        Text(
                          '${product.soldCount} sold',
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    product.stock == 0
                        ? Container(
                            width: double.infinity,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color:
                                      AppColors.red.withValues(alpha: 0.3)),
                            ),
                            alignment: Alignment.center,
                            child: const Text('Out of Stock',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.red,
                                    fontWeight: FontWeight.w600)),
                          )
                        : Consumer<AuthProvider>(
                      builder: (_, auth, _) => Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 28,
                              child: OutlinedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailScreen(product: product),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  side: const BorderSide(
                                      color: AppColors.primaryBlue, width: 1),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                ),
                                child: const Text('Details',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryBlue)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: SizedBox(
                              height: 28,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (!auth.isLoggedIn) {
                                    showLoginPrompt(context);
                                    return;
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CheckoutScreen(
                                        directItems: [
                                          CartItem(
                                            productId: product.id,
                                            quantity: 1,
                                            product: product,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.skyBlue,
                                  overlayColor: AppColors.navyBlue,
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                ),
                                child: const Text('Buy Now',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
}

Widget _productImage(String url) {
  final isReal = url.isNotEmpty && !url.contains('picsum');
  if (!isReal) {
    return Container(
      color: AppColors.veryLightBlue,
      child: const Icon(Icons.home_repair_service_rounded,
          size: 48, color: AppColors.lightBlue),
    );
  }
  return CachedNetworkImage(
    imageUrl: url,
    fit: BoxFit.cover,
    placeholder: (_, _) => Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    ),
    errorWidget: (_, _, _) => Container(
      color: AppColors.veryLightBlue,
      child: const Icon(Icons.home_repair_service_rounded,
          size: 48, color: AppColors.lightBlue),
    ),
  );
}
