import 'package:supabase_flutter/supabase_flutter.dart';

/// نقطة وصول موحدة لعميل Supabase عبر التطبيق
class SupabaseService {
  SupabaseService._();

  /// استدعِ هذا مرة وحدة بملف main.dart قبل runApp()
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static const String supabaseUrl = 'https://nomgbttkfzhgbmbyidpy.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vbWdidHRrZnpoZ2JtYnlpZHB5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQyOTU4NzUsImV4cCI6MjA5OTg3MTg3NX0.ZUjZgDUzXdfEdhLXFcHLh15c-QnmVkdxHcY5lqYBre4';
}