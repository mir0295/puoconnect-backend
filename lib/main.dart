import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'screens/login_screen.dart';

void main() async {
  // Memastikan Flutter bindings siap sedia sebelum Firebase diinisialisasi
  WidgetsFlutterBinding.ensureInitialized();
  
  // Menginisialisasi Firebase dengan konfigurasi khusus platform
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, 
  );
  
  runApp(const PuoConnectApp());
}

class PuoConnectApp extends StatelessWidget {
  const PuoConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PuoConnect',
      home: LoginScreen(),
    );
  }
}