import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/message_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import '../messages/messages_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const List<Widget> _screens = [
    HomeScreen(),
    MessagesScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) {
        context.read<NotificationProvider>().load(auth.user!.id);
        context.read<MessageProvider>().load(auth.user!.id);
      }
    });
  }

  static IconData _destIcon(int i, bool active) {
    switch (i) {
      case 0: return active ? Icons.home : Icons.home_outlined;
      case 1: return active ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded;
      case 2: return active ? Icons.notifications : Icons.notifications_outlined;
      default: return active ? Icons.person : Icons.person_outline;
    }
  }

  static Widget _buildNavIcon(
      int i, bool active, int notifUnread, int msgUnseen) {
    if (i == 1 && msgUnseen > 0) {
      return Badge(
        label: Text('$msgUnseen', style: const TextStyle(fontSize: 9)),
        child: Icon(_destIcon(i, active)),
      );
    }
    if (i == 2 && notifUnread > 0) {
      return Badge(
        label: Text('$notifUnread', style: const TextStyle(fontSize: 9)),
        child: Icon(_destIcon(i, active)),
      );
    }
    return Icon(_destIcon(i, active));
  }

  static String _destLabel(int i) {
    switch (i) {
      case 0: return 'Home';
      case 1: return 'Messages';
      case 2: return 'Alerts';
      default: return 'Profile';
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav   = context.watch<NavigationProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final unread = notifProvider.unreadCount;
    final msgProvider = context.watch<MessageProvider>();
    final msgUnseen = msgProvider.unseenCount;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.offWhite,
        body: Row(
          children: [
            // ── Side navigation rail ──────────────────────────────
            Container(
              color: AppColors.navyBlue,
              child: NavigationRail(
                backgroundColor: AppColors.navyBlue,
                selectedIndex: nav.currentIndex,
                onDestinationSelected: (i) {
                  if (i == 1) msgProvider.markSeen();
                  context.read<NavigationProvider>().goToTab(i);
                },
                labelType: NavigationRailLabelType.all,
                minWidth: 80,
                selectedIconTheme:
                    const IconThemeData(color: Colors.white, size: 24),
                unselectedIconTheme:
                    const IconThemeData(color: Colors.white54, size: 22),
                selectedLabelTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11),
                unselectedLabelTextStyle: const TextStyle(
                    color: Colors.white54, fontSize: 11),
                leading: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Column(
                    children: const [
                      Icon(Icons.home_repair_service_rounded,
                          color: Colors.white, size: 30),
                      SizedBox(height: 4),
                      Text('ApliMart',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
                destinations: [
                  for (int di = 0; di < 4; di++)
                    NavigationRailDestination(
                      icon: _buildNavIcon(di, false, unread, msgUnseen),
                      selectedIcon: _buildNavIcon(di, true, unread, msgUnseen),
                      label: Text(_destLabel(di)),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),

            // ── Main content (max 1280 px, centred) ──────────────
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: IndexedStack(
                    index: nav.currentIndex,
                    children: _screens,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Mobile layout ─────────────────────────────────────────────
    return Scaffold(
      body: IndexedStack(
        index: nav.currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: nav.currentIndex,
          onTap: (i) {
            if (i == 1) msgProvider.markSeen();
            context.read<NavigationProvider>().goToTab(i);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.grey,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          backgroundColor: Colors.white,
          elevation: 0,
          items: [
            for (int di = 0; di < 4; di++)
              BottomNavigationBarItem(
                icon: _buildNavIcon(di, false, unread, msgUnseen),
                activeIcon: _buildNavIcon(di, true, unread, msgUnseen),
                label: _destLabel(di),
              ),
          ],
        ),
      ),
    );
  }
}
