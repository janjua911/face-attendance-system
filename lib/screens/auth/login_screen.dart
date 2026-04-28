import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../admin/admin_dashboard.dart';
import '../teacher/teacher_dashboard.dart';
import '../student/student_dashboard.dart';
import 'signup_screen.dart'; // ✅ ADD THIS IMPORT

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final AuthService _authService = AuthService();

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Email aur Password daalo');
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      String role = result['role'];
      if (!mounted) return;

      // Role-based navigation
      switch (role) {
        case 'admin':
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const AdminDashboard()));
          break;
        case 'teacher':
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const TeacherDashboard()));
          break;
        case 'student':
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const StudentDashboard()));
          break;
      }
    } else {
      _showError(result['message']);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.face, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'Face Attendance System',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'University Smart Attendance',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 40),

              // Email Field
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Email',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.email, color: Colors.indigo),
                  filled: true,
                  fillColor: const Color(0xFF16213E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.lock, color: Colors.indigo),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white38,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF16213E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Login',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              // ✅ ADDED: Sign Up Row (Login button ke baad)
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ",
                      style: TextStyle(color: Colors.white54)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignUpScreen())),
                    child: const Text('Sign Up',
                        style: TextStyle(
                            color: Colors.indigo,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}