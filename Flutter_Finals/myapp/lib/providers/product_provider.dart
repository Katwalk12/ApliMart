import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _all = [];
  bool _loading = false;
  String _category = 'All';

  List<Product> get all => _all;
  bool get loading => _loading;
  String get selectedCategory => _category;

  List<Product> get products {
    if (_category == 'All') return _all;
    return _all.where((p) => p.category == _category).toList();
  }

  List<Product> get flashSale => _all
      .where((p) => p.originalPrice != null)
      .take(8)
      .toList();

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _all = await ProductService.getProducts();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  void setCategory(String cat) {
    _category = cat;
    notifyListeners();
  }

  /// Immediately restores stock and decrements soldCount in memory on cancellation
  /// so the UI reflects the change before the DB roundtrip completes.
  void restoreStockLocally(List<OrderItem> items) {
    for (final item in items) {
      final idx = _all.indexWhere((p) => p.id == item.productId);
      if (idx == -1) continue;
      final p = _all[idx];
      _all[idx] = p.copyWith(
        stock: p.stock + item.quantity,
        soldCount: (p.soldCount - item.quantity).clamp(0, p.soldCount),
      );
    }
    notifyListeners();
  }

  /// Immediately decrements stock and increments soldCount in memory at checkout
  /// so the UI reflects the purchase before the DB roundtrip completes.
  void updateStockLocally(List<CartItem> items) {
    for (final item in items) {
      final idx = _all.indexWhere((p) => p.id == item.productId);
      if (idx == -1) continue;
      final p = _all[idx];
      _all[idx] = p.copyWith(
        stock: (p.stock - item.quantity).clamp(0, p.stock),
        soldCount: p.soldCount + item.quantity,
      );
    }
    notifyListeners();
  }
}
