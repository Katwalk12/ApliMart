import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/xendit_config.dart';

class XenditInvoice {
  final String id;
  final String externalId;
  final String invoiceUrl;
  final String status;

  const XenditInvoice({
    required this.id,
    required this.externalId,
    required this.invoiceUrl,
    required this.status,
  });

  factory XenditInvoice.fromJson(Map<String, dynamic> j) => XenditInvoice(
        id: j['id']?.toString() ?? '',
        externalId: j['external_id']?.toString() ?? '',
        invoiceUrl: j['invoice_url']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
      );
}

class XenditService {
  static const _baseUrl = 'https://api.xendit.co';

  // Basic-auth header: secret_key followed by a colon, then base64-encoded.
  static String get _auth =>
      'Basic ${base64Encode(utf8.encode('${XenditConfig.secretKey}:'))}';

  /// Creates a Xendit hosted-checkout invoice and returns it.
  ///
  /// [externalId]     – unique ID you generate (e.g. order ID)
  /// [amount]         – total in PHP (integer pesos)
  /// [description]    – shown on the payment page
  /// [payerName]      – customer name (optional)
  /// [payerEmail]     – customer email (optional)
  /// [paymentMethods] – restrict methods: e.g. ['GCASH'], ['CREDIT_CARD'],
  ///                    ['PAYMAYA']. Pass [] to allow all Xendit methods.
  static Future<XenditInvoice> createInvoice({
    required String externalId,
    required double amount,
    required String description,
    String? payerName,
    String? payerEmail,
    List<String> paymentMethods = const [],
  }) async {
    final body = <String, dynamic>{
      'external_id': externalId,
      'amount': amount.toInt(),
      'description': description,
      'currency': 'PHP',
      'success_redirect_url': 'aplimart://payment/success',
      'failure_redirect_url': 'aplimart://payment/failure',
    };

    if (payerName != null || payerEmail != null) {
      body['customer'] = {
        'given_names': ?payerName,
        'email': ?payerEmail,
      };
    }

    if (paymentMethods.isNotEmpty) {
      body['payment_methods'] = paymentMethods;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/v2/invoices'),
      headers: {
        'Authorization': _auth,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      return XenditInvoice.fromJson(json);
    }

    // Xendit error: { "error_code": "...", "message": "..." }
    final msg = json['message']?.toString() ?? 'Xendit error ${response.statusCode}';
    throw Exception(msg);
  }

  /// Polls the status of an existing invoice.
  /// Returns values like "PENDING", "PAID", "EXPIRED".
  static Future<String> getInvoiceStatus(String invoiceId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/v2/invoices/$invoiceId'),
      headers: {'Authorization': _auth},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['status']?.toString() ?? 'UNKNOWN';
    }
    return 'UNKNOWN';
  }
}
