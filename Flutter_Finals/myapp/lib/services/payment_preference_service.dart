import 'package:shared_preferences/shared_preferences.dart';

class PaymentPreferenceService {
  static const _kIndex = 'default_payment_index';
  static const _kLabel = 'default_payment_label';

  static Future<int> getDefaultIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_kIndex) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> setDefault(int index, String label) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kIndex, index);
      await prefs.setString(_kLabel, label);
    } catch (_) {}
  }

  static Future<String?> getDefaultLabel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kLabel);
    } catch (_) {
      return null;
    }
  }
}
