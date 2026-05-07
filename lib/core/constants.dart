import 'package:flutter_dotenv/flutter_dotenv.dart';

String get kSupabaseUrl => dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ?? '';
String get kSupabaseAnonKey =>
	dotenv.env['NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY'] ?? '';
const String kUserId = "user_123";
