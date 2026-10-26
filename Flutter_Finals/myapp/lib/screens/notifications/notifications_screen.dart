import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../orders/orders_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      context.read<NotificationProvider>().load(auth.user!.id);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showDetail(AppNotification n) {
    if (!n.isRead) {
      context.read<NotificationProvider>().markOneRead(n.id);
    }
    final color = n.type.color;
    final df = '${n.createdAt.day}/${n.createdAt.month}/${n.createdAt.year}'
        '  ${n.createdAt.hour.toString().padLeft(2, '0')}'
        ':${n.createdAt.minute.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // icon
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(n.type.icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            // title
            Text(n.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyBlue)),
            const SizedBox(height: 10),
            // body
            Text(n.body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.darkGrey, height: 1.5)),
            const SizedBox(height: 12),
            // timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time,
                    size: 13, color: AppColors.grey),
                const SizedBox(width: 4),
                Text(df,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.grey)),
              ],
            ),
            if (n.orderId.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const OrdersScreen()),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('View My Orders'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notifProvider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.navyBlue, AppColors.darkBlue],
            ),
          ),
        ),
        title: const Text('Notifications',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (notifProvider.unreadCount > 0)
            TextButton(
              onPressed: () {
                if (auth.isLoggedIn) {
                  notifProvider.markAllRead(auth.user!.id);
                }
              },
              child: const Text('Mark all read',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
            onPressed: () {
              if (auth.isLoggedIn) {
                notifProvider.refresh(auth.user!.id);
              }
            },
          ),
        ],
      ),
      backgroundColor: AppColors.offWhite,
      body: !auth.isLoggedIn
          ? const Center(
              child: Text('Log in to see notifications',
                  style: TextStyle(color: AppColors.grey)))
          : notifProvider.loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryBlue))
              : notifProvider.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_off_outlined,
                              size: 56, color: AppColors.lightBlue),
                          const SizedBox(height: 16),
                          const Text('No notifications yet',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkGrey)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () =>
                                notifProvider.refresh(auth.user!.id),
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          notifProvider.refresh(auth.user!.id),
                      color: AppColors.primaryBlue,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: notifProvider.items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final n = notifProvider.items[i];
                          final color = n.type.color;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showDetail(n),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                            decoration: BoxDecoration(
                              color: n.isRead
                                  ? Colors.white
                                  : color.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: n.isRead
                                  ? null
                                  : Border.all(
                                      color:
                                          color.withValues(alpha: 0.2)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.04),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(n.type.icon,
                                    color: color, size: 22),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(n.title,
                                        style: TextStyle(
                                            fontWeight: n.isRead
                                                ? FontWeight.w500
                                                : FontWeight.bold,
                                            fontSize: 13,
                                            color: AppColors.navyBlue)),
                                  ),
                                  if (!n.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(n.body,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.darkGrey)),
                                  const SizedBox(height: 4),
                                  Text(_timeAgo(n.createdAt),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.grey)),
                                ],
                              ),
                            ),
                          ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
