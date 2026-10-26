import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../home/widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  final _focus = FocusNode();
  List<Product> _results = [];
  bool _loading = false;
  bool _searched = false;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final data = await ProductService.getProducts();
    if (mounted) setState(() { _results = data; _loading = false; });
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      _loadAll();
      return;
    }
    setState(() { _loading = true; _searched = true; });
    final data = await ProductService.getProducts(
      search: query.trim(),
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );
    if (mounted) setState(() { _results = data; _loading = false; });
  }

  Future<void> _filterCategory(String cat) async {
    setState(() { _selectedCategory = cat; _loading = true; });
    final data = await ProductService.getProducts(
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      category: cat == 'All' ? null : cat,
    );
    if (mounted) setState(() { _results = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final categories = ProductService.categories;

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
        titleSpacing: 8,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: TextField(
          controller: _searchCtrl,
          focusNode: _focus,
          autofocus: false,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: 'Search appliances...',
            hintStyle: const TextStyle(color: Colors.white60),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.15),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 20),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      _loadAll();
                      setState(() => _searched = false);
                    },
                  )
                : null,
          ),
          onSubmitted: _search,
          onChanged: (v) {
            setState(() {});
            if (v.isEmpty) _loadAll();
          },
          textInputAction: TextInputAction.search,
        ),
      ),
      body: Column(
        children: [
          // Category filter
          Container(
            height: 44,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat = categories[i]['name'] as String;
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => _filterCategory(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.navyBlue : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.navyBlue
                            : AppColors.lightBlue,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.darkGrey,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Result count
          if (_searched || _searchCtrl.text.isNotEmpty)
            Container(
              color: AppColors.veryLightBlue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Text(
                    '${_results.length} result${_results.length != 1 ? 's' : ''}'
                    '${_searchCtrl.text.isNotEmpty ? ' for "${_searchCtrl.text}"' : ''}',
                    style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

          // Results
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryBlue))
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off,
                                size: 56, color: AppColors.lightBlue),
                            const SizedBox(height: 16),
                            const Text('No products found',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkGrey)),
                            const SizedBox(height: 8),
                            Text(
                              'Try a different search term',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _results.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.50,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemBuilder: (_, i) =>
                            ProductCard(product: _results[i]),
                      ),
          ),
        ],
      ),
    );
  }
}
