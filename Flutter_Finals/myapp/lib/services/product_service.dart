import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';

class ProductService {
  static dynamic get _db {
    if (!SupabaseConfig.isConfigured) return null;
    return Supabase.instance.client.from('products');
  }

  static Future<List<Product>> getProducts({
    String? category,
    String? search,
  }) async {
    final db = _db;
    if (db == null) return [];
    try {
      dynamic query = db.select();
      if (category != null && category.isNotEmpty && category != 'All') {
        query = query.eq('category', category);
      }
      if (search != null && search.isNotEmpty) {
        query = query.ilike('name', '%$search%');
      }
      final data = await query.order('created_at', ascending: false);
      return (data as List).map((e) => Product.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Product>> getFlashSaleProducts() async {
    final db = _db;
    if (db == null) return [];
    try {
      final data = await db
          .select()
          .not('original_price', 'is', null)
          .order('sold_count', ascending: false)
          .limit(8);
      return (data as List).map((e) => Product.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Product>> getFeaturedProducts() async {
    final db = _db;
    if (db == null) return [];
    try {
      final data = await db
          .select()
          .eq('is_featured', true)
          .order('sold_count', ascending: false)
          .limit(10);
      return (data as List).map((e) => Product.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Product?> getProduct(String id) async {
    final db = _db;
    if (db == null) return null;
    try {
      final data = await db.select().eq('id', id).single();
      return Product.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Restores stock and decrements sold_count when an order is cancelled.
  /// Reads fresh values from the DB to avoid stale in-memory data.
  static Future<void> restoreStock(List<OrderItem> items) async {
    if (!SupabaseConfig.isConfigured) return;
    final client = Supabase.instance.client;
    for (final item in items) {
      try {
        final pData = await client
            .from('products')
            .select('stock, sold_count')
            .eq('id', item.productId)
            .maybeSingle();
        if (pData == null) continue;
        final currentStock = (pData['stock'] as num?)?.toInt() ?? 0;
        final currentSold = (pData['sold_count'] as num?)?.toInt() ?? 0;
        await client.from('products').update({
          'stock': currentStock + item.quantity,
          'sold_count': (currentSold - item.quantity).clamp(0, currentSold),
        }).eq('id', item.productId);
      } catch (_) {}
    }
  }

  /// Upserts a rating (and optional review text) for the current user, then
  /// recalculates the true average and per-star breakdown from all rows.
  /// The unique(user_id, product_id) constraint prevents duplicate counts.
  // SQL: alter table product_ratings
  //        add column if not exists review_text  text        default '',
  //        add column if not exists reviewer_name text       default 'Anonymous',
  //        add column if not exists created_at   timestamptz default now();
  static Future<void> submitRating(
    String productId,
    double newRating, {
    String reviewText = '',
    String reviewerName = 'Anonymous',
  }) async {
    if (!SupabaseConfig.isConfigured) return;
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await client.from('product_ratings').upsert({
        'user_id': userId,
        'product_id': productId,
        'rating': newRating,
        'review_text': reviewText.trim(),
        'reviewer_name': reviewerName,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,product_id');

      // Recalculate true average from all ratings for this product
      final rows = await client
          .from('product_ratings')
          .select('rating')
          .eq('product_id', productId);

      final ratings = (rows as List)
          .map((r) => (r['rating'] as num).toDouble())
          .toList();
      final count = ratings.length;
      final avg = count > 0
          ? ratings.reduce((a, b) => a + b) / count
          : 0.0;

      final breakdown = <String, int>{
        '1': 0, '2': 0, '3': 0, '4': 0, '5': 0
      };
      for (final r in ratings) {
        final star = r.round().clamp(1, 5).toString();
        breakdown[star] = (breakdown[star] ?? 0) + 1;
      }

      await client.from('products').update({
        'rating': double.parse(avg.toStringAsFixed(1)),
        'review_count': count,
        'rating_breakdown': breakdown,
      }).eq('id', productId);
    } catch (e) {
      debugPrint('submitRating error: $e');
    }
  }

  /// Returns all ratings (with or without review text) for [productId],
  /// sorted newest first. Requires the "Public view all ratings" RLS policy.
  static Future<List<Map<String, dynamic>>> getReviews(
      String productId) async {
    if (!SupabaseConfig.isConfigured) return [];
    try {
      final rows = await Supabase.instance.client
          .from('product_ratings')
          .select('rating, review_text, reviewer_name, created_at')
          .eq('product_id', productId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (_) {
      return [];
    }
  }

  /// Returns the current user's existing rating row {rating, review_text},
  /// or null if the user has not yet rated this product.
  static Future<Map<String, dynamic>?> getUserRating(
      String productId) async {
    if (!SupabaseConfig.isConfigured) return null;
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final row = await client
          .from('product_ratings')
          .select('rating, review_text')
          .eq('product_id', productId)
          .eq('user_id', userId)
          .maybeSingle();
      return row;
    } catch (_) {
      return null;
    }
  }

  /// Decrements stock and increments sold_count at checkout.
  /// Reads fresh values from the DB (not the local cache) to avoid stale data
  /// causing the count to reset on the next product refresh.
  static Future<void> recordSale(List<CartItem> items) async {
    if (!SupabaseConfig.isConfigured) return;
    final client = Supabase.instance.client;
    for (final item in items) {
      try {
        final pData = await client
            .from('products')
            .select('stock, sold_count')
            .eq('id', item.productId)
            .maybeSingle();
        if (pData == null) continue;
        final currentStock = (pData['stock'] as num?)?.toInt() ?? 0;
        final currentSold = (pData['sold_count'] as num?)?.toInt() ?? 0;
        await client.from('products').update({
          'stock': (currentStock - item.quantity).clamp(0, currentStock),
          'sold_count': currentSold + item.quantity,
        }).eq('id', item.productId);
      } catch (_) {}
    }
  }

  static List<Map<String, dynamic>> get categories => [
        {'name': 'All', 'icon': '🏪'},
        {'name': 'Television', 'icon': '📺'},
        {'name': 'Refrigerator', 'icon': '🧊'},
        {'name': 'Washing Machine', 'icon': '🫧'},
        {'name': 'Air Conditioner', 'icon': '❄️'},
        {'name': 'Fan', 'icon': '💨'},
        {'name': 'Microwave', 'icon': '📡'},
        {'name': 'Vacuum Cleaner', 'icon': '🧹'},
      ];
}
