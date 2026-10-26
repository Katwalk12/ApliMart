import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/login_prompt.dart';
import '../checkout/checkout_screen.dart';
import '../main/main_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  String _formatPrice(double p) {
    final s = p.toStringAsFixed(0);
    final buf = StringBuffer('₱');
    final start = s.length % 3;
    if (start > 0) buf.write(s.substring(0, start));
    for (int i = start; i < s.length; i += 3) {
      if (i > 0) buf.write(',');
      buf.write(s.substring(i, i + 3));
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.navyBlue, AppColors.darkBlue],
            ),
          ),
        ),
        title: const Text('My Cart',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Consumer<CartProvider>(
        builder: (_, cart, _) {
          if (cart.items.isEmpty) {
            return Center(
              child: Consumer<AuthProvider>(
                builder: (_, auth, _) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.veryLightBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_cart_outlined,
                          size: 52, color: AppColors.lightBlue),
                    ),
                    const SizedBox(height: 20),
                    const Text('Your cart is empty',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGrey)),
                    const SizedBox(height: 8),
                    const Text('Browse products and add to cart',
                        style: TextStyle(color: AppColors.grey)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const MainScreen()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Go Shopping Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyBlue,
                        minimumSize: const Size(200, 46),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    if (!auth.isLoggedIn) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => showLoginPrompt(context),
                        icon: const Icon(Icons.login_rounded,
                            color: AppColors.navyBlue),
                        label: const Text('Log in / Sign Up',
                            style: TextStyle(
                                color: AppColors.navyBlue,
                                fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppColors.navyBlue, width: 1.5),
                          minimumSize: const Size(200, 46),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.items.length,
                  itemBuilder: (_, i) {
                    final item = cart.items[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Image
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(10)),
                            child: _cartItemImage(item.product.imageUrl),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(item.product.formattedPrice,
                                      style: const TextStyle(
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  if (item.product.stock == 0) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.red
                                            .withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        border: Border.all(
                                            color: AppColors.red
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: const Text('Out of Stock',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.red,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _qtyBtn(Icons.remove, () {
                                        cart.updateQuantity(
                                            item.productId, item.quantity - 1);
                                      }),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 4),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: AppColors.lightBlue),
                                        ),
                                        child: Text('${item.quantity}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      _qtyBtn(Icons.add,
                                          item.quantity < item.product.stock
                                              ? () => cart.updateQuantity(
                                                  item.productId,
                                                  item.quantity + 1)
                                              : null),
                                      const Spacer(),
                                      Text(
                                        _formatPrice(item.subtotal),
                                        style: const TextStyle(
                                            color: AppColors.navyBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: AppColors.grey, size: 20),
                            onPressed: () =>
                                cart.removeItem(item.productId),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Order summary
              Container(
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${cart.itemCount} items',
                            style: const TextStyle(color: AppColors.grey)),
                        Text(_formatPrice(cart.total),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.darkGrey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Shipping', style: TextStyle(color: AppColors.grey)),
                        Text('Calculated at checkout',
                            style: TextStyle(
                                color: AppColors.grey, fontSize: 12)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.navyBlue)),
                        Text(
                          _formatPrice(cart.total),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: AppColors.primaryBlue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Consumer<AuthProvider>(
                      builder: (_, auth, _) {
                        final hasOutOfStock = cart.items
                            .any((i) => i.product.stock == 0);
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasOutOfStock)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        size: 16, color: AppColors.red),
                                    const SizedBox(width: 6),
                                    const Expanded(
                                      child: Text(
                                        'Some items are out of stock. Remove them to proceed.',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ElevatedButton(
                              onPressed: hasOutOfStock
                                  ? null
                                  : () {
                                      if (!auth.isLoggedIn) {
                                        showLoginPrompt(context);
                                        return;
                                      }
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const CheckoutScreen()),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navyBlue,
                                disabledBackgroundColor: Colors.grey[300],
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                  'Checkout (${_formatPrice(cart.total)})',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(
                color: onTap == null ? Colors.grey[300]! : AppColors.lightBlue),
          ),
          child: Icon(icon,
              size: 16,
              color: onTap == null ? Colors.grey[400] : AppColors.primaryBlue),
        ),
      );

}

Widget _cartItemImage(String url) {
  final isReal = url.isNotEmpty && !url.contains('picsum');
  if (!isReal) {
    return Container(
      width: 90,
      height: 90,
      color: AppColors.veryLightBlue,
      child: const Icon(Icons.home_repair_service_rounded,
          color: AppColors.lightBlue),
    );
  }
  return CachedNetworkImage(
    imageUrl: url,
    width: 90,
    height: 90,
    fit: BoxFit.cover,
    errorWidget: (_, _, _) => Container(
      width: 90,
      height: 90,
      color: AppColors.veryLightBlue,
      child: const Icon(Icons.home_repair_service_rounded,
          color: AppColors.lightBlue),
    ),
  );
}
