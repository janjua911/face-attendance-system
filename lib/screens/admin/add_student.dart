import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../models/student_model.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  String _passwordStrength = '';
  Color _passwordColor = Colors.transparent;
  int _activeStep = 0;

  void _checkPasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() { _passwordStrength = ''; });
      return;
    }
    if (password.length < 6) {
      setState(() {
        _passwordStrength = 'Weak — minimum 6 characters required';
        _passwordColor = Colors.red;
      });
    } else if (password.length < 10 || !password.contains(RegExp(r'[0-9]'))) {
      setState(() {
        _passwordStrength = 'Medium — add a number for strength';
        _passwordColor = Colors.orange;
      });
    } else {
      setState(() {
        _passwordStrength = 'Strong password';
        _passwordColor = Colors.green;
      });
    }
  }

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollNoController = TextEditingController();
  final _cnicController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedDepartment = 'Computer Science';
  
  final List<Uint8List> _photos = [];
  bool _isLoading = false;
  
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  final List<String> _departments = [
    'Computer Science',
    'Software Engineering',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Business Administration',
    'Mathematics',
  ];

  Future<void> _pickMultiplePhotos() async {
    final List<XFile> images = await _picker.pickMultiImage(
      imageQuality: 85,
    );

    if (images.isEmpty) return;

    int canAdd = 20 - _photos.length;
    if (canAdd <= 0) {
      _showSnack('Maximum 20 photos already added!', Colors.orange);
      return;
    }

    final toAdd = images.take(canAdd).toList();
    for (var img in toAdd) {
      final bytes = await img.readAsBytes();
      setState(() => _photos.add(bytes));
    }

    _showSnack('${toAdd.length} photos added successfully!', Colors.green);
  }

  Future<void> _pickFromCamera() async {
    if (_photos.length >= 20) {
      _showSnack('Maximum 20 photos already added!', Colors.orange);
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
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
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
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add Student Photos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload 15-20 photos from different angles',
              style: TextStyle(color: Colors.white54, fontSize: 14),
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
                  color: const Color(0xFF00B4D8),
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
                  color: const Color(0xFF48CAE4),
                ),
                _buildPhotoOption(
                  icon: Icons.photo_album,
                  label: 'Multiple',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickMultiplePhotos();
                  },
                  color: const Color(0xFF90E0EF),
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
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_photos.length < 5) {
      _showSnack('Please add at least 5 photos!', Colors.red);
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
        _showSnack('This email is already registered!', Colors.red);
        return;
      }

      List<String> photoUrls = [];
      for (int i = 0; i < _photos.length; i++) {
        _showSnack('Uploading photo ${i + 1}/${_photos.length}...', const Color(0xFF00B4D8));
        String? url = await _cloudinaryService.uploadImage(
          _photos[i],
          '${_rollNoController.text}_photo_$i.jpg',
        );
        if (url != null) photoUrls.add(url);
      }

      final result = await _firestoreService.createStudent(
        name: _nameController.text.trim(),
        rollNo: _rollNoController.text.trim(),
        cnic: _cnicController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        department: _selectedDepartment,
        photoUrls: photoUrls,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        _showSuccessDialog();
      } else {
        _showSnack(result['message'], Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error: $e', Colors.red);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 16),
            Text('Registration Successful!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Student has been registered successfully.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF00B4D8),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Go Back', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(color == Colors.green ? Icons.check_circle : Icons.info, color: Colors.white, size: 20),
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
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Add New Student',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6C63FF), Color(0xFF3F3D9E)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Progress Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  _buildProgressStep(0, 'Info', _activeStep >= 0),
                  Expanded(child: _buildProgressLine(_activeStep > 0)),
                  _buildProgressStep(1, 'Photos', _activeStep >= 1),
                  Expanded(child: _buildProgressLine(_activeStep > 1)),
                  _buildProgressStep(2, 'Submit', _activeStep >= 2),
                ],
              ),
            ),
            
            // Main Form Container
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF6C63FF), Color(0xFF3F3D9E)],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.school, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Student Registration',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Fill in the details below',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Basic Information',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Enter student\'s personal details',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            
                            _buildModernField(
                              controller: _nameController,
                              hint: 'Full Name',
                              icon: Icons.person_outline,
                              validator: (v) => v!.isEmpty ? 'Name is required' : null,
                            ),
                            
                            _buildModernField(
                              controller: _rollNoController,
                              hint: 'Roll Number',
                              icon: Icons.numbers_outlined,
                              validator: (v) => v!.isEmpty ? 'Roll number is required' : null,
                            ),
                            
                            _buildModernField(
                              controller: _cnicController,
                              hint: 'CNIC (13 digits)',
                              icon: Icons.credit_card_outlined,
                              keyboardType: TextInputType.number,
                              maxLength: 13,
                              validator: (v) {
                                if (v!.isEmpty) return 'CNIC is required';
                                if (v.length != 13) return 'CNIC must be 13 digits';
                                return null;
                              },
                            ),
                            
                            _buildModernField(
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
                            
                            _buildModernField(
                              controller: _passwordController,
                              hint: 'Password',
                              icon: Icons.lock_outline,
                              isPassword: true,
                              onChanged: _checkPasswordStrength,
                              validator: (v) {
                                if (v!.isEmpty) return 'Password is required';
                                if (v.length < 6) return 'Password must be at least 6 characters';
                                return null;
                              },
                            ),
                            
                            if (_passwordStrength.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 12, bottom: 12),
                                child: Row(
                                  children: [
                                    Icon(
                                      _passwordColor == Colors.green ? Icons.check_circle : Icons.warning,
                                      color: _passwordColor,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(_passwordStrength, style: TextStyle(color: _passwordColor, fontSize: 12)),
                                  ],
                                ),
                              ),
                            
                            const SizedBox(height: 8),
                            const Text('Department', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF252542),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedDepartment,
                                  dropdownColor: const Color(0xFF1A1A2E),
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6C63FF)),
                                  isExpanded: true,
                                  items: _departments.map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.school_outlined, size: 18, color: Color(0xFF6C63FF)),
                                        const SizedBox(width: 12),
                                        Text(d),
                                      ],
                                    ),
                                  )).toList(),
                                  onChanged: (val) => setState(() => _selectedDepartment = val!),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Photos Section
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C63FF).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.photo_camera_outlined, color: Color(0xFF6C63FF), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Student Photos (${_photos.length}/20)',
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const Text('Add 15-20 photos from different angles', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
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
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.memory(
                                        _photos[i],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _photos.removeAt(i)),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, size: 14, color: Colors.white),
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
                                  color: const Color(0xFF252542),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3), style: BorderStyle.solid),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined, color: const Color(0xFF6C63FF), size: 28),
                                    const SizedBox(width: 12),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text('Add Photos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                        Text('Camera • Gallery • Multiple', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveStudent,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  foregroundColor: Colors.white,
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
                                          Icon(Icons.check_circle_outline),
                                          SizedBox(width: 12),
                                          Text(
                                            'Register Student',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
            color: isActive ? const Color(0xFF6C63FF) : const Color(0xFF252542),
            border: Border.all(color: isActive ? const Color(0xFF6C63FF) : Colors.grey.shade700, width: 2),
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade500, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: isActive ? const Color(0xFF6C63FF) : Colors.grey.shade600, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Container(
      height: 2,
      color: isActive ? const Color(0xFF6C63FF) : const Color(0xFF252542),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    int? maxLength,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        maxLength: maxLength,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 22),
          counterText: '',
          filled: true,
          fillColor: const Color(0xFF252542),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
        ),
      ),
    );
  }
}