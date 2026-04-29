// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../services/auth_service.dart';
// import '../admin/admin_dashboard.dart';
// import '../teacher/teacher_dashboard.dart';
// import '../student/student_dashboard.dart';
// import 'signup_screen.dart';

// // AppTheme for consistent styling
// class AppTheme {
//   static const Color primaryPurple = Color(0xFF6C63FF);
//   static const Color primaryDark = Color(0xFF3F3D9E);
//   static const Color accentCyan = Color(0xFF00B4D8);
//   static const Color accentLight = Color(0xFF90E0EF);
  
//   static const Color backgroundDark = Color(0xFF0F0F1A);
//   static const Color surfaceDark = Color(0xFF1A1A2E);
//   static const Color surfaceLight = Color(0xFF252542);
  
//   static const Color textPrimary = Colors.white;
//   static const Color textSecondary = Color(0xFFB0B0C8);
//   static const Color textHint = Color(0xFF6B6B8D);
  
//   static const LinearGradient primaryGradient = LinearGradient(
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//     colors: [primaryPurple, primaryDark],
//   );
// }

// class LoginScreen extends ConsumerStatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   ConsumerState<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends ConsumerState<LoginScreen> {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _isLoading = false;
//   bool _obscurePassword = true;
//   final AuthService _authService = AuthService();

//   void _login() async {
//     if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
//       _showError('Please enter email and password');
//       return;
//     }

//     setState(() => _isLoading = true);

//     final result = await _authService.login(
//       _emailController.text.trim(),
//       _passwordController.text.trim(),
//     );

//     setState(() => _isLoading = false);

//     if (result['success']) {
//       String role = result['role'];
//       if (!mounted) return;

//       switch (role) {
//         case 'admin':
//           Navigator.pushReplacement(context,
//               MaterialPageRoute(builder: (_) => const AdminDashboard()));
//           break;
//         case 'teacher':
//           Navigator.pushReplacement(context,
//               MaterialPageRoute(builder: (_) => const TeacherDashboard()));
//           break;
//         case 'student':
//           Navigator.pushReplacement(context,
//               MaterialPageRoute(builder: (_) => const StudentDashboard()));
//           break;
//       }
//     } else {
//       _showError(result['message']);
//     }
//   }

//   void _showError(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.error_rounded, color: Colors.white, size: 20),
//             const SizedBox(width: 12),
//             Expanded(child: Text(msg)),
//           ],
//         ),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppTheme.backgroundDark,
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // Logo - Using your app icon image
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   gradient: AppTheme.primaryGradient,
//                   borderRadius: BorderRadius.circular(30),
//                   boxShadow: [
//                     BoxShadow(
//                       color: AppTheme.primaryPurple.withOpacity(0.4),
//                       blurRadius: 20,
//                       offset: const Offset(0, 8),
//                     ),
//                   ],
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(20),
//                   child: Image.asset(
//                     'assets/app_icon.png',
//                     width: 80,
//                     height: 80,
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stackTrace) {
//                       // Fallback icon if image not found
//                       return Container(
//                         width: 80,
//                         height: 80,
//                         decoration: BoxDecoration(
//                           color: AppTheme.primaryPurple,
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: const Icon(
//                           Icons.face,
//                           size: 50,
//                           color: Colors.white,
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),
//               const Text(
//                 'Face Attendance System',
//                 style: TextStyle(
//                   color: AppTheme.textPrimary,
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const Text(
//                 'University Smart Attendance',
//                 style: TextStyle(color: AppTheme.textHint, fontSize: 14),
//               ),
//               const SizedBox(height: 40),

//               // Email Field
//               Container(
//                 decoration: BoxDecoration(
//                   color: AppTheme.surfaceLight,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.2)),
//                 ),
//                 child: TextField(
//                   controller: _emailController,
//                   style: const TextStyle(color: AppTheme.textPrimary),
//                   decoration: InputDecoration(
//                     hintText: 'Email',
//                     hintStyle: const TextStyle(color: AppTheme.textHint),
//                     prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryPurple),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(16),
//                       borderSide: BorderSide.none,
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),

//               // Password Field
//               Container(
//                 decoration: BoxDecoration(
//                   color: AppTheme.surfaceLight,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.2)),
//                 ),
//                 child: TextField(
//                   controller: _passwordController,
//                   obscureText: _obscurePassword,
//                   style: const TextStyle(color: AppTheme.textPrimary),
//                   decoration: InputDecoration(
//                     hintText: 'Password',
//                     hintStyle: const TextStyle(color: AppTheme.textHint),
//                     prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryPurple),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscurePassword ? Icons.visibility_off : Icons.visibility,
//                         color: AppTheme.textHint,
//                       ),
//                       onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(16),
//                       borderSide: BorderSide.none,
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // Login Button
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _login,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppTheme.primaryPurple,
//                     foregroundColor: AppTheme.textPrimary,
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                   ),
//                   child: _isLoading
//                       ? const SizedBox(
//                           height: 24,
//                           width: 24,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2.5,
//                             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                           ),
//                         )
//                       : const Text(
//                           'Login',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                 ),
//               ),

//               // Sign Up Row
//               const SizedBox(height: 16),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     "Don't have an account? ",
//                     style: TextStyle(color: AppTheme.textHint),
//                   ),
//                   GestureDetector(
//                     onTap: () => Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => const SignUpScreen()),
//                     ),
//                     child: const Text(
//                       'Sign Up',
//                       style: TextStyle(
//                         color: AppTheme.primaryPurple,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 15,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }















import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../admin/admin_dashboard.dart';
import '../teacher/teacher_dashboard.dart';
import '../student/student_dashboard.dart';
import 'signup_screen.dart';

// AppTheme for consistent styling
class AppTheme {
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF3F3D9E);
  static const Color accentCyan = Color(0xFF00B4D8);
  static const Color accentLight = Color(0xFF90E0EF);
  
  static const Color backgroundDark = Color(0xFF0F0F1A);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF252542);
  
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0C8);
  static const Color textHint = Color(0xFF6B6B8D);
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, primaryDark],
  );
}

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
      _showError('Please enter email and password');
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
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo - Using your app_icon.png
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/app_icon.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback icon if image fails to load
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.face,
                        size: 50,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Face Attendance System',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'University Smart Attendance',
                style: TextStyle(color: AppTheme.textHint, fontSize: 14),
              ),
              const SizedBox(height: 40),

              // Email Field
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.2)),
                ),
                child: TextField(
                  controller: _emailController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: const TextStyle(color: AppTheme.textHint),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.2)),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: AppTheme.textHint),
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryPurple),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.textHint,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: AppTheme.textPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              // Sign Up Row
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(color: AppTheme.textHint),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppTheme.primaryPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
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