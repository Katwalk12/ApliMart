import 'package:supabase/supabase.dart';
import '../config/supabase_config.dart';

class RiderAccountService {
  /// Creates a new Supabase auth user and registers them as a rider.
  /// Uses the service role key so the admin's own session is never affected.
  static Future<void> createRider({
    required String name,
    required String email,
    required String password,
  }) async {
    // Spin up a temporary admin client using the service role key.
    // This bypasses RLS and never touches the global singleton session.
    final adminClient = SupabaseClient(
      SupabaseConfig.supabaseUrl,
      SupabaseConfig.serviceRoleKey,
    );

    try {
      // 1. Create the auth user (email pre-confirmed — rider can log in immediately)
      final res = await adminClient.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
          userMetadata: {'name': name},
        ),
      );

      final userId = res.user?.id;
      if (userId == null) throw Exception('User creation returned no ID.');

      // 2. Register as a rider (service role bypasses riders RLS)
      await adminClient.from('riders').upsert({
        'user_id': userId,
        'email': email,
        'name': name,
      }, onConflict: 'user_id');

      // 3. Create profile record (service role bypasses profiles RLS)
      await adminClient.from('profiles').upsert({
        'id': userId,
        'name': name,
      }, onConflict: 'id');
    } finally {
      adminClient.dispose();
    }
  }
}
