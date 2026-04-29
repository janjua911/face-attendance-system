import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../services/cloudinary_service.dart';
import 'login_screen.dart';
import '../../services/embedding_service.dart';

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

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  String _selectedRole = 'student';

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rollNoController = TextEditingController();
  final _cnicController = TextEditingController();
  final _employeeIdController = TextEditingController();
  String _selectedDepartment = 'Computer Science';
  String _passwordStrength = '';
  Color _passwordColor = AppTheme.success;
  bool _obscurePassword = true;

  final List<Uint8List> _photos = [];
  bool _isLoading = false;
  final CloudinaryService _cloudinary = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

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
      setState(() => _passwordStrength = '');
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

  Future<void> _pickMultiplePhotos() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty) return;
    int canAdd = 20 - _photos.length;
    final toAdd = images.take(canAdd).toList();
    for (var img in toAdd) {
      final bytes = await img.readAsBytes();
      setState(() => _photos.add(bytes));
    }
    _showSnack('${toAdd.length} photos added!', AppTheme.success);
  }

  Future<void> _pickFromCamera() async {
    if (_photos.length >= 20) {
      _showSnack('Maximum 20 photos already added!', AppTheme.warning);
      return;
    }
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _photos.add(bytes));
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add Face Photos',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload clear photos from different angles',
              style: TextStyle(color: AppTheme.textHint, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPhotoOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromCamera();
                  },
                  color: AppTheme.accentCyan,
                ),
                _buildPhotoOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(ctx);
                    _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    ).then((img) async {
                      if (img != null) {
                        final bytes = await img.readAsBytes();
                        setState(() => _photos.add(bytes));
                      }
                    });
                  },
                  color: AppTheme.primaryPurple,
                ),
                _buildPhotoOption(
                  icon: Icons.photo_album,
                  label: 'Multiple',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickMultiplePhotos();
                  },
                  color: AppTheme.warning,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5), width: 1),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnack('Please fill all fields!', AppTheme.error);
      return;
    }
    if (_passwordController.text.length < 6) {
      _showSnack('Password must be at least 6 characters!', AppTheme.error);
      return;
    }
    if (_selectedRole == 'student') {
      if (_rollNoController.text.isEmpty || _cnicController.text.isEmpty) {
        _showSnack('Roll Number and CNIC are required!', AppTheme.error);
        return;
      }
      if (_cnicController.text.length != 13) {
        _showSnack('CNIC must be exactly 13 digits!', AppTheme.error);
        return;
      }
      if (_photos.length < 5) {
        _showSnack('Please add at least 5 face photos!', AppTheme.error);
        return;
      }
    }
    if (_selectedRole == 'teacher' && _employeeIdController.text.isEmpty) {
      _showSnack('Employee ID is required!', AppTheme.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final existingUser = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      if (existingUser.docs.isNotEmpty) {
        setState(() => _isLoading = false);
        _showSnack('This email is already registered!', AppTheme.error);
        return;
      }

      List<String> photoUrls = [];
      if (_selectedRole == 'student') {
        for (int i = 0; i < _photos.length; i++) {
          _showSnack(
            'Uploading photo ${i + 1}/${_photos.length}...',
            AppTheme.primaryPurple,
          );
          String? url = await _cloudinary.uploadImage(
            _photos[i],
            '${_rollNoController.text}_photo_$i.jpg',
          );
          if (url != null) photoUrls.add(url);
        }
      }

      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      String uid = cred.user!.uid;
      final db = FirebaseFirestore.instance;

      await db.collection('users').doc(uid).set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'department': _selectedDepartment,
        if (_selectedRole == 'student') 'rollNo': _rollNoController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      if (_selectedRole == 'student') {
        await db.collection('students').doc(uid).set({
          'uid': uid,
          'rollNo': _rollNoController.text.trim(),
          'name': _nameController.text.trim(),
          'cnic': _cnicController.text.trim(),
          'department': _selectedDepartment,
          'email': _emailController.text.trim(),
          'photoUrls': photoUrls,
          'faceEmbedding': [],
          'embeddingStatus': 'pending',
          'validPhotos': 0,
          'createdAt': Timestamp.now(),
        });
      } else {
        await db.collection('teachers').doc(uid).set({
          'uid': uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'employeeId': _employeeIdController.text.trim(),
          'department': _selectedDepartment,
          'assignedCourses': [],
          'createdAt': Timestamp.now(),
        });
      }

      if (_selectedRole == 'student' && photoUrls.isNotEmpty) {
        _showSnack('Generating face embedding...', AppTheme.primaryPurple);
        
        final embeddingService = EmbeddingService();
        final embResult = await embeddingService.generateAndSaveEmbedding(
          studentUid: uid,
          photoUrls: photoUrls,
          onProgress: (msg) => _showSnack(msg, AppTheme.primaryPurple),
        );

        if (embResult['success']) {
          _showSnack('Registration complete! Embedding ready.', AppTheme.success);
        } else {
          _showSnack('Registered! Face embedding pending — contact admin.', AppTheme.warning);
        }
      }

      setState(() => _isLoading = false);
      _showSnack('Registration successful!', AppTheme.success);
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error: ${e.toString()}', AppTheme.error);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppTheme.success ? Icons.check_circle : 
              color == AppTheme.error ? Icons.error : 
              Icons.info,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: _buildGradientAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            _buildRoleSelection(),
            const SizedBox(height: 24),
            _buildPersonalInfoSection(),
            const SizedBox(height: 24),
            if (_selectedRole == 'student') _buildStudentSection(),
            if (_selectedRole == 'teacher') _buildTeacherSection(),
            const SizedBox(height: 24),
            _buildRegisterButton(),
            const SizedBox(height: 16),
            _buildLoginLink(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildGradientAppBar() {
    return AppBar(
      title: const Text(
        'Create Account',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppTheme.textPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: () => Navigator.pop(context),
      ),
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

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(
              'assets/app_icon.png',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.person_add, color: Colors.white, size: 50);
              },
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Create Your Account',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Join the university smart attendance system',
            style: TextStyle(color: AppTheme.textHint, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryPurple, AppTheme.accentCyan],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_outline, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            const Text(
              'I am a...',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _RoleCard(
                icon: Icons.school,
                label: 'Student',
                isSelected: _selectedRole == 'student',
                color: AppTheme.warning,
                onTap: () => setState(() => _selectedRole = 'student'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleCard(
                icon: Icons.person,
                label: 'Teacher',
                isSelected: _selectedRole == 'teacher',
                color: const Color(0xFF26A69A),
                onTap: () => setState(() => _selectedRole = 'teacher'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryPurple, AppTheme.accentCyan],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(_nameController, 'Full Name', Icons.person),
            _buildTextField(_emailController, 'Email Address', Icons.email,
                keyboardType: TextInputType.emailAddress),
            _buildPasswordField(),
            _buildDepartmentDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textHint),
          prefixIcon: Icon(icon, color: AppTheme.primaryPurple, size: 22),
          counterText: maxLength != null ? null : '',
          filled: true,
          fillColor: AppTheme.surfaceLight,
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
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: AppTheme.textPrimary),
            onChanged: _checkPasswordStrength,
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
                    const Icon(Icons.school, size: 18, color: AppTheme.primaryPurple),
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

  Widget _buildStudentSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.warning, Color(0xFFFFB74D)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Student Details',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(_rollNoController, 'Roll Number', Icons.numbers),
            _buildCNICField(),
            const SizedBox(height: 8),
            _buildPhotoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCNICField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: _cnicController,
        keyboardType: TextInputType.number,
        maxLength: 13,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'CNIC (13 digits, no dashes)',
          hintStyle: const TextStyle(color: AppTheme.textHint),
          prefixIcon: const Icon(Icons.credit_card, color: AppTheme.primaryPurple, size: 22),
          counterStyle: const TextStyle(color: AppTheme.textHint),
          filled: true,
          fillColor: AppTheme.surfaceLight,
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
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_camera, size: 16, color: AppTheme.warning),
            const SizedBox(width: 8),
            Text(
              'Face Photos (${_photos.length}/20)',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Add 10-20 clear face photos from different angles',
          style: TextStyle(color: AppTheme.textHint, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (_photos.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemCount: _photos.length,
            itemBuilder: (ctx, i) => Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_photos[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => setState(() => _photos.removeAt(i)),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _showPhotoOptions,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate, color: AppTheme.warning, size: 28),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Add Face Photos', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                    Text('Camera • Gallery • Multiple', style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Teacher Details',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(_employeeIdController, 'Employee ID', Icons.badge),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'Create Account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        ),
        child: RichText(
          text: TextSpan(
            text: 'Already have an account? ',
            style: const TextStyle(color: AppTheme.textHint),
            children: const [
              TextSpan(
                text: 'Login',
                style: TextStyle(
                  color: AppTheme.primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppTheme.textHint.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppTheme.textHint, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textHint,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}