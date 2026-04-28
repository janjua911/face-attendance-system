import 'package:flutter/material.dart';
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

  void _checkPasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() { _passwordStrength = ''; });
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

  // Pick MULTIPLE photos at once
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

    // Only add up to limit
    final toAdd = images.take(canAdd).toList();
    for (var img in toAdd) {
      final bytes = await img.readAsBytes();
      setState(() => _photos.add(bytes));
    }

    _showSnack('${toAdd.length} photos added!', Colors.green);
  }

  // Single photo from camera
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

  // Show photo source picker
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Photos',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PhotoOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromCamera();
                  },
                ),
                _PhotoOption(
                  icon: Icons.photo_library,
                  label: 'Gallery\n(1 photo)',
                  onTap: () {
                    Navigator.pop(ctx);
                    _picker.pickImage(source: ImageSource.gallery,
                        imageQuality: 85).then((img) async {
                      if (img != null) {
                        final bytes = await img.readAsBytes();
                        setState(() => _photos.add(bytes));
                      }
                    });
                  },
                ),
                _PhotoOption(
                  icon: Icons.photo_album,
                  label: 'Select\nMultiple',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickMultiplePhotos();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Save student
  Future<void> _saveStudent() async {
    if (_nameController.text.isEmpty ||
        _rollNoController.text.isEmpty ||
        _cnicController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnack('Sab fields fill karo!', Colors.red);
      return;
    }

    // Password validation
    if (_passwordController.text.length < 6) {
      _showSnack('Password kam az kam 6 characters ka hona chahiye!', Colors.red);
      return;
    }

    // CNIC validation  
    if (_cnicController.text.length != 13) {
      _showSnack('CNIC exactly 13 digits ka hona chahiye!', Colors.red);
      return;
    }

    if (_photos.length < 5) {
      _showSnack('Kam az kam 5 photos add karo!', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload photos to Cloudinary
      List<String> photoUrls = [];
      for (int i = 0; i < _photos.length; i++) {
        _showSnack('Uploading photo ${i + 1}/${_photos.length}...', Colors.blue);
        String? url = await _cloudinaryService.uploadImage(
          _photos[i],
          '${_rollNoController.text}_photo_$i.jpg',
        );
        if (url != null) photoUrls.add(url);
      }

      // 2. Create Firebase Auth account for student
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
        _showSnack('Student registered successfully! ✅', Colors.green);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      } else {
        _showSnack(result['message'], Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error: $e', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text('Add New Student'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form Section
            _sectionTitle('Student Information'),
            const SizedBox(height: 12),
            _buildField(_nameController, 'Full Name', Icons.person),
            _buildField(_rollNoController, 'Roll Number', Icons.badge),
            
            // CNIC Field with 13 digit constraint
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _cnicController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                maxLength: 13,
                decoration: InputDecoration(
                  hintText: 'CNIC (13 digits, no dashes)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.credit_card, color: Colors.indigo),
                  counterStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF16213E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            
            _buildField(_emailController, 'Email', Icons.email,
                keyboardType: TextInputType.emailAddress),
            
            // Password field with strength indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                onChanged: _checkPasswordStrength,
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.lock, color: Colors.indigo),
                  filled: true,
                  fillColor: const Color(0xFF16213E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (_passwordStrength.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 12),
                child: Text(_passwordStrength,
                    style: TextStyle(color: _passwordColor, fontSize: 12)),
              ),

            // Department Dropdown
            const SizedBox(height: 8),
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
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                  isExpanded: true,
                  items: _departments
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedDepartment = val!),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Photos Section
            _sectionTitle('Face Photos (${_photos.length}/20)'),
            const SizedBox(height: 4),
            const Text('Add 15-20 photos from different angles',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 12),

            // Photo Grid
            if (_photos.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                        onTap: () => setState(() => _photos.removeAt(i)),
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

            const SizedBox(height: 12),

            // Add Photo Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showPhotoOptions,
                icon: const Icon(Icons.add_a_photo, color: Colors.indigo),
                label: const Text('Add Photo',
                    style: TextStyle(color: Colors.indigo)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.indigo),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveStudent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Register Student',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold));
  }

  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
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

class _PhotoOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.indigo, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}