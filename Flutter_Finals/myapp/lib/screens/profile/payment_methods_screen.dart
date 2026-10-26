import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/payment_preference_service.dart';

// ── Payment option descriptor (mirrored from checkout) ─────────────────────

class _PayOpt {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool requiresOnline;
  const _PayOpt(this.label, this.subtitle, this.icon, this.color,
      {this.requiresOnline = false});
}

const _payOptions = [
  _PayOpt(
    'Cash on Delivery',
    'Pay when your order arrives',
    Icons.money_outlined,
    AppColors.green,
  ),
  _PayOpt(
    'GCash',
    'Pay via GCash e-wallet',
    Icons.phone_android_outlined,
    Color(0xFF0033A0),
    requiresOnline: true,
  ),
  _PayOpt(
    'Maya',
    'Pay via Maya e-wallet',
    Icons.account_balance_wallet_outlined,
    Color(0xFF00B45A),
    requiresOnline: true,
  ),
  _PayOpt(
    'Credit / Debit Card',
    'Visa, Mastercard, JCB',
    Icons.credit_card_outlined,
    AppColors.primaryBlue,
    requiresOnline: true,
  ),
];

// ──────────────────────────────────────────────────────────────────────────

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  int _selectedIndex = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final idx = await PaymentPreferenceService.getDefaultIndex();
    if (mounted) {
      setState(() => _selectedIndex = idx.clamp(0, _payOptions.length - 1));
    }
  }

  Future<void> _select(int index) async {
    if (index == _selectedIndex || _saving) return;
    setState(() { _selectedIndex = index; _saving = true; });
    await PaymentPreferenceService.setDefault(index, _payOptions[index].label);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_payOptions[index].label} set as your default payment method'),
          backgroundColor: AppColors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.navyBlue, AppColors.primaryBlue]),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Payment Methods',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Info banner ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.veryLightBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.lightBlue.withValues(alpha: 0.5)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: AppColors.primaryBlue, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select your default payment method. It will be '
                    'pre-selected at checkout. Online payments are '
                    'powered by Xendit.',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.darkGrey,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Section label ─────────────────────────────────────────────
          const Text('Default Payment Method',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyBlue)),
          const SizedBox(height: 12),

          // ── Payment options list ──────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6),
              ],
            ),
            child: Column(
              children: _payOptions.asMap().entries.map((entry) {
                final i = entry.key;
                final opt = entry.value;
                final isSelected = _selectedIndex == i;
                return Column(
                  children: [
                    if (i > 0)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                    InkWell(
                      onTap: () => _select(i),
                      borderRadius: i == 0
                          ? const BorderRadius.vertical(
                              top: Radius.circular(12))
                          : i == _payOptions.length - 1
                              ? const BorderRadius.vertical(
                                  bottom: Radius.circular(12))
                              : BorderRadius.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            // Icon badge
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: opt.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(opt.icon,
                                  color: opt.color, size: 22),
                            ),
                            const SizedBox(width: 14),

                            // Label + subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(opt.label,
                                      style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          fontSize: 14,
                                          color: AppColors.darkGrey)),
                                  const SizedBox(height: 2),
                                  Text(opt.subtitle,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.grey)),
                                ],
                              ),
                            ),

                            // Badges + radio
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.green
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Text('Default',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.green,
                                            fontWeight:
                                                FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (opt.requiresOnline && !isSelected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.skyBlue
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Text('Online',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primaryBlue,
                                            fontWeight:
                                                FontWeight.w500)),
                                  ),
                                const SizedBox(width: 8),
                                _saving && isSelected
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primaryBlue),
                                      )
                                    : Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons
                                                .radio_button_unchecked,
                                        color: isSelected
                                            ? AppColors.navyBlue
                                            : AppColors.grey,
                                        size: 22,
                                      ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // ── Current default summary card ───────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.navyBlue.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _payOptions[_selectedIndex]
                        .color
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _payOptions[_selectedIndex].icon,
                    color: _payOptions[_selectedIndex].color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your default method',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.grey)),
                      Text(_payOptions[_selectedIndex].label,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.navyBlue)),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle,
                    color: AppColors.green, size: 22),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Your default will be pre-selected at checkout. '
            'You can always change it during checkout.',
            style: TextStyle(
                fontSize: 12, color: AppColors.grey, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Online payments (GCash, Maya, Card) are securely '
            'handled via Xendit.',
            style: TextStyle(
                fontSize: 12, color: AppColors.grey, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
