import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  String _selectedDepartment = 'Computer Science';
  String _selectedSemester = 'Fall 2026';
  int _creditHours = 3;
  bool _isLoading = false;

  // Selected teacher
  String? _selectedTeacherId;
  String? _selectedTeacherName;

  final List<String> _departments = [
    'Computer Science',
    'Software Engineering',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Business Administration',
    'Mathematics',
  ];

  final List<String> _semesters = [
    'Spring 2026',
    'Fall 2026',
    'Spring 2027',
    'Fall 2027',
  ];

  Future<void> _saveCourse() async {
    if (_nameController.text.isEmpty || _codeController.text.isEmpty) {
      _showSnack('Course name aur code fill karo!', Colors.red);
      return;
    }
    if (_selectedTeacherId == null) {
      _showSnack('Pehle teacher select karo!', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = FirebaseFirestore.instance;
      final docRef = db.collection('courses').doc();

      await docRef.set({
        'courseId': docRef.id,
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim().toUpperCase(),
        'department': _selectedDepartment,
        'teacherId': _selectedTeacherId,
        'teacherName': _selectedTeacherName,
        'creditHours': _creditHours,
        'semester': _selectedSemester,
        'createdAt': Timestamp.now(),
      });

      // Add course to teacher's assignedCourses
      await db.collection('teachers').doc(_selectedTeacherId).update({
        'assignedCourses': FieldValue.arrayUnion([docRef.id]),
      });

      setState(() => _isLoading = false);
      _showSnack('Course created successfully! ✅', Colors.green);
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
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: const Text('Create New Course'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.book, color: Colors.orange, size: 32),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Course Details',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text('Fill course info and assign teacher',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Course Name
            _buildField(_nameController, 'Course Name', Icons.book),
            // Course Code
            _buildField(_codeController, 'Course Code (e.g. CS301)',
                Icons.code),

            // Department
            const SizedBox(height: 4),
            _buildDropdown(
              value: _selectedDepartment,
              items: _departments,
              icon: Icons.school,
              onChanged: (val) =>
                  setState(() => _selectedDepartment = val!),
            ),
            const SizedBox(height: 12),

            // Semester
            _buildDropdown(
              value: _selectedSemester,
              items: _semesters,
              icon: Icons.calendar_today,
              onChanged: (val) =>
                  setState(() => _selectedSemester = val!),
            ),
            const SizedBox(height: 12),

            // Credit Hours
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Text('Credit Hours',
                      style: TextStyle(color: Colors.white)),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      if (_creditHours > 1)
                        setState(() => _creditHours--);
                    },
                    icon: const Icon(Icons.remove_circle,
                        color: Colors.orange),
                  ),
                  Text('$_creditHours',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () {
                      if (_creditHours < 6)
                        setState(() => _creditHours++);
                    },
                    icon: const Icon(Icons.add_circle,
                        color: Colors.orange),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Assign Teacher Section
            const Text('Assign Teacher',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Teachers List from Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('teachers')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Colors.orange));
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Koi teacher registered nahi hai!\nPehle teacher add karo.',
                      style: TextStyle(color: Colors.white38),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final isSelected =
                        _selectedTeacherId == data['uid'];

                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedTeacherId = data['uid'];
                        _selectedTeacherName = data['name'];
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.orange.withOpacity(0.2)
                              : const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.orange
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  Colors.orange.withOpacity(0.2),
                              child: Text(
                                data['name'][0].toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.orange),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(data['name'],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight:
                                            FontWeight.bold)),
                                Text(data['department'],
                                    style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12)),
                              ],
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(Icons.check_circle,
                                  color: Colors.orange),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Text('Create Course',
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
          prefixIcon: Icon(icon, color: Colors.orange),
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

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                dropdownColor: const Color(0xFF16213E),
                style: const TextStyle(color: Colors.white),
                icon: const Icon(Icons.arrow_drop_down,
                    color: Colors.orange),
                isExpanded: true,
                items: items
                    .map((d) =>
                        DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}