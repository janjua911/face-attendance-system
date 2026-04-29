import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateCourseScreen extends StatefulWidget {
  final Map<String, dynamic>? courseData;
  final String? courseId;
  
  const CreateCourseScreen({super.key, this.courseData, this.courseId});

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
  bool _isEditMode = false;

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

  @override
  void initState() {
    super.initState();
    _checkEditMode();
  }

  void _checkEditMode() {
    if (widget.courseData != null && widget.courseId != null) {
      _isEditMode = true;
      _nameController.text = widget.courseData!['name'] ?? '';
      _codeController.text = widget.courseData!['code'] ?? '';
      _selectedDepartment = widget.courseData!['department'] ?? 'Computer Science';
      _selectedSemester = widget.courseData!['semester'] ?? 'Fall 2026';
      _creditHours = widget.courseData!['creditHours'] ?? 3;
      _selectedTeacherId = widget.courseData!['teacherId'];
      _selectedTeacherName = widget.courseData!['teacherName'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _saveCourse() async {
    if (_nameController.text.isEmpty || _codeController.text.isEmpty) {
      _showSnack('Please fill course name and code!', Colors.red);
      return;
    }
    if (_selectedTeacherId == null) {
      _showSnack('Please select a teacher first!', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = FirebaseFirestore.instance;
      
      if (_isEditMode && widget.courseId != null) {
        final oldTeacherId = widget.courseData!['teacherId'];
        
        await db.collection('courses').doc(widget.courseId).update({
          'name': _nameController.text.trim(),
          'code': _codeController.text.trim().toUpperCase(),
          'department': _selectedDepartment,
          'teacherId': _selectedTeacherId,
          'teacherName': _selectedTeacherName,
          'creditHours': _creditHours,
          'semester': _selectedSemester,
          'updatedAt': Timestamp.now(),
        });
        
        if (oldTeacherId != null && oldTeacherId != _selectedTeacherId) {
          await db.collection('teachers').doc(oldTeacherId).update({
            'assignedCourses': FieldValue.arrayRemove([widget.courseId]),
          });
        }
        
        if (_selectedTeacherId != oldTeacherId) {
          await db.collection('teachers').doc(_selectedTeacherId).update({
            'assignedCourses': FieldValue.arrayUnion([widget.courseId]),
          });
        }
        
        _showSnack('Course updated successfully! ✅', Colors.green);
      } else {
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

        await db.collection('teachers').doc(_selectedTeacherId).update({
          'assignedCourses': FieldValue.arrayUnion([docRef.id]),
        });
        
        _showSnack('Course created successfully! ✅', Colors.green);
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
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.error,
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
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Course' : 'Create New Course'),
        backgroundColor: const Color(0xFFFFA726),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA726).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.book, color: const Color(0xFFFFA726), size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditMode ? 'Edit Course' : 'Course Details',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _isEditMode ? 'Update course information' : 'Fill course info and assign teacher',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildField(_nameController, 'Course Name', Icons.book),
            _buildField(_codeController, 'Course Code (e.g., CS301)', Icons.code),
            
            _buildDropdown(
              value: _selectedDepartment,
              items: _departments,
              icon: Icons.school,
              label: 'Department',
              onChanged: (val) => setState(() => _selectedDepartment = val!),
            ),
            const SizedBox(height: 12),
            
            _buildDropdown(
              value: _selectedSemester,
              items: _semesters,
              icon: Icons.calendar_today,
              label: 'Semester',
              onChanged: (val) => setState(() => _selectedSemester = val!),
            ),
            const SizedBox(height: 12),
            
            _buildCreditHoursSelector(),
            const SizedBox(height: 24),
            
            const Text(
              'Assign Teacher',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('teachers').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFFA726)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'No teachers registered!\nPlease add a teacher first.',
                      style: TextStyle(color: Colors.white38),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final isSelected = _selectedTeacherId == data['uid'];

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
                              ? const Color(0xFFFFA726).withOpacity(0.2)
                              : const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFFA726) : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFFFA726).withOpacity(0.2),
                              child: Text(
                                data['name'][0].toUpperCase(),
                                style: const TextStyle(color: Color(0xFFFFA726)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'],
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    data['department'],
                                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: Color(0xFFFFA726)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA726),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isEditMode ? 'Update Course' : 'Create Course',
                        style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: const Color(0xFFFFA726)),
          filled: true,
          fillColor: const Color(0xFF1A1A2E),
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
    required String label,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFFFA726)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    dropdownColor: const Color(0xFF1A1A2E),
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFFA726)),
                    isExpanded: true,
                    items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreditHoursSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Credit Hours', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer, color: Color(0xFFFFA726)),
              const SizedBox(width: 12),
              const Text('Credit Hours', style: TextStyle(color: Colors.white)),
              const Spacer(),
              IconButton(
                onPressed: () {
                  if (_creditHours > 1) setState(() => _creditHours--);
                },
                icon: const Icon(Icons.remove_circle, color: Color(0xFFFFA726)),
              ),
              Text(
                '$_creditHours',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {
                  if (_creditHours < 6) setState(() => _creditHours++);
                },
                icon: const Icon(Icons.add_circle, color: Color(0xFFFFA726)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}