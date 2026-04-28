import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTeacherScreen extends StatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _employeeIdController = TextEditingController();
  String _selectedDepartment = 'Computer Science';
  bool _isLoading = false;

  final List<String> _departments = [
    'Computer Science',
    'Software Engineering',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Business Administration',
    'Mathematics',
  ];

  Future<void> _saveTeacher() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _employeeIdController.text.isEmpty) {
      _showSnack('Sab fields fill karo!', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create Firebase Auth account
      UserCredential cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = cred.user!.uid;
      final db = FirebaseFirestore.instance;

      // Save to users collection
      await db.collection('users').doc(uid).set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'teacher',
        'department': _selectedDepartment,
        'createdAt': Timestamp.now(),
      });

      // Save to teachers collection
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
      _showSnack('Teacher registered successfully! ✅', Colors.green);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
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
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: const Text('Add New Teacher'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person, color: Colors.teal, size: 32),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Teacher Registration',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text('Fill all details carefully',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildField(_nameController, 'Full Name', Icons.person),
            _buildField(
                _employeeIdController, 'Employee ID', Icons.badge),
            _buildField(_emailController, 'Email', Icons.email,
                keyboardType: TextInputType.emailAddress),
            _buildField(_passwordController, 'Password', Icons.lock,
                isPassword: true),

            const SizedBox(height: 8),

            // Department Dropdown
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

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTeacher,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Register Teacher',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
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