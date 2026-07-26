import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
      url: dotenv.get('SUPABASE_URL'),
      publishableKey: dotenv.get('SUPABASE_ANON_KEY'),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
