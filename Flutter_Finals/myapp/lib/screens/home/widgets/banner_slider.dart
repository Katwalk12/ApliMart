import 'dart:async';
import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  int _current = 0;
  late final PageController _pageController;
  Timer? _timer;

  static const List<_BannerData> _banners = [
    _BannerData(
      title: 'Summer Sale!',
      subtitle: 'Up to 40% off on Air Conditioners',
      icon: Icons.ac_unit_rounded,
      colors: [Color(0xFF0F2C6F), Color(0xFF29B6F6)],
    ),
    _BannerData(
      title: 'Smart TVs',
      subtitle: 'Upgrade your home entertainment',
      icon: Icons.tv_rounded,
      colors: [Color(0xFF1565C0), Color(0xFF4FC3F7)],
    ),
    _BannerData(
      title: 'Free Shipping',
      subtitle: 'On selected appliances this week',
      icon: Icons.local_shipping_rounded,
      colors: [Color(0xFF0D47A1), Color(0xFF1E88E5)],
    ),
    _BannerData(
      title: 'Flash Sale',
      subtitle: 'Limited time deals on refrigerators',
      icon: Icons.kitchen_rounded,
      colors: [Color(0xFF01579B), Color(0xFF039BE5)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      final next = (_current + 1) % _banners.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              final b = _banners[index];
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: b.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Opacity(
                        opacity: 0.15,
                        child: Icon(b.icon, size: 160, color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'ApliMart Deals',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            b.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            b.subtitle,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Shop Now',
                              style: TextStyle(
                                color: AppColors.navyBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _banners.asMap().entries.map((e) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _current == e.key ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: _current == e.key
                    ? AppColors.primaryBlue
                    : AppColors.lightBlue,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BannerData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });
}
