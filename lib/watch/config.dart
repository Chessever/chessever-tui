/// Compile-time Supabase config for the public Chessever broadcasts feed.
///
/// Public anon key is safe to bundle: row-level security enforces what
/// anonymous clients can read. Defaults match the mobile app's `.env`;
/// override at build time with:
///
///   dart compile exe bin/chessever_tui.dart \
///     --define=SUPABASE_URL=https://... \
///     --define=SUPABASE_ANON_KEY=eyJ...
class WatchConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://oelbsuggrzyqwzmvidju.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9lbGJzdWdncnp5cXd6bXZpZGp1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk5MDgyODYsImV4cCI6MjA2NTQ4NDI4Nn0.YpIEGIVCN2yUmh4ALnuF0i4jKI3ld1VHNVSCN2J7R30',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
