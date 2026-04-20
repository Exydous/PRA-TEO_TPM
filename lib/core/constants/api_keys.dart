import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  // Mengambil nilai dari .env, jika tidak ada akan return string kosong
  static String supabaseUrl = dotenv.get('SUPABASE_URL', fallback: '');
  static String supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY', fallback: '');
  static String get currencyApiKey => dotenv.env['FREECURRENCY_API_KEY'] ?? '';
}