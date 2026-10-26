import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = false;
  String? _error;
  bool _isRider = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  User? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.userMetadata?['is_admin'] == true;
  bool get isRider => _isRider;
  String? get error => _error;
  String get displayName =>
      _user?.userMetadata?['name']?.toString() ?? _user?.email ?? 'User';
  String get phone =>
      _user?.userMetadata?['phone']?.toString() ?? '';

  AuthProvider() {
    if (!SupabaseConfig.isConfigured) return;
    _user = Supabase.instance.client.auth.currentUser;
    if (_user != null) _checkRider(_user!.id);
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      if (_user != null) {
        _checkRider(_user!.id);
        _upsertProfile(_user!);
      } else {
        _isRider = false;
      }
      notifyListeners();
    });
  }

  Future<void> _checkRider(String userId) async {
    try {
      final res = await Supabase.instance.client
          .from('riders')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();
      if (_disposed) return;
      _isRider = res != null;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _upsertProfile(User user) async {
    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'name': user.userMetadata?['name']?.toString() ?? user.email ?? '',
      }, onConflict: 'id');
    } catch (_) {}
  }

  Future<bool> signIn(String email, String password) async {
    if (!SupabaseConfig.isConfigured) {
      _error = 'Supabase not configured. Fill in supabase_config.dart.';
      notifyListeners();
      return false;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    if (!SupabaseConfig.isConfigured) {
      _error = 'Supabase not configured. Fill in supabase_config.dart.';
      notifyListeners();
      return false;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String name,
    String? phone,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      _error = 'Supabase not configured.';
      notifyListeners();
      return false;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = <String, dynamic>{'name': name};
      if (phone != null && phone.isNotEmpty) data['phone'] = phone;
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: data),
      );
      _user = Supabase.instance.client.auth.currentUser;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (!SupabaseConfig.isConfigured) return;
    await Supabase.instance.client.auth.signOut();
  }
}
