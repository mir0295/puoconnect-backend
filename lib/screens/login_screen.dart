import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_dashboard_screen.dart'; 
import 'admin_dashboard.dart';
import 'super_admin_dashboard.dart'; // [DIADD]: Import fail Super Admin
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  
  bool _isObscure = true;
  bool _isLoading = false; // Penunjuk pemuatan
  final Color primaryColor = Colors.blueAccent;

  Future<void> login() async {
    setState(() => _isLoading = true); // Aktifkan indikator
    
    try {
      UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(), 
          password: passController.text.trim()
      );

      if (!mounted) return;

      // Mendapatkan data user dari Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();

      if (!mounted) return;

      if (userDoc.exists) {
        String role = userDoc['role'];
        String dept = userDoc['department']; 

        // [DIUBASUAH]: Navigasi berasingan mengikut peranan (Role)
        if (role == 'superadmin') {
          // Navigasi Khas ke Super Admin Dashboard
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(
              builder: (context) => const SuperAdminDashboard()
            )
          );
        } else if (role == 'admin') {
          // Navigasi ke Admin Dashboard Biasa
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(
              builder: (context) => AdminDashboard(
                department: dept, 
                role: role
              )
            )
          );
        } else {
          // Menghantar data department ke DashboardScreen bagi pengguna biasa
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(
              builder: (context) => DashboardScreen(userDept: dept)
            )
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login gagal: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false); // Matikan indikator
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 120, 
                    child: Image.asset(
                      'assets/images/puoconnect_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("Selamat Datang", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text("Sila log masuk ke PUO Notify", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  
                  TextField(
                    controller: emailController, 
                    decoration: InputDecoration(
                      labelText: "Email", 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
                      prefixIcon: const Icon(Icons.email)
                    )
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passController, 
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      labelText: "Password", 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _isObscure = !_isObscure),
                      )
                    )
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: _isLoading ? null : login, // Disable butang semasa loading
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) // Papar loading
                        : const Text("LOGIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                    child: const Text("Tiada akaun? Daftar sekarang"),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}