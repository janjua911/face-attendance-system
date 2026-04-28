import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/embedding_service.dart';
import 'fix_embeddings.dart';

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
    _nameController =
        TextEditingController(text: widget.data['name']);
    _rollNoController =
        TextEditingController(text: widget.data['rollNo']);
    _cnicController =
        TextEditingController(text: widget.data['cnic'] ?? '');
    _newPasswordController = TextEditingController();
    _selectedDepartment = widget.data['department'] ??
        'Computer Science';
  }

  // ✅ UPDATED: Improved retry embedding function with better feedback
  Future<void> _retryEmbedding(Map<String, dynamic> studentData) async {
    final photoUrls = List<String>.from(studentData['photoUrls'] ?? []);
    
    if (photoUrls.isEmpty) {
      _showSnack('Koi photos nahi hain! Pehle photos add karo.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    _showSnack('🧠 Generating embedding...', Colors.purple);

    final embeddingService = EmbeddingService();
    final result = await embeddingService.generateAndSaveEmbedding(
      studentUid: widget.uid,
      photoUrls: photoUrls,
      onProgress: (msg) => _showSnack(msg, Colors.purple),
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      _showSnack(
        '✅ Embedding generated! ${result['validPhotos']}/${result['totalPhotos']} photos used.',
        Colors.green,
      );
    } else {
      _showSnack('❌ ${result['message']}', Colors.red);
    }
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty ||
        _rollNoController.text.isEmpty) {
      _showSnack('Name aur Roll No fill karo!', Colors.red);
      return;
    }

    if (_cnicController.text.isNotEmpty &&
        _cnicController.text.length != 13) {
      _showSnack('CNIC exactly 13 digits honi chahiye!', Colors.red);
      return;
    }

    if (_changePassword &&
        _newPasswordController.text.length < 6) {
      _showSnack('Password kam az kam 6 characters!', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = FirebaseFirestore.instance;

      // Update students collection
      await db.collection('students').doc(widget.uid).update({
        'name': _nameController.text.trim(),
        'rollNo': _rollNoController.text.trim(),
        'cnic': _cnicController.text.trim(),
        'department': _selectedDepartment,
      });

      // Update users collection
      await db.collection('users').doc(widget.uid).update({
        'name': _nameController.text.trim(),
        'rollNo': _rollNoController.text.trim(),
        'department': _selectedDepartment,
      });

      // Update enrollments studentName
      final enrollments = await db
          .collection('enrollments')
          .where('studentId', isEqualTo: widget.uid)
          .get();
      for (var doc in enrollments.docs) {
        await doc.reference.update({
          'studentName': _nameController.text.trim()
        });
      }

      // Password change
      if (_changePassword &&
          _newPasswordController.text.isNotEmpty) {
        // Note: Firebase Admin SDK needed for this
        // Workaround: User khud change kar sakta hai
        _showSnack(
          'Info updated! Password change ke liye student apne account se reset kare.',
          Colors.orange,
        );
      } else {
        _showSnack('Student updated successfully! ✅', Colors.green);
      }

      setState(() => _isLoading = false);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error: $e', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: color,
          duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('Edit Student'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.3),
                    radius: 24,
                    child: Text(
                      widget.data['name'][0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.data['name'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text(widget.data['email'],
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Embedding Status Widget
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .doc(widget.uid)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox();
                final data = snap.data!.data() as Map<String, dynamic>;
                final status = data['embeddingStatus'] ?? 'unknown';
                final validPhotos = data['validPhotos'] ?? 0;

                Color statusColor = Colors.orange;
                String statusText = 'Pending';
                if (status == 'complete') {
                  statusColor = Colors.green;
                  statusText = 'Complete ($validPhotos photos)';
                } else if (status == 'failed') {
                  statusColor = Colors.red;
                  statusText = 'Failed — Retry needed';
                } else if (status == 'processing') {
                  statusColor = Colors.purple;
                  statusText = 'Processing...';
                }

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            status == 'complete'
                                ? Icons.check_circle
                                : status == 'processing'
                                    ? Icons.hourglass_top
                                    : Icons.warning,
                            color: statusColor,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Face Embedding Status',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                Text(statusText,
                                    style: TextStyle(
                                        color: statusColor, fontSize: 12)),
                              ],
                            ),
                          ),
                          // ✅ UPDATED: Retry button calls the improved function
                          if (status != 'complete' && status != 'processing')
                            ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _retryEmbedding(data),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Retry',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            const Text('Edit Information',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _buildField(_nameController, 'Full Name', Icons.person),
            _buildField(
                _rollNoController, 'Roll Number', Icons.badge),

            // CNIC
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _cnicController,
                keyboardType: TextInputType.number,
                maxLength: 13,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'CNIC (13 digits)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.credit_card,
                      color: Colors.blue),
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
            ),

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
                      color: Colors.blue),
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

            const SizedBox(height: 20),

            // Password Reset Note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.orange, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Password reset ke liye: Firebase Console → Authentication → User → Reset Password Email bhejo.',
                      style: TextStyle(
                          color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Text('Save Changes',
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

  Widget _buildField(
      TextEditingController controller, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.blue),
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