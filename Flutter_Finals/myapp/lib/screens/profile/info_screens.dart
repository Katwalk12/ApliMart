import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

// ── Shared scaffold ───────────────────────────────────────────────────────────

class _InfoScaffold extends StatelessWidget {
  final String title;
  final Widget body;

  const _InfoScaffold({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.navyBlue, AppColors.darkBlue],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: body,
    );
  }
}

// ── Customer Service ──────────────────────────────────────────────────────────

class CustomerServiceScreen extends StatelessWidget {
  const CustomerServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _InfoScaffold(
      title: 'Customer Service',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ContactCard(
            icon: Icons.email_outlined,
            color: const Color(0xFF1976D2),
            title: 'Email Support',
            subtitle: 'support@applimart.ph',
            detail: 'Response within 24 hours (Mon – Fri)',
          ),
          const SizedBox(height: 12),
          _ContactCard(
            icon: Icons.phone_outlined,
            color: const Color(0xFF43A047),
            title: 'Hotline',
            subtitle: '+63 2 8888 – APLI (2754)',
            detail: 'Mon – Sat, 8:00 AM – 8:00 PM PHT',
          ),
          const SizedBox(height: 12),
          _ContactCard(
            icon: Icons.chat_bubble_outline_rounded,
            color: const Color(0xFFFF6B2B),
            title: 'Live Chat',
            subtitle: 'Available in the app',
            detail: 'Mon – Fri, 9:00 AM – 6:00 PM PHT',
          ),
          const SizedBox(height: 20),
          _SectionHeader(label: 'Frequently Asked Questions'),
          const SizedBox(height: 8),
          ..._faqs.map((faq) => _FaqTile(q: faq.$1, a: faq.$2)),
          const SizedBox(height: 20),
          _SectionHeader(label: 'Order Issues'),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.swap_horiz_rounded,
            label: 'Returns & Exchanges',
            detail:
                'Items can be returned within 7 days of delivery if unopened and in original condition. Contact support with your order number to begin the process.',
          ),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.local_shipping_outlined,
            label: 'Delivery Concerns',
            detail:
                'If your order has not arrived within the estimated window, please contact us with your order number. Our riders are tracked in real time.',
          ),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.payment_outlined,
            label: 'Payment Disputes',
            detail:
                'For failed or disputed payments, email support@applimart.ph with your transaction reference. Refunds are processed within 5–7 business days.',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static const _faqs = [
    (
      'How do I track my order?',
      'Go to Profile → My Orders and tap on any order to see its real-time status, rider assignment, and estimated arrival.'
    ),
    (
      'Can I cancel a pending order?',
      'Yes. Pending orders can be cancelled instantly from the Order Detail screen. Once an admin has approved your order (Processing), you can still request a cancellation — the admin will review and confirm it.'
    ),
    (
      'What payment methods are accepted?',
      'ApliMart accepts Cash on Delivery (COD) and online payments via GCash, Maya, credit/debit cards, and other methods powered by Xendit.'
    ),
    (
      'Is there a warranty on items?',
      'All appliances sold on ApliMart carry the manufacturer\'s standard warranty. Warranty claims are handled directly with the brand. Contact us and we will assist you.'
    ),
    (
      'How is VAT applied?',
      'In compliance with BIR regulations, a 12% VAT and a 1% platform service fee are applied to the subtotal of each order. These are displayed in your checkout summary.'
    ),
  ];
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String detail;

  const _ContactCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(detail,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String q;
  final String a;
  const _FaqTile({required this.q, required this.a});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(widget.q,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          trailing: Icon(
            _open
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: AppColors.primaryBlue,
          ),
          onExpansionChanged: (v) => setState(() => _open = v),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 14),
          children: [
            Text(widget.a,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.darkGrey,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  const _InfoTile(
      {required this.icon, required this.label, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(detail,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.darkGrey,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.navyBlue));
  }
}

// ── About ApliMart ────────────────────────────────────────────────────────────

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _InfoScaffold(
      title: 'About ApliMart',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Logo card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navyBlue, AppColors.darkBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      color: AppColors.navyBlue, size: 40),
                ),
                const SizedBox(height: 14),
                const Text('ApliMart',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const SizedBox(height: 4),
                const Text('Your Home Appliance Marketplace',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13)),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Version 1.0.0',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _SectionHeader(label: 'Our Mission'),
          const SizedBox(height: 10),
          _card(
            child: const Text(
              'ApliMart was built to make quality home appliances accessible to every Filipino household. '
              'We connect trusted suppliers with buyers through a seamless, transparent, and '
              'BIR-compliant e-commerce platform — so you can shop with confidence and '
              'have your appliances delivered right to your door.',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.darkGrey,
                  height: 1.6),
            ),
          ),

          const SizedBox(height: 20),
          _SectionHeader(label: 'What We Offer'),
          const SizedBox(height: 10),
          ..._features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FeatureRow(icon: f.$1, color: f.$2, label: f.$3, desc: f.$4),
            ),
          ),

          const SizedBox(height: 20),
          _SectionHeader(label: 'Company'),
          const SizedBox(height: 10),
          _card(
            child: Column(
              children: [
                _detailRow('Registered Name', 'ApliMart Technologies, Inc.'),
                _divider(),
                _detailRow('Country', 'Philippines'),
                _divider(),
                _detailRow('BIR TIN', '123-456-789-000'),
                _divider(),
                _detailRow('DTI Registration', 'DTIPH-2024-00123'),
                _divider(),
                _detailRow('Email', 'hello@applimart.ph'),
                _divider(),
                _detailRow('Website', 'www.applimart.ph'),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _SectionHeader(label: 'Legal'),
          const SizedBox(height: 10),
          _card(
            child: Column(
              children: [
                _detailRow('Governing Law', 'Republic of the Philippines'),
                _divider(),
                _detailRow('Data Privacy', 'R.A. 10173 (Data Privacy Act)'),
                _divider(),
                _detailRow('Consumer Protection', 'R.A. 7394'),
                _divider(),
                _detailRow('E-Commerce', 'R.A. 8792 (E-Commerce Act)'),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static const _features = [
    (Icons.storefront_outlined, Color(0xFF1976D2), 'Wide Product Selection',
        'Browse hundreds of appliances across all major categories — refrigerators, TVs, washing machines, and more.'),
    (Icons.local_shipping_outlined, Color(0xFF43A047), 'Reliable Delivery',
        'Track your order in real time from warehouse to doorstep with our dedicated rider network.'),
    (Icons.verified_outlined, Color(0xFFFF6B2B), 'Verified Sellers',
        'Every merchant on ApliMart is verified and held to strict quality and service standards.'),
    (Icons.lock_outline, Color(0xFF7B1FA2), 'Secure Payments',
        'Powered by Xendit — supporting GCash, Maya, cards, and COD with end-to-end encryption.'),
    (Icons.receipt_long_outlined, Color(0xFFE65100), 'BIR-Compliant Invoicing',
        '12% VAT and platform fee are transparently itemised in every order summary and receipt.'),
  ];

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.grey)),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _divider() => const Divider(height: 1, color: AppColors.offWhite);
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String desc;
  const _FeatureRow(
      {required this.icon,
      required this.color,
      required this.label,
      required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 3),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.darkGrey,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Privacy Policy ────────────────────────────────────────────────────────────

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _InfoScaffold(
      title: 'Privacy Policy',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _policyMeta(),
          const SizedBox(height: 16),
          ..._sections.map((s) => _PolicySection(title: s.$1, body: s.$2)),
          const SizedBox(height: 8),
          _contactCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _policyMeta() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline,
                color: Color(0xFF1976D2), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Effective Date: January 1, 2025',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Color(0xFF1565C0))),
                  SizedBox(height: 2),
                  Text(
                      'This policy applies to the ApliMart mobile application and website.',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF1976D2))),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _contactCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contact Our DPO',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.navyBlue)),
            const SizedBox(height: 6),
            const Text(
              'For privacy-related concerns, requests, or to exercise your rights under R.A. 10173:',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.darkGrey,
                  height: 1.5),
            ),
            const SizedBox(height: 10),
            Row(
              children: const [
                Icon(Icons.email_outlined,
                    size: 15, color: AppColors.primaryBlue),
                SizedBox(width: 6),
                Text('privacy@applimart.ph',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      );

  static const _sections = [
    (
      '1. Information We Collect',
      'We collect the following personal information when you use ApliMart:\n\n'
          '• Account Information: name, email address, mobile number, and password (hashed).\n'
          '• Delivery Information: shipping address and contact details.\n'
          '• Transaction Data: order history, payment method (we do not store card numbers), and receipts.\n'
          '• Device Data: device type, OS version, and anonymous usage statistics.\n'
          '• Location Data: only when you request delivery address suggestions (never stored continuously).'
    ),
    (
      '2. How We Use Your Information',
      'Your information is used strictly to:\n\n'
          '• Process and fulfil your orders.\n'
          '• Send order status notifications and delivery updates.\n'
          '• Provide customer support.\n'
          '• Detect and prevent fraud or unauthorised activity.\n'
          '• Comply with BIR tax reporting and legal obligations.\n'
          '• Improve app performance through anonymised analytics.\n\n'
          'We do not sell or rent your personal data to third parties.'
    ),
    (
      '3. Data Sharing',
      'We share your data only with parties essential to fulfilling your order:\n\n'
          '• Delivery Riders: name and address for drop-off.\n'
          '• Payment Processors (Xendit): transaction data under their own privacy terms.\n'
          '• Government Agencies: when required by Philippine law (BIR, NPC, courts).\n\n'
          'All third-party partners are contractually bound to handle your data in accordance with R.A. 10173.'
    ),
    (
      '4. Data Retention',
      'We retain your personal data for as long as your account is active or as required by law. '
          'Transaction records are kept for a minimum of 5 years as required by BIR. '
          'You may request deletion of your account and associated data at any time, subject to legal retention obligations.'
    ),
    (
      '5. Your Rights Under R.A. 10173',
      'As a data subject, you have the right to:\n\n'
          '• Access: request a copy of the personal data we hold about you.\n'
          '• Rectification: correct inaccurate or incomplete information.\n'
          '• Erasure: request deletion of your data (subject to legal limits).\n'
          '• Object: opt out of processing for direct marketing.\n'
          '• Data Portability: receive your data in a structured, readable format.\n'
          '• Lodge a Complaint: file a complaint with the National Privacy Commission (NPC) at www.privacy.gov.ph.'
    ),
    (
      '6. Security',
      'We protect your data using:\n\n'
          '• TLS 1.3 encryption for all data in transit.\n'
          '• AES-256 encryption for sensitive data at rest.\n'
          '• Role-based access controls — only authorised personnel can access personal data.\n'
          '• Regular security audits and vulnerability assessments.\n\n'
          'Despite our best efforts, no system is 100% secure. Please use a strong password and keep it confidential.'
    ),
    (
      '7. Cookies & Analytics',
      'The ApliMart app does not use browser cookies. We use anonymised, aggregated analytics (crash reports and performance metrics) to improve the app. '
          'These analytics cannot be used to identify you personally.'
    ),
    (
      '8. Children\'s Privacy',
      'ApliMart is not directed at children under 18. We do not knowingly collect personal data from minors. '
          'If you believe a minor has provided us with personal information, please contact our DPO immediately.'
    ),
    (
      '9. Changes to This Policy',
      'We may update this Privacy Policy from time to time. Material changes will be notified via in-app notification at least 15 days before they take effect. '
          'Continued use of ApliMart after the effective date constitutes acceptance of the updated policy.'
    ),
  ];
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;
  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.navyBlue)),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.darkGrey,
                  height: 1.6)),
        ],
      ),
    );
  }
}
