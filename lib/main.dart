import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart'; // Tambahkan import ini

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://lobbilgxxggijuepuber.supabase.co',      // <--- GANTI DENGAN URL ASLI
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvYmJpbGd4eGdnaWp1ZXB1YmVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIzODI4NjYsImV4cCI6MjEwNzk1ODg2Nn0.OiGZZYmtqH6cuXBRJPNtMtIB4ImcKbH-BUiQJidv1TI',      // <--- GANTI DENGAN ANON KEY ASLI
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
      home: const AuthGate(), // <-- UBAH BAGIAN INI
    );
  }
}

// Widget yang mengecek status login secara otomatis
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Cek apakah ada session aktif
        final session = Supabase.instance.client.auth.currentSession;
        
        if (session != null) {
          return const DashboardPage(); // Jika sudah login
        } else {
          return const LoginPage(); // Jika belum login
        }
      },
    );
  }
}