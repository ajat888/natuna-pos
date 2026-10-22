import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ tambahkan import di atas

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env"); // ✅ muat file .env dulu
  
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,       // ✅ ambil dari .env
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!, // ✅ ambil dari .env
    );
    runApp(const NatunaApp());
  } catch (e) {
    // Jika koneksi ke Supabase gagal, tampilkan layar error alih-alih layar hitam
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Gagal terhubung ke database:\n$e\n\nPastikan HP terhubung ke internet dan URL Supabase benar.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    ));
  }
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
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Tampilkan loading berputar saat pertama kali memuat
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Ambil session dari snapshot atau current session
        final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
        
        if (session != null) {
          return const DashboardPage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}