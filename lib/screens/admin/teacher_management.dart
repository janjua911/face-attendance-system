import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_teacher.dart';
import 'edit_teacher.dart';

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
  
  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00897B), Color(0xFF26A69A)],
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

class TeacherManagementScreen extends StatelessWidget {
  const TeacherManagementScreen({super.key});

  Future<void> _deleteTeacher(BuildContext context, String uid, String name) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_rounded, color: AppTheme.error, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Delete Teacher?', style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "$name"?\nThis action cannot be undone!',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textHint)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final db = FirebaseFirestore.instance;
      await db.collection('teachers').doc(uid).delete();
      await db.collection('users').doc(uid).delete();

      if (context.mounted) {
        _showSnackBar(context, 'Teacher deleted successfully!', AppTheme.success);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Error: $e', AppTheme.error);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppTheme.success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
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
      floatingActionButton: _buildFloatingActionButton(context),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('teachers')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF26A69A)),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final teachers = snapshot.data!.docs;
          final totalCourses = teachers.fold<int>(0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            final assignedCourses = data['assignedCourses'] as List?;
            return sum + (assignedCourses?.length ?? 0);
          });

          return Column(
            children: [
              _buildStatsCard(teachers.length, totalCourses),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: teachers.length,
                  itemBuilder: (ctx, i) {
                    final data = teachers[i].data() as Map<String, dynamic>;
                    final uid = data['uid'];
                    return _buildTeacherCard(context, data, uid);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildGradientAppBar() {
    return AppBar(
      title: const Text(
        'Teacher Management',
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

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddTeacherScreen()),
      ),
      backgroundColor: const Color(0xFF26A69A),
      elevation: 4,
      icon: const Icon(Icons.add_rounded, color: AppTheme.textPrimary),
      label: const Text(
        'Add Teacher',
        style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  }

  Widget _buildStatsCard(int teacherCount, int totalCourses) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.person, 'Total Teachers', teacherCount.toString(), const Color(0xFF26A69A)),
          Container(width: 1, height: 40, color: AppTheme.surfaceLight),
          _buildStatItem(Icons.book, 'Assigned Courses', totalCourses.toString(), AppTheme.accentCyan),
          Container(width: 1, height: 40, color: AppTheme.surfaceLight),
          _buildStatItem(Icons.school, 'Departments', '--', AppTheme.primaryPurple),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textHint,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherCard(BuildContext context, Map<String, dynamic> data, String uid) {
    final assignedCourses = data['assignedCourses'] as List?;
    final courseCount = assignedCourses?.length ?? 0;
    final isActive = data['isActive'] != false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF26A69A).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditTeacherScreen(uid: uid, data: data),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Teacher Avatar with gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.tealGradient,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.transparent,
                    child: Text(
                      data['name'][0].toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                
                // Teacher Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              data['name'],
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Inactive',
                                style: TextStyle(
                                  color: AppTheme.error,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ID: ${data['employeeId']}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF26A69A).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              data['department'],
                              style: const TextStyle(
                                color: Color(0xFF26A69A),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.book_outlined, size: 12, color: AppTheme.textHint),
                          const SizedBox(width: 4),
                          Text(
                            '$courseCount courses assigned',
                            style: const TextStyle(
                              color: AppTheme.accentCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action Buttons
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditTeacherScreen(uid: uid, data: data),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                        tooltip: 'Edit',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => _deleteTeacher(context, uid, data['name']),
                        icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                        tooltip: 'Delete',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_add_alt_1,
              size: 64,
              color: Color(0xFF26A69A),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Teachers Found',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to add a new teacher',
            style: TextStyle(color: AppTheme.textHint, fontSize: 14),
          ),
        ],
      ),
    );
  }
}