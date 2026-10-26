import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';
import '../admin/admin_screen.dart';
import '../auth/login_screen.dart';
import '../delivery/delivery_screen.dart';
import '../auth/register_screen.dart';
import '../main/main_screen.dart';
import '../notifications/notifications_screen.dart';
import '../orders/orders_screen.dart';
import 'edit_profile_screen.dart';
import 'info_screens.dart';
import 'my_addresses_screen.dart';
import 'payment_methods_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (!auth.isLoggedIn) {
          return _GuestProfileScreen();
        }
        return _LoggedInProfileScreen(auth: auth);
      },
    );
  }
}

// ─── Guest ───────────────────────────────────────────────────────────────────

class _GuestProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.navyBlue, AppColors.primaryBlue],
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24,
                bottom: 28,
                left: 24,
                right: 24,
              ),
              child: Column(
                children: [
                  // Centered profile picture
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const Icon(Icons.person,
                        color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 10),
                  const Text('Guest User',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  // Log In / Sign Up buttons below
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.navyBlue,
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Log In',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Colors.white, width: 1.5),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Sign Up',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Help & Support
            Padding(
              padding: const EdgeInsets.all(16),
              child: _sectionCard(
                title: 'Help & Support',
                icon: Icons.help_outline,
                iconColor: AppColors.green,
                items: [
                  _menuItem(context, Icons.headset_mic_outlined,
                      'Customer Service',
                      () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CustomerServiceScreen()))),
                  _menuItem(context, Icons.info_outline,
                      'About ApliMart',
                      () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AboutScreen()))),
                  _menuItem(context, Icons.policy_outlined,
                      'Privacy Policy',
                      () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Logged-in ───────────────────────────────────────────────────────────────

class _LoggedInProfileScreen extends StatelessWidget {
  final AuthProvider auth;
  const _LoggedInProfileScreen({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      // ── Fixed header ────────────────────────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.navyBlue, AppColors.primaryBlue],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    auth.displayName[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(auth.displayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text(auth.user?.email ?? '',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      // ── Scrollable body ─────────────────────────────────────────
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _statItemTap(
                    context,
                    'Orders',
                    '${context.watch<OrderProvider>().orders.length}',
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const OrdersScreen())),
                  ),
                  _divider(),
                  _statItem('Wishlist', '5'),
                  _divider(),
                  Consumer<CartProvider>(
                    builder: (_, cart, _) =>
                        _statItem('Cart', '${cart.itemCount}'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // My Orders
            _sectionCard(
              title: 'My Orders',
              icon: Icons.receipt_long_outlined,
              iconColor: AppColors.primaryBlue,
              items: [
                _menuItem(context, Icons.pending_outlined, 'Pending Orders',
                    () => _goOrders(context, OrderStatus.pending)),
                _menuItem(context, Icons.settings_outlined, 'Processing',
                    () => _goOrders(context, OrderStatus.processing)),
                _menuItem(context, Icons.local_shipping_outlined, 'Shipped',
                    () => _goOrders(context, OrderStatus.shipped)),
                _menuItem(context, Icons.check_circle_outline, 'Delivered',
                    () => _goOrders(context, OrderStatus.delivered)),
              ],
            ),
            const SizedBox(height: 12),

            // Account Settings
            _sectionCard(
              title: 'Account Settings',
              icon: Icons.settings_outlined,
              iconColor: AppColors.skyBlue,
              items: [
                _menuItem(context, Icons.person_outline, 'Edit Profile',
                    () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const EditProfileScreen()))),
                _menuItem(context, Icons.location_on_outlined,
                    'My Addresses', () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MyAddressesScreen()))),
                _menuItem(context, Icons.payment_outlined,
                    'Payment Methods', () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()))),
                _menuItem(context, Icons.notifications_outlined,
                    'Notifications', () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
              ],
            ),
            const SizedBox(height: 12),

            // Help & Support
            _sectionCard(
              title: 'Help & Support',
              icon: Icons.help_outline,
              iconColor: AppColors.green,
              items: [
                _menuItem(context, Icons.headset_mic_outlined,
                    'Customer Service',
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CustomerServiceScreen()))),
                _menuItem(context, Icons.info_outline,
                    'About ApliMart',
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()))),
                _menuItem(context, Icons.policy_outlined,
                    'Privacy Policy',
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
              ],
            ),

            // Admin panel
            if (auth.isAdmin) ...[
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Admin',
                icon: Icons.admin_panel_settings_outlined,
                iconColor: AppColors.red,
                items: [
                  _menuItem(
                    context,
                    Icons.dashboard_outlined,
                    'Admin Dashboard',
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AdminScreen())),
                  ),
                ],
              ),
            ],

            // Rider / Delivery panel
            if (auth.isRider) ...[
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Delivery',
                icon: Icons.delivery_dining,
                iconColor: const Color(0xFF29B6F6),
                items: [
                  _menuItem(
                    context,
                    Icons.local_shipping_outlined,
                    'Delivery Dashboard',
                    () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const DeliveryScreen())),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Sign Out
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await context.read<CartProvider>().saveAndUnload();
                  if (!context.mounted) return;
                  context.read<OrderProvider>().clear();
                  context.read<NotificationProvider>().clear();
                  await auth.signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                    (_) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: AppColors.red),
                label: const Text('Sign Out',
                    style: TextStyle(
                        color: AppColors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.red),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

Widget _statItemTap(
        BuildContext context, String label, String value, VoidCallback onTap) =>
    Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyBlue)),
            Text(label,
                style: const TextStyle(color: AppColors.grey, fontSize: 12)),
          ],
        ),
      ),
    );

Widget _statItem(String label, String value) => Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyBlue)),
          Text(label,
              style: const TextStyle(color: AppColors.grey, fontSize: 12)),
        ],
      ),
    );

Widget _divider() =>
    Container(height: 40, width: 1, color: AppColors.lightBlue);

Widget _sectionCard({
  required String title,
  required IconData icon,
  required Color iconColor,
  required List<Widget> items,
}) =>
    Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.navyBlue)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...items,
        ],
      ),
    );

Widget _menuItem(BuildContext context, IconData icon, String label,
        VoidCallback onTap) =>
    InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.darkGrey)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey, size: 20),
          ],
        ),
      ),
    );

void _goOrders(BuildContext context, OrderStatus status) => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrdersScreen(initialTab: status)),
    );

