import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';

/// Shows a bottom sheet prompting the guest to sign in.
/// Returns true if the user is already logged in (no sheet shown).
void showLoginPrompt(BuildContext context, {String? reason}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _LoginPromptSheet(reason: reason),
  );
}

class _LoginPromptSheet extends StatelessWidget {
  final String? reason;
  const _LoginPromptSheet({this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.veryLightBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded,
                size: 36, color: AppColors.primaryBlue),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'Sign In to Continue',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.navyBlue),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            reason ?? 'Create an account or sign in to add items\nto your cart and place orders.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.grey, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),

          // Sign In button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Create Account button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.navyBlue, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyBlue),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Continue browsing
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Continue Browsing',
              style: TextStyle(color: AppColors.grey, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
