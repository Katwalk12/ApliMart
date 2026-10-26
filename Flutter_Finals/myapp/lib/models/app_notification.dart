import 'package:flutter/material.dart';
import '../config/app_theme.dart';

enum NotifType {
  orderApproved,
  orderPickedUp,
  orderOnTheWay,
  orderDelivered,
  orderCancelled,
  cancellationApproved,
}

extension NotifTypeX on NotifType {
  String get value {
    switch (this) {
      case NotifType.orderApproved:  return 'order_approved';
      case NotifType.orderPickedUp:  return 'order_picked_up';
      case NotifType.orderOnTheWay:  return 'order_on_the_way';
      case NotifType.orderDelivered: return 'order_delivered';
      case NotifType.orderCancelled:       return 'order_cancelled';
      case NotifType.cancellationApproved: return 'cancellation_approved';
    }
  }

  static NotifType fromString(String s) {
    switch (s) {
      case 'order_picked_up':        return NotifType.orderPickedUp;
      case 'order_on_the_way':       return NotifType.orderOnTheWay;
      case 'order_delivered':        return NotifType.orderDelivered;
      case 'order_cancelled':        return NotifType.orderCancelled;
      case 'cancellation_approved':  return NotifType.cancellationApproved;
      default:                       return NotifType.orderApproved;
    }
  }

  IconData get icon {
    switch (this) {
      case NotifType.orderApproved:        return Icons.check_circle_outline;
      case NotifType.orderPickedUp:        return Icons.inventory_2_outlined;
      case NotifType.orderOnTheWay:        return Icons.local_shipping_outlined;
      case NotifType.orderDelivered:       return Icons.check_circle_rounded;
      case NotifType.orderCancelled:       return Icons.cancel_outlined;
      case NotifType.cancellationApproved: return Icons.cancel_outlined;
    }
  }

  Color get color {
    switch (this) {
      case NotifType.orderApproved:        return AppColors.green;
      case NotifType.orderPickedUp:        return const Color(0xFFFF9800);
      case NotifType.orderOnTheWay:        return const Color(0xFF29B6F6);
      case NotifType.orderDelivered:       return AppColors.green;
      case NotifType.orderCancelled:       return AppColors.red;
      case NotifType.cancellationApproved: return AppColors.red;
    }
  }
}

class AppNotification {
  final String id;
  final String userId;
  final String orderId;
  final NotifType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id:        j['id']?.toString() ?? '',
        userId:    j['user_id']?.toString() ?? '',
        orderId:   j['order_id']?.toString() ?? '',
        type:      NotifTypeX.fromString(j['type']?.toString() ?? ''),
        title:     j['title']?.toString() ?? '',
        body:      j['body']?.toString() ?? '',
        isRead:    j['is_read'] == true,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}
