import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  String? _userId;
  final Map<String, CartItem> _items = {};

  // No _load() in constructor — we don't know the user yet.
  CartProvider();

  List<CartItem> get items => _items.values.toList();
  int get itemCount => _items.values.fold(0, (s, i) => s + i.quantity);
  double get total => _items.values.fold(0.0, (s, i) => s + i.subtotal);
  bool hasProduct(String productId) => _items.containsKey(productId);

  // ── Per-user storage key ───────────────────────────────────────────────────

  static String _key(String userId) => 'cart_v2_$userId';

  // ── Internal helpers ───────────────────────────────────────────────────────

  Future<void> _loadForUserInternal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null) return;
      final list = jsonDecode(raw) as List;
      for (final e in list) {
        final item = CartItem.fromJson(e as Map<String, dynamic>);
        _items[item.productId] = item;
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key(uid), jsonEncode(_items.values.map((i) => i.toJson()).toList()));
    } catch (_) {}
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Called by ProxyProvider whenever AuthProvider notifies.
  /// Loads the cart on login and saves+unloads on logout automatically.
  void onAuthChanged({required bool isLoggedIn, String? userId}) {
    if (isLoggedIn && userId != null && userId != _userId) {
      loadForUser(userId);
    } else if (!isLoggedIn && _userId != null) {
      saveAndUnload();
    }
  }

  /// Load the cart for [userId] after sign-in.
  /// Switches user context, saving the previous user's cart first if needed.
  Future<void> loadForUser(String userId) async {
    if (_userId == userId) return; // already loaded for this user

    // Save whatever was in memory for the previous user before switching.
    if (_userId != null) await _save();

    _items.clear();
    _userId = userId;
    await _loadForUserInternal(userId);
    notifyListeners();
  }

  /// Save the current cart to storage and unload from memory on sign-out.
  /// The cart is preserved so it reappears when the user signs in again.
  Future<void> saveAndUnload() async {
    await _save(); // persist cart before clearing
    _items.clear();
    _userId = null;
    notifyListeners();
  }

  /// Clear the cart entirely (called after a successful checkout).
  void clear() {
    _items.clear();
    notifyListeners();
    _save(); // save empty list to storage for current user
  }

  // ── Cart operations ────────────────────────────────────────────────────────

  void addItem(Product product, {int quantity = 1}) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity += quantity;
    } else {
      _items[product.id] = CartItem(
        productId: product.id,
        quantity: quantity,
        product: product,
      );
    }
    notifyListeners();
    _save();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
    _save();
  }

  void updateQuantity(String productId, int qty) {
    if (!_items.containsKey(productId)) return;
    if (qty <= 0) {
      removeItem(productId);
    } else {
      _items[productId]!.quantity = qty;
      notifyListeners();
      _save();
    }
  }
}
