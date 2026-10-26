import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../cart/cart_screen.dart';
import '../search/search_screen.dart';
import 'widgets/banner_slider.dart';
import 'widgets/category_section.dart';
import 'widgets/flash_sale_section.dart';
import 'widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<ProductProvider>().load());
  }

  void _onCategoryChanged(String cat) {
    context.read<ProductProvider>().setCategory(cat);
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();
    final products = pp.products;
    final loading = pp.loading;
    final selectedCategory = pp.selectedCategory;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: () => context.read<ProductProvider>().load(),
        child: CustomScrollView(
        slivers: [
          // Custom AppBar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.navyBlue,
            expandedHeight: 56,
            collapsedHeight: 56,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.navyBlue, AppColors.darkBlue],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            titleSpacing: 12,
            title: Row(
              children: [
                if (MediaQuery.of(context).size.width < 900) ...[
                  const Text(
                    'ApliMart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SearchScreen())),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.search,
                              color: AppColors.grey, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Search appliances...',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              Consumer<CartProvider>(
                builder: (_, cart, _) => Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined,
                          color: Colors.white),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CartScreen())),
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${cart.itemCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Body content
          SliverToBoxAdapter(
            child: Column(
              children: [
                const BannerSlider(),
                CategorySection(
                  selectedCategory: selectedCategory,
                  onCategorySelected: _onCategoryChanged,
                ),
                const FlashSaleSection(),
                // Section header
                Container(
                  color: Colors.white,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedCategory == 'All'
                            ? 'For You'
                            : selectedCategory,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Product grid — responsive columns & aspect ratio
          Builder(builder: (context) {
            final w = MediaQuery.of(context).size.width;
            final cols = w < 600 ? 2 : w < 900 ? 3 : 4;
            final ratio = w < 600 ? 0.52 : w < 900 ? 0.56 : 0.61;
            final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              childAspectRatio: ratio,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            );
            if (loading) {
              return SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, _) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    childCount: cols * 3,
                  ),
                  gridDelegate: gridDelegate,
                ),
              );
            }
            if (products.isEmpty) {
              return SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  height: 200,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 48, color: AppColors.lightBlue),
                        SizedBox(height: 12),
                        Text('No products found',
                            style: TextStyle(color: AppColors.grey)),
                      ],
                    ),
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => ProductCard(product: products[i]),
                  childCount: products.length,
                ),
                gridDelegate: gridDelegate,
              ),
            );
          }),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
        ),
      ),
    );
  }
}
