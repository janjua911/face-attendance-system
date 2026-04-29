import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import the theme file (make sure this path is correct in your project)
// import '../../theme/app_theme.dart';

// For now, including the theme directly to ensure consistency
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
  
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFFF4444);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF2196F3);
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, primaryDark],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceDark, Color(0xFF1E1E35)],
  );
  
  static List<BoxShadow> get defaultShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}

enum SnackBarType { success, error, warning, info }

void showCustomSnackBar(
  BuildContext context,
  String message, {
  SnackBarType type = SnackBarType.info,
}) {
  Color bgColor;
  IconData icon;
  
  switch (type) {
    case SnackBarType.success:
      bgColor = AppTheme.success;
      icon = Icons.check_circle_rounded;
      break;
    case SnackBarType.error:
      bgColor = AppTheme.error;
      icon = Icons.error_rounded;
      break;
    case SnackBarType.warning:
      bgColor = AppTheme.warning;
      icon = Icons.warning_rounded;
      break;
    case SnackBarType.info:
      bgColor = AppTheme.info;
      icon = Icons.info_rounded;
      break;
  }
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ),
  );
}

class AddTeacherScreen extends StatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _employeeIdController = TextEditingController();
  String _selectedDepartment = 'Computer Science';
  bool _isLoading = false;
  int _activeStep = 0;
  
  String _passwordStrength = '';
  Color _passwordColor = AppTheme.success;
  bool _obscurePassword = true;

  final List<String> _departments = [
    'Computer Science',
    'Software Engineering',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Business Administration',
    'Mathematics',
  ];

  void _checkPasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() { _passwordStrength = ''; });
      return;
    }
    if (password.length < 6) {
      setState(() {
        _passwordStrength = 'Weak — minimum 6 characters required';
        _passwordColor = AppTheme.error;
      });
    } else if (password.length < 10 || !password.contains(RegExp(r'[0-9]'))) {
      setState(() {
        _passwordStrength = 'Medium — add a number for strength';
        _passwordColor = AppTheme.warning;
      });
    } else {
      setState(() {
        _passwordStrength = 'Strong password';
        _passwordColor = AppTheme.success;
      });
    }
  }

  Future<void> _saveTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = cred.user!.uid;
      final db = FirebaseFirestore.instance;

      await db.collection('users').doc(uid).set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'teacher',
        'department': _selectedDepartment,
        'createdAt': Timestamp.now(),
      });

      await db.collection('teachers').doc(uid).set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'employeeId': _employeeIdController.text.trim(),
        'department': _selectedDepartment,
        'assignedCourses': [],
        'createdAt': Timestamp.now(),
      });

      setState(() => _isLoading = false);
      _showSuccessDialog();
    } catch (e) {
      setState(() => _isLoading = false);
      showCustomSnackBar(context, 'Error: ${e.toString()}', type: SnackBarType.error);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: AppTheme.success, size: 60),
            SizedBox(height: 16),
            Text('Registration Successful!', style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: const Text(
          'Teacher has been registered successfully.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Go Back', style: TextStyle(color: AppTheme.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: _buildGradientAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: _buildFormCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildGradientAppBar() {
    return AppBar(
      title: const Text(
        'Add New Teacher',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppTheme.textPrimary,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _buildProgressStep(0, 'Info', _activeStep >= 0),
          Expanded(child: _buildProgressLine(_activeStep > 0)),
          _buildProgressStep(1, 'Verify', _activeStep >= 1),
          Expanded(child: _buildProgressLine(_activeStep > 1)),
          _buildProgressStep(2, 'Submit', _activeStep >= 2),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.primaryPurple : AppTheme.surfaceLight,
            border: Border.all(color: isActive ? AppTheme.primaryPurple : Colors.grey.shade700, width: 2),
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? AppTheme.textPrimary : Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.primaryPurple : Colors.grey.shade600,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Container(
      height: 2,
      color: isActive ? AppTheme.primaryPurple : AppTheme.surfaceLight,
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Column(
        children: [
          _buildCardHeader(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  hint: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (v) => v!.isEmpty ? 'Name is required' : null,
                ),
                _buildTextField(
                  controller: _employeeIdController,
                  hint: 'Employee ID',
                  icon: Icons.badge_outlined,
                  validator: (v) => v!.isEmpty ? 'Employee ID is required' : null,
                ),
                _buildTextField(
                  controller: _emailController,
                  hint: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v!.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter valid email';
                    return null;
                  },
                ),
                _buildPasswordField(),
                const SizedBox(height: 8),
                _buildDepartmentDropdown(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.textPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.school_outlined, color: AppTheme.textPrimary, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teacher Registration',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Fill in the teacher details below',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.accentCyan, Color(0xFF48CAE4)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.person_add_alt_1, color: AppTheme.textPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Basic Information',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Enter teacher\'s personal details',
                style: TextStyle(color: AppTheme.textHint, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppTheme.textPrimary),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textHint),
          prefixIcon: Icon(icon, color: AppTheme.primaryPurple, size: 22),
          filled: true,
          fillColor: AppTheme.surfaceLight,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppTheme.primaryPurple.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.error, width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: AppTheme.textPrimary),
            onChanged: _checkPasswordStrength,
            validator: (v) {
              if (v!.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: const TextStyle(color: AppTheme.textHint),
              prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryPurple, size: 22),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textHint,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: AppTheme.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.primaryPurple.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 1.5),
              ),
            ),
          ),
          if (_passwordStrength.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 8),
              child: Row(
                children: [
                  Icon(
                    _passwordColor == AppTheme.success ? Icons.check_circle : Icons.warning,
                    color: _passwordColor,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _passwordStrength,
                    style: TextStyle(color: _passwordColor, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Department',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDepartment,
              dropdownColor: AppTheme.surfaceDark,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
              icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryPurple),
              isExpanded: true,
              items: _departments.map((d) => DropdownMenuItem(
                value: d,
                child: Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 18, color: AppTheme.primaryPurple),
                    const SizedBox(width: 12),
                    Text(d),
                  ],
                ),
              )).toList(),
              onChanged: (val) => setState(() => _selectedDepartment = val!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveTeacher,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryPurple,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textPrimary),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'Register Teacher',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}