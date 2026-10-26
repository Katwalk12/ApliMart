import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedAddress {
  final String label;
  final String name;
  final String phone;
  final String street;
  final String city;
  final String province;
  final String postal;
  final String targetLocation;

  const SavedAddress({
    required this.label,
    required this.name,
    required this.phone,
    required this.street,
    required this.city,
    required this.province,
    required this.postal,
    this.targetLocation = '',
  });

  String get fullAddress {
    return [street, city, province, postal]
        .where((p) => p.isNotEmpty)
        .join(', ');
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'name': name,
        'phone': phone,
        'street': street,
        'city': city,
        'province': province,
        'postal': postal,
        'targetLocation': targetLocation,
      };

  factory SavedAddress.fromJson(Map<String, dynamic> j) => SavedAddress(
        label: j['label'] ?? '',
        name: j['name'] ?? '',
        phone: j['phone'] ?? '',
        street: j['street'] ?? '',
        city: j['city'] ?? '',
        province: j['province'] ?? '',
        postal: j['postal'] ?? '',
        targetLocation: j['targetLocation'] ?? '',
      );
}

class AddressService {
  static const _kList = 'saved_addresses_v2';
  static const _kDefault = 'default_addr_index';

  static Future<List<SavedAddress>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kList);
      if (raw == null) {
        // Migrate from old single-address storage
        return await _migrateOld(prefs);
      }
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => SavedAddress.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<SavedAddress> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kList, jsonEncode(addresses.map((a) => a.toJson()).toList()));
  }

  static Future<int> getDefaultIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kDefault) ?? 0;
  }

  static Future<void> setDefaultIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDefault, index);
  }

  // Migrate old flat key storage to new list format
  static Future<List<SavedAddress>> _migrateOld(
      SharedPreferences prefs) async {
    final name = prefs.getString('default_addr_name');
    if (name == null || name.isEmpty) return [];
    final addr = SavedAddress(
      label: 'Home',
      name: name,
      phone: prefs.getString('default_addr_phone') ?? '',
      street: prefs.getString('default_addr_address') ?? '',
      city: prefs.getString('default_addr_city') ?? '',
      province: '',
      postal: '',
    );
    await saveAll([addr]);
    await setDefaultIndex(0);
    return [addr];
  }

  // Legacy compat used by old code paths (no-op if already migrated)
  static Future<Map<String, String>?> loadDefault() async {
    final list = await loadAll();
    if (list.isEmpty) return null;
    final idx = await getDefaultIndex();
    final addr = list[idx.clamp(0, list.length - 1)];
    return {
      'name': addr.name,
      'phone': addr.phone,
      'address': addr.street,
      'city': '${addr.city}, ${addr.province}'.trim(),
    };
  }
}
