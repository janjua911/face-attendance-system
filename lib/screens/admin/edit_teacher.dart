import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTeacherScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> data;

  const EditTeacherScreen({
    super.key,
    required this.uid,
    required this.data,
  });

  @override
  State<EditTeacherScreen> createState() => _EditTeacherScreenState();
}

class _EditTeacherScreenState extends State<EditTeacherScreen> {
  late TextEditingController _nameController;
  late TextEditingController _employeeIdController;
  late String _selectedDepartment;
  bool _isLoading = false;

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
    _employeeIdController =
        TextEditingController(text: widget.data['employeeId']);
    _selectedDepartment =
        widget.data['department'] ?? 'Computer Science';
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty ||
        _employeeIdController.text.isEmpty) {
      _showSnack('Sab fields fill karo!', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = FirebaseFirestore.instance;

      await db.collection('teachers').doc(widget.uid).update({
        'name': _nameController.text.trim(),
        'employeeId': _employeeIdController.text.trim(),
        'department': _selectedDepartment,
      });

      await db.collection('users').doc(widget.uid).update({
        'name': _nameController.text.trim(),
        'department': _selectedDepartment,
      });

      // Update course teacherName
      final courses = await db
          .collection('courses')
          .where('teacherId', isEqualTo: widget.uid)
          .get();
      for (var doc in courses.docs) {
        await doc.reference
            .update({'teacherName': _nameController.text.trim()});
      }

      setState(() => _isLoading = false);
      _showSnack('Teacher updated successfully! ✅', Colors.green);
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
          duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: const Text('Edit Teacher'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teacher Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.teal.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Colors.teal.withOpacity(0.3),
                    radius: 24,
                    child: Text(
                      widget.data['name'][0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.teal,
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
                              color: Colors.white38,
                              fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Edit Information',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _buildField(_nameController, 'Full Name', Icons.person),
            _buildField(_employeeIdController, 'Employee ID',
                Icons.badge),

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
                  icon: const Icon(Icons.arrow_drop_down,
                      color: Colors.teal),
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

            const SizedBox(height: 16),

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
                      'Password reset: Firebase Console → Authentication → User → Reset Password.',
                      style: TextStyle(
                          color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
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
          prefixIcon: Icon(icon, color: Colors.teal),
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