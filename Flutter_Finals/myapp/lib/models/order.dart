import 'package:flutter/material.dart';

enum OrderStatus { pending, processing, pickedUp, shipped, delivered, cancelled, cancelRequested }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:         return 'Pending';
      case OrderStatus.processing:      return 'Approved';
      case OrderStatus.pickedUp:        return 'Picked Up';
      case OrderStatus.shipped:         return 'On the Way';
      case OrderStatus.delivered:       return 'Delivered';
      case OrderStatus.cancelled:       return 'Cancelled';
      case OrderStatus.cancelRequested: return 'Cancel Requested';
    }
  }

  String get supabaseValue {
    switch (this) {
      case OrderStatus.pending:         return 'pending';
      case OrderStatus.processing:      return 'processing';
      case OrderStatus.pickedUp:        return 'picked_up';
      case OrderStatus.shipped:         return 'shipped';
      case OrderStatus.delivered:       return 'delivered';
      case OrderStatus.cancelled:       return 'cancelled';
      case OrderStatus.cancelRequested: return 'cancel_requested';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:         return const Color(0xFFFF6B2B);
      case OrderStatus.processing:      return const Color(0xFF1976D2);
      case OrderStatus.pickedUp:        return const Color(0xFFFF9800);
      case OrderStatus.shipped:         return const Color(0xFF29B6F6);
      case OrderStatus.delivered:       return const Color(0xFF43A047);
      case OrderStatus.cancelled:       return const Color(0xFFE53935);
      case OrderStatus.cancelRequested: return const Color(0xFFFF8F00);
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:         return Icons.hourglass_empty_rounded;
      case OrderStatus.processing:      return Icons.check_circle_outline;
      case OrderStatus.pickedUp:        return Icons.inventory_2_outlined;
      case OrderStatus.shipped:         return Icons.local_shipping_outlined;
      case OrderStatus.delivered:       return Icons.check_circle_outline_rounded;
      case OrderStatus.cancelled:       return Icons.cancel_outlined;
      case OrderStatus.cancelRequested: return Icons.pending_actions_outlined;
    }
  }

  static OrderStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'processing':        return OrderStatus.processing;
      case 'picked_up':         return OrderStatus.pickedUp;
      case 'shipped':           return OrderStatus.shipped;
      case 'delivered':         return OrderStatus.delivered;
      case 'cancelled':         return OrderStatus.cancelled;
      case 'cancel_requested':  return OrderStatus.cancelRequested;
      // legacy values
      case 'to_ship':     return OrderStatus.processing;
      case 'to_receive':  return OrderStatus.shipped;
      case 'completed':   return OrderStatus.delivered;
      default:            return OrderStatus.pending;
    }
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String imageUrl;
  final double price;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId:   json['product_id']?.toString()   ?? '',
        productName: json['product_name']?.toString() ?? '',
        imageUrl:    json['image_url']?.toString()    ?? '',
        price:       (json['price'] as num?)?.toDouble() ?? 0,
        quantity:    (json['quantity'] as num?)?.toInt()  ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'product_id':   productId,
        'product_name': productName,
        'image_url':    imageUrl,
        'price':        price,
        'quantity':     quantity,
      };
}

class Order {
  final String id;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingFee;
  final double vatAmount;      // 12% BIR VAT
  final double serviceFee;     // 1% platform/e-commerce fee
  final OrderStatus status;
  final String address;
  final String paymentMethod;
  final DateTime createdAt;
  final String? cancellationReason;

  const Order({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    this.vatAmount = 0,
    this.serviceFee = 0,
    required this.status,
    required this.address,
    required this.paymentMethod,
    required this.createdAt,
    this.cancellationReason,
  });

  double get total => subtotal + vatAmount + serviceFee + shippingFee;
  int get itemCount => items.fold(0, (s, i) => s + i.quantity);
  String get orderNumber => 'APM-${id.replaceAll('-', '').substring(0, 8).toUpperCase()}';

  Map<String, dynamic> toJson() => {
        'id':                   id,
        'items':                items.map((i) => i.toJson()).toList(),
        'subtotal':             subtotal,
        'shipping_fee':         shippingFee,
        'vat_amount':           vatAmount,
        'service_fee':          serviceFee,
        'status':               status.supabaseValue,
        'address':              address,
        'payment_method':       paymentMethod,
        'created_at':           createdAt.toIso8601String(),
        if (cancellationReason != null)
          'cancellation_reason': cancellationReason,
      };

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final itemsList = rawItems is List ? rawItems : [];
    return Order(
      id:                 json['id']?.toString() ?? '',
      items:              itemsList
                            .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
                            .toList(),
      subtotal:           (json['subtotal'] as num?)?.toDouble() ?? 0,
      shippingFee:        (json['shipping_fee'] as num?)?.toDouble() ?? 150,
      vatAmount:          (json['vat_amount'] as num?)?.toDouble() ?? 0,
      serviceFee:         (json['service_fee'] as num?)?.toDouble() ?? 0,
      status:             OrderStatusX.fromString(json['status']?.toString() ?? 'pending'),
      address:            json['address']?.toString() ?? '',
      paymentMethod:      json['payment_method']?.toString() ?? '',
      createdAt:          DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      cancellationReason: json['cancellation_reason']?.toString(),
    );
  }

  factory Order.fromSupabaseJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final itemsList = rawItems is List ? rawItems : [];
    return Order(
      id:                 json['id']?.toString() ?? '',
      items:              itemsList
                            .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
                            .toList(),
      subtotal:           (json['subtotal'] as num?)?.toDouble() ?? 0,
      shippingFee:        (json['shipping_fee'] as num?)?.toDouble() ?? 150,
      vatAmount:          (json['vat_amount'] as num?)?.toDouble() ?? 0,
      serviceFee:         (json['service_fee'] as num?)?.toDouble() ?? 0,
      status:             OrderStatusX.fromString(json['status']?.toString() ?? 'pending'),
      address:            json['address']?.toString() ?? '',
      paymentMethod:      json['payment_method']?.toString() ?? '',
      createdAt:          DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      cancellationReason: json['cancellation_reason']?.toString(),
    );
  }

  static String formatPrice(double p) {
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

  String get formattedTotal => formatPrice(total);
}
