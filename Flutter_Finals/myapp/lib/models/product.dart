class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final String category;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final int stock;
  final bool freeShipping;
  final bool isFeatured;
  final int soldCount;
  // star level (1-5) → count of ratings at that level
  final Map<int, int> ratingBreakdown;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.category,
    required this.imageUrl,
    this.rating = 0,
    this.reviewCount = 0,
    this.stock = 0,
    this.freeShipping = false,
    this.isFeatured = false,
    this.soldCount = 0,
    this.ratingBreakdown = const {},
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        price: _toDouble(json['price']),
        originalPrice:
            json['original_price'] != null ? _toDouble(json['original_price']) : null,
        category: json['category']?.toString() ?? '',
        imageUrl: json['image_url']?.toString() ?? '',
        rating: _toDouble(json['rating']),
        reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        freeShipping: json['free_shipping'] as bool? ?? false,
        isFeatured: json['is_featured'] as bool? ?? false,
        soldCount: (json['sold_count'] as num?)?.toInt() ?? 0,
        ratingBreakdown: _parseBreakdown(json['rating_breakdown']),
      );

  static Map<int, int> _parseBreakdown(dynamic val) {
    if (val is! Map) return {};
    final result = <int, int>{};
    for (final e in val.entries) {
      final star = int.tryParse(e.key.toString());
      final count = (e.value as num?)?.toInt() ?? 0;
      if (star != null) result[star] = count;
    }
    return result;
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'original_price': originalPrice,
        'category': category,
        'image_url': imageUrl,
        'rating': rating,
        'review_count': reviewCount,
        'stock': stock,
        'free_shipping': freeShipping,
        'is_featured': isFeatured,
        'sold_count': soldCount,
        'rating_breakdown':
            ratingBreakdown.map((k, v) => MapEntry(k.toString(), v)),
      };

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? originalPrice,
    String? category,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    int? stock,
    bool? freeShipping,
    bool? isFeatured,
    int? soldCount,
    Map<int, int>? ratingBreakdown,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        originalPrice: originalPrice ?? this.originalPrice,
        category: category ?? this.category,
        imageUrl: imageUrl ?? this.imageUrl,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        stock: stock ?? this.stock,
        freeShipping: freeShipping ?? this.freeShipping,
        isFeatured: isFeatured ?? this.isFeatured,
        soldCount: soldCount ?? this.soldCount,
        ratingBreakdown: ratingBreakdown ?? this.ratingBreakdown,
      );

  int get discountPercent {
    if (originalPrice == null || originalPrice! <= price) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).round();
  }

  String get formattedPrice => _formatPrice(price);
  String get formattedOriginalPrice =>
      originalPrice != null ? _formatPrice(originalPrice!) : '';

  static String _formatPrice(double p) {
    final s = p.toStringAsFixed(0);
    final buffer = StringBuffer('₱');
    final start = s.length % 3;
    if (start > 0) buffer.write(s.substring(0, start));
    for (int i = start; i < s.length; i += 3) {
      if (i > 0) buffer.write(',');
      buffer.write(s.substring(i, i + 3));
    }
    return buffer.toString();
  }
}
