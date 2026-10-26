class SupabaseConfig {
  // Replace these with your actual Supabase project credentials
  // from https://app.supabase.com → Settings → API
  static const supabaseUrl = 'https://yiuyovdbfwrzzqtcikov.supabase.co';
  static const supabasePublishableKey = 'sb_publishable_t6mdH0vFkXb2GvNn2Mzj8Q_hCfDdvjr';

  // Service role key — Project Settings → API → the SECRET key.
  // New Supabase projects:  sb_secret_...   (copy exactly, no extra letters)
  // Classic Supabase projects: eyJ...       (long JWT string)
  // The NAME you give the key in the dashboard does NOT matter.
  static const serviceRoleKey = 'YOUR_SUPABASE_SERVICE_ROLE_KEY';

  // Returns true only when real credentials have been filled in
  static bool get isConfigured =>
      !supabaseUrl.startsWith('YOUR_') &&
      !supabasePublishableKey.startsWith('YOUR_');

  // Positive check: accept only the two known valid secret-key formats.
  // Rejects placeholders, publishable keys, and keys with copy-paste typos.
  static bool get hasServiceRole =>
      serviceRoleKey.startsWith('sb_secret_') ||
      serviceRoleKey.startsWith('eyJ');
}
