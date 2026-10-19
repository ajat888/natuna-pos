import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'MASUKKAN_PROJECT_URL_ANDA',      // <--- GANTI DENGAN URL SUPABASE ANDA
    anonKey: 'MASUKKAN_ANON_KEY_ANDA',     // <--- GANTI DENGAN ANON KEY ANDA
  );
  
  runApp(const NatunaApp());
}

class NatunaApp extends StatelessWidget {
  const NatunaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Natuna POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LoginPage(),
    );
  }
}',      // <--- GANTI DENGAN URL SUPABASE ANDA
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvYmJpbGd4eGdnaWp1ZXB1YmVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIzODI4NjYsImV4cCI6MjEwNzk1ODg2Nn0.OiGZZYmtqH6cuXBRJPNtMtIB4ImcKbH-BUiQJidv1TI',     // <--- GANTI DENGAN ANON KEY ANDA
  );
  
  runApp(const NatunaApp());
}

class NatunaApp extends StatelessWidget {
  const NatunaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Natuna POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LoginPage(),
    );
  }
}