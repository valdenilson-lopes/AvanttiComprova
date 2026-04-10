import 'env.dart';

class ApiConfig {
  static String get baseUrl {
    switch (Env.current) {
      case Environment.dev:
        return 'https://tmziegptfhcsobwsptwm.supabase.co'; // 👈 Sua URL do Supabase
      case Environment.homolog:
        return 'https://tmziegptfhcsobwsptwm.supabase.co'; // Mesma URL (ou outra)
      case Environment.prod:
        return 'https://tmziegptfhcsobwsptwm.supabase.co'; // Mesma URL
    }
  }

  static String get anonKey =>
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRtemllZ3B0Zmhjc29id3NwdHdtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5OTk0NzYsImV4cCI6MjA5MDU3NTQ3Nn0.GkXzNF-AOnexwD9i2tJIoMlCasQUm3W1ox3h20XOR5Y';
}
