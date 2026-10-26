import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../config/xendit_config.dart';
import '../../models/cart_item.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/address_service.dart';
import '../../services/payment_preference_service.dart';
import '../../services/product_service.dart';
import '../../services/xendit_service.dart';
import '../orders/order_detail_screen.dart';

// ── Payment option descriptor ──────────────────────────────────────────────

class _PayOpt {
  final String label;
  final IconData icon;
  final Color color;
  final List<String>? xenditMethods;
  const _PayOpt(this.label, this.icon, this.color, this.xenditMethods);
}

const _payOptions = [
  _PayOpt('Cash on Delivery', Icons.money_outlined, AppColors.green, null),
  _PayOpt('GCash', Icons.phone_android_outlined, Color(0xFF0033A0), ['GCASH']),
  _PayOpt('Maya', Icons.account_balance_wallet_outlined, Color(0xFF00B45A), ['PAYMAYA']),
  _PayOpt('Credit / Debit Card', Icons.credit_card_outlined, AppColors.primaryBlue,
      ['CREDIT_CARD']),
];

// ──────────────────────────────────────────────────────────────────────────

class CheckoutScreen extends StatefulWidget {
  final List<CartItem>? directItems;
  const CheckoutScreen({super.key, this.directItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<SavedAddress> _addresses = [];
  int _selectedIndex = 0;
  double _shippingFee = 0; // 0 = standard (free), 150 = express
  _PayOpt _selectedPay = _payOptions.first;
  bool _placing = false;
  String? _xenditError;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _loadPaymentPref();
  }

  Future<void> _loadAddresses() async {
    final addresses = await AddressService.loadAll();
    final defaultIdx = await AddressService.getDefaultIndex();
    if (mounted) {
      setState(() {
        _addresses = addresses;
        _selectedIndex =
            defaultIdx.clamp(0, addresses.isEmpty ? 0 : addresses.length - 1);
      });
    }
  }

  Future<void> _loadPaymentPref() async {
    final idx = await PaymentPreferenceService.getDefaultIndex();
    if (mounted) {
      setState(() =>
          _selectedPay = _payOptions[idx.clamp(0, _payOptions.length - 1)]);
    }
  }

  SavedAddress? get _selectedAddress =>
      _addresses.isEmpty ? null : _addresses[_selectedIndex];

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = widget.directItems ?? cart.items;
    final subtotal = items.fold(0.0, (s, i) => s + i.subtotal);
    final vatAmount = subtotal * 0.12;           // 12% VAT (Net Price × 0.12)
    final total = subtotal + vatAmount + _shippingFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // ── Address ───────────────────────────────────────────────────
          _addressCard(context),
          const SizedBox(height: 16),

          // ── Items ─────────────────────────────────────────────────────
          _sectionLabel('Items'),
          const SizedBox(height: 8),
          _itemsCard(items),
          const SizedBox(height: 16),

          // ── Shipping ──────────────────────────────────────────────────
          _sectionLabel('Shipping option'),
          const SizedBox(height: 8),
          _shippingCard(),
          const SizedBox(height: 16),

          // ── Voucher ───────────────────────────────────────────────────
          _sectionLabel('Voucher'),
          const SizedBox(height: 8),
          _voucherTile(),
          const SizedBox(height: 16),

          // ── Payment ───────────────────────────────────────────────────
          _sectionLabel('Payment Method'),
          const SizedBox(height: 8),
          _paymentCard(context),
          const SizedBox(height: 16),

          // ── Order summary ─────────────────────────────────────────────
          _summaryCard(subtotal, vatAmount, total),
          const SizedBox(height: 12),

          if (_xenditError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.red.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_xenditError!,
                        style: const TextStyle(
                            color: AppColors.red, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Place Order button ─────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _placing
                  ? null
                  : () => _submit(
                      context, cart, items, total, vatAmount),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                disabledBackgroundColor: Colors.black38,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                elevation: 0,
              ),
              child: _placing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      _selectedPay.xenditMethods == null
                          ? 'Place Order · ${Order.formatPrice(total)}'
                          : 'Pay ${Order.formatPrice(total)} via ${_selectedPay.label}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Address card ──────────────────────────────────────────────────────────

  Widget _addressCard(BuildContext context) {
    final addr = _selectedAddress;
    return GestureDetector(
      onTap: () => _showAddressPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: _cardDecor(),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined,
                size: 22, color: Colors.black87),
            const SizedBox(width: 12),
            Expanded(
              child: addr == null
                  ? const Text('Add delivery address',
                      style:
                          TextStyle(color: Colors.black54, fontSize: 14))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              addr.label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.black87),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              addr.phone,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${addr.name} · ${addr.fullAddress}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (addr.targetLocation.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.place_outlined,
                                  size: 12, color: Colors.black38),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  addr.targetLocation,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black45),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
            ),
            const Icon(Icons.chevron_right,
                color: Colors.black38, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Items card ────────────────────────────────────────────────────────────

  Widget _itemsCard(List<CartItem> items) {
    return Container(
      decoration: _cardDecor(),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name + price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.product.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.product.formattedPrice,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Image + qty row
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _productImage(item.product.imageUrl),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Qty: ${item.quantity} · ${item.product.formattedPrice} each',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _productImage(String url) {
    final isReal = url.isNotEmpty && !url.contains('picsum');
    if (isReal) {
      return Image.network(
        url,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imageFallback(),
      );
    }
    return _imageFallback();
  }

  Widget _imageFallback() => Container(
        width: 64,
        height: 64,
        color: AppColors.veryLightBlue,
        child: const Icon(Icons.home_repair_service_rounded,
            color: AppColors.lightBlue, size: 30),
      );

  // ── Shipping card ─────────────────────────────────────────────────────────

  Widget _shippingCard() {
    return Column(
      children: [
        _shippingOption(
          label: 'Standard Shipping',
          sub: '3–5 business days',
          price: 'Free',
          value: 0,
        ),
        const SizedBox(height: 8),
        _shippingOption(
          label: 'Express Shipping',
          sub: '1–2 business days',
          price: '₱150.00',
          value: 150,
        ),
      ],
    );
  }

  Widget _shippingOption({
    required String label,
    required String sub,
    required String price,
    required double value,
  }) {
    final selected = _shippingFee == value;
    return GestureDetector(
      onTap: () => setState(() => _shippingFee = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.black87 : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? Colors.black87 : Colors.black38,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87)),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            Text(price,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  // ── Voucher tile ──────────────────────────────────────────────────────────

  Widget _voucherTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _cardDecor(),
      child: Row(
        children: [
          const Icon(Icons.local_offer_outlined,
              size: 20, color: Colors.black54),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Select a voucher',
                style: TextStyle(fontSize: 14, color: Colors.black54)),
          ),
          const Icon(Icons.chevron_right, color: Colors.black38, size: 20),
        ],
      ),
    );
  }

  // ── Payment card ──────────────────────────────────────────────────────────

  Widget _paymentCard(BuildContext context) {
    return Container(
      decoration: _cardDecor(),
      child: Column(
        children: _payOptions.asMap().entries.map((entry) {
          final i = entry.key;
          final opt = entry.value;
          final sel = _selectedPay == opt;
          return Column(
            children: [
              if (i > 0) const Divider(height: 1, indent: 16),
              InkWell(
                onTap: () {
                  if (opt.xenditMethods != null &&
                      !XenditConfig.isConfigured) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Online payment not configured yet. '
                            'Add your Xendit keys to xendit_config.dart.'),
                        backgroundColor: AppColors.red,
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _selectedPay = opt;
                    _xenditError = null;
                  });
                },
                borderRadius: i == 0
                    ? const BorderRadius.vertical(top: Radius.circular(12))
                    : i == _payOptions.length - 1
                        ? const BorderRadius.vertical(
                            bottom: Radius.circular(12))
                        : BorderRadius.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: opt.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            Icon(opt.icon, color: opt.color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(opt.label,
                                style: TextStyle(
                                    fontWeight: sel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 14,
                                    color: sel
                                        ? Colors.black87
                                        : Colors.black54)),
                            if (opt.xenditMethods != null)
                              const Text('Powered by Xendit',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.black38)),
                          ],
                        ),
                      ),
                      Icon(
                        sel
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: sel ? Colors.black87 : Colors.black38,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Summary card ──────────────────────────────────────────────────────────

  Widget _summaryCard(
      double subtotal, double vatAmount, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87)),
          const SizedBox(height: 12),
          _sumRow('Net Price', Order.formatPrice(subtotal)),
          const SizedBox(height: 6),
          _sumRowSub('VAT (12%)', '+ ${Order.formatPrice(vatAmount)}',
              color: const Color(0xFFE65100)),
          const SizedBox(height: 6),
          _sumRow('Shipping',
              _shippingFee == 0 ? 'Free' : Order.formatPrice(_shippingFee)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87)),
              Text(Order.formatPrice(total),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F8FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBDEFB)),
            ),
            child: const Row(
              children: [
                Icon(Icons.receipt_outlined,
                    size: 13, color: Color(0xFF1976D2)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Prices are subject to 12% VAT per BIR regulations. '
                    'Platform fee covers e-commerce processing costs.',
                    style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF1565C0),
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sumRowSub(String label, String value, {Color? color}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.add_circle_outline,
                  size: 12, color: color ?? Colors.grey),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: color ?? Colors.grey.shade600)),
            ],
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color ?? Colors.grey.shade700)),
        ],
      );

  // ── Address picker bottom sheet ───────────────────────────────────────────

  void _showAddressPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text('Shipping addresses',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ),
              ..._addresses.asMap().entries.map((entry) {
                final i = entry.key;
                final addr = entry.value;
                final isSel = i == _selectedIndex;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedIndex = i);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel
                              ? Colors.black87
                              : Colors.grey.shade200,
                          width: isSel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSel
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: isSel
                                ? Colors.black87
                                : Colors.black38,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(addr.label,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Colors.black87)),
                                    const SizedBox(width: 6),
                                    Text('(${addr.phone})',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(addr.name,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54)),
                                Text(addr.fullAddress,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                if (addr.targetLocation.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.place_outlined,
                                          size: 12,
                                          color: Colors.black38),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          addr.targetLocation,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black45),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 18, color: Colors.black54),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _showAddAddressSheet(context,
                                  editIndex: i);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _showAddAddressSheet(context);
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    foregroundColor: Colors.black87,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 20),
                      SizedBox(width: 6),
                      Text('Add new address',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Add / edit address bottom sheet ──────────────────────────────────────

  Future<void> _showAddAddressSheet(BuildContext context,
      {int? editIndex}) async {
    final existing = editIndex != null ? _addresses[editIndex] : null;
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final streetCtrl = TextEditingController(text: existing?.street ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? '');
    final provinceCtrl = TextEditingController(text: existing?.province ?? '');
    final postalCtrl = TextEditingController(text: existing?.postal ?? '');
    final targetLocationCtrl =
        TextEditingController(text: existing?.targetLocation ?? '');
    bool isDefault = editIndex == null ? true : (editIndex == _selectedIndex);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _AddressFormSheet(
        editIndex: editIndex,
        labelCtrl: labelCtrl,
        nameCtrl: nameCtrl,
        phoneCtrl: phoneCtrl,
        streetCtrl: streetCtrl,
        cityCtrl: cityCtrl,
        provinceCtrl: provinceCtrl,
        postalCtrl: postalCtrl,
        targetLocationCtrl: targetLocationCtrl,
        isDefault: isDefault,
        onSave: (updatedDefault) async {
          final addr = SavedAddress(
            label: labelCtrl.text.trim().isEmpty
                ? 'Home'
                : labelCtrl.text.trim(),
            name: nameCtrl.text.trim(),
            phone: phoneCtrl.text.trim(),
            street: streetCtrl.text.trim(),
            city: cityCtrl.text.trim(),
            province: provinceCtrl.text.trim(),
            postal: postalCtrl.text.trim(),
            targetLocation: targetLocationCtrl.text.trim(),
          );
          final updated = List<SavedAddress>.from(_addresses);
          int newIndex = _selectedIndex;
          if (editIndex != null) {
            updated[editIndex] = addr;
            if (updatedDefault) newIndex = editIndex;
          } else {
            updated.add(addr);
            if (updatedDefault) newIndex = updated.length - 1;
          }
          await AddressService.saveAll(updated);
          await AddressService.setDefaultIndex(newIndex);
          if (context.mounted) {
            setState(() {
              _addresses = updated;
              _selectedIndex = newIndex;
            });
            Navigator.pop(ctx);
          }
        },
      ),
    );

    for (final c in [
      labelCtrl, nameCtrl, phoneCtrl,
      streetCtrl, cityCtrl, provinceCtrl, postalCtrl,
      targetLocationCtrl,
    ]) {
      c.dispose();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87),
      );

  Widget _sumRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.black54, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: Colors.black87, fontSize: 13)),
        ],
      );

  BoxDecoration _cardDecor() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6),
        ],
      );

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit(BuildContext context, CartProvider cart,
      List<CartItem> items, double total,
      double vatAmount) async {
    // Stock validation
    final outOfStock = items.where((i) => i.product.stock == 0).toList();
    if (outOfStock.isNotEmpty) {
      final names = outOfStock.map((i) => i.product.name).join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Out of stock: $names'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }
    final overStock =
        items.where((i) => i.quantity > i.product.stock).toList();
    if (overStock.isNotEmpty) {
      final names = overStock
          .map((i) => '${i.product.name} (only ${i.product.stock} left)')
          .join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quantity exceeds stock: $names'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final addr = _selectedAddress;
    if (addr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a delivery address first'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() {
      _placing = true;
      _xenditError = null;
    });

    final addressStr =
        '${addr.name}, ${addr.phone} | ${addr.fullAddress}';

    try {
      if (_selectedPay.xenditMethods != null) {
        await _handleXenditPayment(
            context, cart, items, total, addressStr,
            vatAmount: vatAmount);
      } else {
        await _placeAndNavigate(
            context, cart, items, addressStr, null,
            vatAmount: vatAmount);
      }
    } catch (e) {
      setState(() {
        _xenditError = e.toString().replaceFirst('Exception: ', '');
        _placing = false;
      });
    }
  }

  // ── Xendit payment ────────────────────────────────────────────────────────

  Future<void> _handleXenditPayment(
    BuildContext context,
    CartProvider cart,
    List<CartItem> items,
    double total,
    String address, {
    double vatAmount = 0,
  }) async {
    final auth = context.read<AuthProvider>();
    final externalId =
        'aplimart-${DateTime.now().millisecondsSinceEpoch}';
    final itemCount = items.fold(0, (s, i) => s + i.quantity);

    final invoice = await XenditService.createInvoice(
      externalId: externalId,
      amount: total,
      description: 'ApliMart Order — $itemCount item(s)',
      payerName: _selectedAddress?.name ?? '',
      payerEmail: auth.user?.email,
      paymentMethods: _selectedPay.xenditMethods!,
    );

    final uri = Uri.parse(invoice.invoiceUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open payment page. Please try again.');
    }

    if (!context.mounted) return;

    // Listen for the deep link redirect from Xendit (aplimart://payment/success|failure)
    final appLinks = AppLinks();
    final completer = Completer<String?>();
    final sub = appLinks.uriLinkStream.listen((incoming) {
      if (incoming.scheme == 'aplimart' && !completer.isCompleted) {
        completer.complete(
            incoming.path.contains('success') ? 'success' : 'failure');
      }
    }, onError: (_) {
      if (!completer.isCompleted) completer.complete(null);
    });

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PaymentConfirmDialog(
        invoice: invoice,
        total: total,
        payOpt: _selectedPay,
        deepLinkFuture: completer.future,
      ),
    );

    await sub.cancel();

    if (confirmed != true || !context.mounted) {
      setState(() => _placing = false);
      return;
    }

    await _placeAndNavigate(
        context, cart, items, address, invoice.externalId,
        vatAmount: vatAmount);
  }

  // ── Place order & navigate ────────────────────────────────────────────────

  Future<void> _placeAndNavigate(
    BuildContext context,
    CartProvider cart,
    List<CartItem> items,
    String address,
    String? xenditRef, {
    double vatAmount = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!context.mounted) return;

    final paymentLabel = xenditRef != null
        ? '${_selectedPay.label} (Xendit)'
        : _selectedPay.label;

    final orderProvider = context.read<OrderProvider>();
    final uid = context.read<AuthProvider>().user?.id;

    final order = orderProvider.placeOrder(
      cartItems: items,
      address: address,
      paymentMethod: paymentLabel,
      shippingFee: _shippingFee > 0 ? _shippingFee : 0,
      vatAmount: vatAmount,
    );

    if (SupabaseConfig.isConfigured && uid != null) {
      try {
        await Supabase.instance.client.from('orders').insert({
          'id': order.id,
          'user_id': uid,
          'total_amount': order.total,
          'subtotal': order.subtotal,
          'shipping_fee': order.shippingFee,
          'vat_amount': order.vatAmount,
          'status': 'pending',
          'address': order.address,
          'payment_method': order.paymentMethod,
          'items': order.items
              .map((i) => {
                    'product_id': i.productId,
                    'product_name': i.productName,
                    'price': i.price,
                    'quantity': i.quantity,
                  })
              .toList(),
          'created_at': order.createdAt.toIso8601String(),
        });
        unawaited(orderProvider.loadFromSupabase(uid));
        // Update sold_count and stock for each ordered product
        unawaited(ProductService.recordSale(items).then((_) {
          if (context.mounted) {
            context.read<ProductProvider>().load();
          }
        }));
      } catch (_) {}
    }

    if (widget.directItems == null) cart.clear();

    // Immediately update in-memory stock so the home screen reflects the
    // purchase before the Supabase roundtrip finishes.
    if (context.mounted) {
      context.read<ProductProvider>().updateStockLocally(items);
    }

    setState(() => _placing = false);
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OrderDetailScreen(order: order, fromCheckout: true),
      ),
      (route) => route.isFirst,
    );
  }
}

// ── Payment confirm dialog ────────────────────────────────────────────────
// Blocks the back button and verifies actual payment status before confirming.

class _PaymentConfirmDialog extends StatefulWidget {
  final XenditInvoice invoice;
  final double total;
  final _PayOpt payOpt;
  final Future<String?> deepLinkFuture;

  const _PaymentConfirmDialog({
    required this.invoice,
    required this.total,
    required this.payOpt,
    required this.deepLinkFuture,
  });

  @override
  State<_PaymentConfirmDialog> createState() =>
      _PaymentConfirmDialogState();
}

class _PaymentConfirmDialogState extends State<_PaymentConfirmDialog> {
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Auto-verify when the deep link redirect arrives from Xendit
    widget.deepLinkFuture.then((result) {
      if (!mounted) return;
      if (result == 'success') {
        _verify();
      } else if (result == 'failure') {
        setState(() {
          _error = 'Payment was cancelled or failed. Please try again.';
        });
      }
    });
  }

  Future<void> _verify() async {
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final status =
          await XenditService.getInvoiceStatus(widget.invoice.id);
      if (!mounted) return;
      if (status == 'PAID') {
        Navigator.pop(context, true);
      } else if (status == 'EXPIRED') {
        setState(() {
          _verifying = false;
          _error =
              'This payment link has expired. Please go back and try again.';
        });
      } else {
        setState(() {
          _verifying = false;
          _error =
              'Payment not completed yet. Please finish payment in the browser first, then tap "I\'ve Paid".';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error =
            'Could not verify payment. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent the Android back button from dismissing the dialog.
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.payment, color: widget.payOpt.color, size: 24),
            const SizedBox(width: 10),
            const Expanded(
                child: Text('Complete Payment',
                    style: TextStyle(fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A payment page opened in your browser. '
              'Complete your payment there, then tap "I\'ve Paid" to verify.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 10),
            Text(
              'Amount: ${Order.formatPrice(widget.total)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 4),
            Text(
              'Method: ${widget.payOpt.label}',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.grey),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                            color: AppColors.red,
                            fontSize: 12,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed:
                _verifying ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: _verifying ? null : _verify,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyBlue,
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: _verifying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text("I've Paid",
                    style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Address form sheet ────────────────────────────────────────────────────

class _AddressFormSheet extends StatefulWidget {
  final int? editIndex;
  final TextEditingController labelCtrl;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController streetCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController provinceCtrl;
  final TextEditingController postalCtrl;
  final TextEditingController targetLocationCtrl;
  final bool isDefault;
  final Future<void> Function(bool isDefault) onSave;

  const _AddressFormSheet({
    required this.editIndex,
    required this.labelCtrl,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.streetCtrl,
    required this.cityCtrl,
    required this.provinceCtrl,
    required this.postalCtrl,
    required this.targetLocationCtrl,
    required this.isDefault,
    required this.onSave,
  });

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    _isDefault = widget.isDefault;
  }

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboard = TextInputType.text,
    bool floatLabel = false,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: floatLabel ? null : hint,
          labelText: floatLabel ? hint : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black87),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.editIndex != null ? 'Edit Address' : 'Add Address',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 16),
            _field(widget.labelCtrl, 'Label (Home, Work...)',
                floatLabel: true),
            const SizedBox(height: 10),
            _field(widget.nameCtrl, 'Recipient name'),
            const SizedBox(height: 10),
            _field(widget.phoneCtrl, 'Phone number',
                keyboard: TextInputType.phone),
            const SizedBox(height: 10),
            _field(widget.streetCtrl, 'Street address'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _field(widget.cityCtrl, 'City')),
                const SizedBox(width: 10),
                Expanded(child: _field(widget.provinceCtrl, 'Province')),
              ],
            ),
            const SizedBox(height: 10),
            _field(widget.postalCtrl, 'Postal code',
                keyboard: TextInputType.number),
            const SizedBox(height: 10),
            _field(widget.targetLocationCtrl,
                'Target location / landmark (e.g. Near 7-Eleven, Blue gate)'),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Set as default address',
                    style:
                        TextStyle(fontSize: 14, color: Colors.black87)),
                Switch(
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                  activeColor: Colors.black87,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => widget.onSave(_isDefault),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Save Address',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
