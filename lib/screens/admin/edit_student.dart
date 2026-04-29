import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/embedding_service.dart';
import 'fix_embeddings.dart';

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

class EditStudentScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> data;

  const EditStudentScreen({
    super.key,
    required this.uid,
    required this.data,
  });

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  late TextEditingController _nameController;
  late TextEditingController _rollNoController;
  late TextEditingController _cnicController;
  late TextEditingController _newPasswordController;
  late String _selectedDepartment;
  bool _isLoading = false;
  bool _changePassword = false;

  final List<String> _departments = [
    'Computer Science',
    'Software Engineering',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Business Administration',
    'Mathematics',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data['name']);
    _rollNoController = TextEditingController(text: widget.data['rollNo']);
    _cnicController = TextEditingController(text: widget.data['cnic'] ?? '');
    _newPasswordController = TextEditingController();
    _selectedDepartment = widget.data['department'] ?? 'Computer Science';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollNoController.dispose();
    _cnicController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _retryEmbedding(Map<String, dynamic> studentData) async {
    final photoUrls = List<String>.from(studentData['photoUrls'] ?? []);
    
    if (photoUrls.isEmpty) {
      _showSnack('No photos found! Please add photos first.', AppTheme.error);
      return;
    }

    setState(() => _isLoading = true);
    _showSnack('Generating face embedding...', AppTheme.primaryPurple);

    final embeddingService = EmbeddingService();
    final result = await embeddingService.generateAndSaveEmbedding(
      studentUid: widget.uid,
      photoUrls: photoUrls,
      onProgress: (msg) => _showSnack(msg, AppTheme.primaryPurple),
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      _showSnack(
        'Embedding generated! ${result['validPhotos']}/${result['totalPhotos']} photos used.',
        AppTheme.success,
      );
    } else {
      _showSnack('Error: ${result['message']}', AppTheme.error);
    }
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty || _rollNoController.text.isEmpty) {
      _showSnack('Name and Roll Number are required!', AppTheme.error);
      return;
    }

    if (_cnicController.text.isNotEmpty && _cnicController.text.length != 13) {
      _showSnack('CNIC must be exactly 13 digits!', AppTheme.error);
      return;
    }

    if (_changePassword && _newPasswordController.text.length < 6) {
      _showSnack('Password must be at least 6 characters!', AppTheme.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = FirebaseFirestore.instance;

      await db.collection('students').doc(widget.uid).update({
        'name': _nameController.text.trim(),
        'rollNo': _rollNoController.text.trim(),
        'cnic': _cnicController.text.trim(),
        'department': _selectedDepartment,
        'updatedAt': Timestamp.now(),
      });

      await db.collection('users').doc(widget.uid).update({
        'name': _nameController.text.trim(),
        'rollNo': _rollNoController.text.trim(),
        'department': _selectedDepartment,
      });

      final enrollments = await db
          .collection('enrollments')
          .where('studentId', isEqualTo: widget.uid)
          .get();
      for (var doc in enrollments.docs) {
        await doc.reference.update({
          'studentName': _nameController.text.trim()
        });
      }

      if (_changePassword && _newPasswordController.text.isNotEmpty) {
        _showSnack(
          'Information updated! For password change, the student can reset it from their account.',
          AppTheme.warning,
        );
      } else {
        _showSnack('Student updated successfully!', AppTheme.success);
      }

      setState(() => _isLoading = false);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error: $e', AppTheme.error);
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
        duration: const Duration(seconds: 3),
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
            _buildStudentCard(),
            const SizedBox(height: 20),
            _buildEmbeddingStatus(),
            const SizedBox(height: 20),
            _buildEditForm(),
            const SizedBox(height: 24),
            _buildInfoNote(),
            const SizedBox(height: 24),
            _buildSaveButton(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildGradientAppBar() {
    return AppBar(
      title: const Text(
        'Edit Student',
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

  Widget _buildStudentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryPurple, AppTheme.accentCyan],
              ),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.transparent,
              child: Text(
                widget.data['name'][0].toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.data['name'],
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email, size: 14, color: AppTheme.textHint),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.data['email'],
                        style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.badge, size: 14, color: AppTheme.textHint),
                    const SizedBox(width: 4),
                    Text(
                      'Roll: ${widget.data['rollNo']}',
                      style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmbeddingStatus() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .doc(widget.uid)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final data = snap.data!.data() as Map<String, dynamic>;
        final status = data['embeddingStatus'] ?? 'unknown';
        final validPhotos = data['validPhotos'] ?? 0;

        Color statusColor = AppTheme.warning;
        String statusText = 'Pending';
        IconData statusIcon = Icons.hourglass_empty;
        
        if (status == 'complete') {
          statusColor = AppTheme.success;
          statusText = 'Complete ($validPhotos photos)';
          statusIcon = Icons.check_circle;
        } else if (status == 'failed') {
          statusColor = AppTheme.error;
          statusText = 'Failed — Retry needed';
          statusIcon = Icons.error;
        } else if (status == 'processing') {
          statusColor = AppTheme.primaryPurple;
          statusText = 'Processing...';
          statusIcon = Icons.sync;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Face Embedding Status',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (status != 'complete' && status != 'processing')
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _retryEmbedding(data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditForm() {
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
                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Edit Information',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildField(_nameController, 'Full Name', Icons.person),
            _buildField(_rollNoController, 'Roll Number', Icons.numbers),
            _buildCNICField(),
            _buildDepartmentDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textHint),
          prefixIcon: Icon(icon, color: AppTheme.primaryPurple, size: 22),
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

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info, color: AppTheme.warning, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Password reset: Use Firebase Console → Authentication → User → Send password reset email.',
              style: TextStyle(color: AppTheme.warning, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveChanges,
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
                  Icon(Icons.save, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}