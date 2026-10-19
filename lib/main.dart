import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pastikan URL dan Key HANYA di dalam tanda kutip satu, tidak ada kode lain di dalamnya
  await Supabase.initialize(
    url: 'https://lobbilgxxggijuepuber.supabase.co',      // <--- GANTI DI SINI
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvYmJpbGd4eGdnaWp1ZXB1YmVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIzODI4NjYsImV4cCI6MjEwNzk1ODg2Nn0.OiGZZYmtqH6cuXBRJPNtMtIB4ImcKbH-BUiQJidv1TI',     // <--- GANTI DI SINI
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