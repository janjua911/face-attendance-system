import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../services/cloudinary_service.dart';
import 'login_screen.dart';
import '../../services/embedding_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  String _selectedRole = 'student';
  int _currentStep = 0; // 0=role, 1=info, 2=photos(student only)

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rollNoController = TextEditingController();
  final _cnicController = TextEditingController();
  final _employeeIdController = TextEditingController();
  String _selectedDepartment = 'Computer Science';
  String _passwordStrength = '';
  Color _passwordColor = Colors.transparent;

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
        _passwordStrength = 'Weak — 6+ characters chahiye';
        _passwordColor = Colors.red;
      });
    } else if (password.length < 10 ||
        !password.contains(RegExp(r'[0-9]'))) {
      setState(() {
        _passwordStrength = 'Medium — number bhi add karo';
        _passwordColor = Colors.orange;
      });
    } else {
      setState(() {
        _passwordStrength = 'Strong ✅';
        _passwordColor = Colors.green;
      });
    }
  }

  Future<void> _pickMultiplePhotos() async {
    final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85);
    if (images.isEmpty) return;
    int canAdd = 20 - _photos.length;
    final toAdd = images.take(canAdd).toList();
    for (var img in toAdd) {
      final bytes = await img.readAsBytes();
      setState(() => _photos.add(bytes));
    }
    _showSnack('${toAdd.length} photos added!', Colors.green);
  }

  Future<void> _register() async {
    // Validations
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnack('Sab fields fill karo!', Colors.red);
      return;
    }
    if (_passwordController.text.length < 6) {
      _showSnack('Password kam az kam 6 characters!', Colors.red);
      return;
    }
    if (_selectedRole == 'student') {
      if (_rollNoController.text.isEmpty ||
          _cnicController.text.isEmpty) {
        _showSnack('Roll No aur CNIC fill karo!', Colors.red);
        return;
      }
      if (_cnicController.text.length != 13) {
        _showSnack('CNIC exactly 13 digits!', Colors.red);
        return;
      }
      if (_photos.length < 5) {
        _showSnack('Kam az kam 5 photos add karo!', Colors.red);
        return;
      }
    }
    if (_selectedRole == 'teacher' &&
        _employeeIdController.text.isEmpty) {
      _showSnack('Employee ID fill karo!', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload photos if student
      List<String> photoUrls = [];
      if (_selectedRole == 'student') {
        for (int i = 0; i < _photos.length; i++) {
          _showSnack(
              'Uploading photo ${i + 1}/${_photos.length}...',
              Colors.blue);
          String? url = await _cloudinary.uploadImage(
            _photos[i],
            '${_rollNoController.text}_photo_$i.jpg',
          );
          if (url != null) photoUrls.add(url);
        }
      }

      // Firebase Auth account
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      String uid = cred.user!.uid;
      final db = FirebaseFirestore.instance;

      // Users collection
      await db.collection('users').doc(uid).set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'department': _selectedDepartment,
        if (_selectedRole == 'student')
          'rollNo': _rollNoController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      // Role specific collection
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
          'embeddingStatus': 'pending', // ← Step 3 ke liye
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

      // ✅ NEW: Student register hone ke baad — embedding generate karo
      if (_selectedRole == 'student' && photoUrls.isNotEmpty) {
        _showSnack('🧠 Generating face embedding...', Colors.purple);
        
        final embeddingService = EmbeddingService();
        final embResult = await embeddingService.generateAndSaveEmbedding(
          studentUid: uid,
          photoUrls: photoUrls,
          onProgress: (msg) => _showSnack(msg, Colors.purple),
        );

        if (embResult['success']) {
          _showSnack(
            '✅ Registration complete! Embedding ready.',
            Colors.green,
          );
        } else {
          _showSnack(
            '⚠️ Registered! Face embedding pending — contact admin.',
            Colors.orange,
          );
        }
      }

      setState(() => _isLoading = false);
      _showSnack('Registration successful! ✅', Colors.green);
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error: ${e.toString()}', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: color,
          duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.indigo, Colors.indigoAccent],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.person_add, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text('Sign Up',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Text('Create your university account',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Role Selection
            const Text('I am a...',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RoleCard(
                    icon: Icons.school,
                    label: 'Student',
                    isSelected: _selectedRole == 'student',
                    color: Colors.orange,
                    onTap: () =>
                        setState(() => _selectedRole = 'student'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RoleCard(
                    icon: Icons.person,
                    label: 'Teacher',
                    isSelected: _selectedRole == 'teacher',
                    color: Colors.teal,
                    onTap: () =>
                        setState(() => _selectedRole = 'teacher'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Common Fields
            const Text('Personal Information',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _buildField(_nameController, 'Full Name', Icons.person),
            _buildField(_emailController, 'Email', Icons.email,
                keyboardType: TextInputType.emailAddress),

            // Password with strength
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              onChanged: _checkPasswordStrength,
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon:
                    const Icon(Icons.lock, color: Colors.indigo),
                filled: true,
                fillColor: const Color(0xFF16213E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_passwordStrength.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4, bottom: 8),
                child: Text(_passwordStrength,
                    style: TextStyle(
                        color: _passwordColor, fontSize: 12)),
              )
            else
              const SizedBox(height: 12),

            // Department
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDepartment,
                  dropdownColor: const Color(0xFF16213E),
                  style: const TextStyle(color: Colors.white),
                  icon: const Icon(Icons.arrow_drop_down,
                      color: Colors.indigo),
                  isExpanded: true,
                  items: _departments
                      .map((d) =>
                          DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedDepartment = val!),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Student specific fields
            if (_selectedRole == 'student') ...[
              const SizedBox(height: 8),
              const Text('Student Details',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildField(
                  _rollNoController, 'Roll Number', Icons.badge),
              TextField(
                controller: _cnicController,
                keyboardType: TextInputType.number,
                maxLength: 13,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'CNIC (13 digits)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.credit_card,
                      color: Colors.indigo),
                  counterStyle:
                      const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF16213E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Face Photos
              const Text('Face Photos',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                '${_photos.length}/20 photos — Add 10-20 clear face photos',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 12),

              if (_photos.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (ctx, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(_photos[i],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _photos.removeAt(i)),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickMultiplePhotos,
                  icon: const Icon(Icons.add_a_photo,
                      color: Colors.indigo),
                  label: const Text('Add Face Photos',
                      style: TextStyle(color: Colors.indigo)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.indigo),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],

            // Teacher specific
            if (_selectedRole == 'teacher') ...[
              const SizedBox(height: 8),
              const Text('Teacher Details',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildField(_employeeIdController, 'Employee ID',
                  Icons.badge),
            ],

            const SizedBox(height: 24),

            // Register Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Text('Create Account',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),

            // Already have account
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen())),
                child: const Text(
                  'Already have an account? Login',
                  style: TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.indigo),
          filled: true,
          fillColor: const Color(0xFF16213E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? color : Colors.white38,
                size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: isSelected ? color : Colors.white38,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}