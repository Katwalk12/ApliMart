import 'product.dart';

class CartItem {
  final String productId;
  int quantity;
  final Product product;

  CartItem({
    required this.productId,
    required this.quantity,
    required this.product,
  });

  double get subtotal => product.price * quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'quantity': quantity,
        'product': product.toJson(),
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId'] as String,
        quantity: json['quantity'] as int,
        product: Product.fromJson(json['product'] as Map<String, dynamic>),
      );
}
