import 'package:flutter/material.dart';
import 'add_student.dart';
import 'add_teacher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'course_management.dart';
import 'pending_registrations.dart';  // Make sure this exists
import 'all_students.dart';
import 'all_attendance.dart';
import 'teacher_management.dart';
import 'fix_embeddings.dart';  // Make sure this exists

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

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: _buildGradientAppBar(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildSectionHeader('Quick Actions', Icons.dashboard),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.9,
                children: [
                  MenuCard(
                    icon: Icons.person_add_alt_1,
                    title: 'Add Student',
                    subtitle: 'Register new student',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A00E0), Color(0xFF6C63FF)],
                    ),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AddStudentScreen()));
                    },
                  ),
                  MenuCard(
                    icon: Icons.school,
                    title: 'Add Teacher',
                    subtitle: 'Register new teacher',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                    ),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const TeacherManagementScreen()));
                    },
                  ),
                  MenuCard(
                    icon: Icons.book,
                    title: 'Manage Courses',
                    subtitle: 'Create & assign courses',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
                    ),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CourseManagementScreen()));
                    },
                  ),
                  MenuCard(
                    icon: Icons.how_to_reg,
                    title: 'Registrations',
                    subtitle: 'Approve student requests',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9D4EDD), Color(0xFFC77DFF)],
                    ),
                    onTap: () {
                      Navigator.push(context,
                           MaterialPageRoute(builder: (_) => const PendingRegistrationsScreen()));
                    },
                  ),
                  MenuCard(
                    icon: Icons.people,
                    title: 'All Students',
                    subtitle: 'View student list',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    ),
                    onTap: () {
                      Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const AllStudentsScreen()));
                    },
                  ),
                  MenuCard(
                    icon: Icons.psychology,
                    title: 'Fix Embeddings',
                    subtitle: 'Generate missing embeddings',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
                    ),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const FixEmbeddingsScreen())),
                  ),
                  MenuCard(
                    icon: Icons.bar_chart,
                    title: 'Attendance',
                    subtitle: 'View all records',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFFF6B6B)],
                    ),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AllAttendanceScreen()));
                    },
                  ),
                  MenuCard(
                    icon: Icons.settings,
                    title: 'Settings',
                    subtitle: 'System preferences',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF546E7A), Color(0xFF78909C)],
                    ),
                    onTap: () {
                      _showComingSoon(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildGradientAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Admin Panel',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppTheme.textPrimary,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          ),
        ),
      ],
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

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: AppTheme.textPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, Admin',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage your university system',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.smart_toy, size: 14, color: AppTheme.accentLight),
                      SizedBox(width: 6),
                      Text(
                        'AI-Powered Management',
                        style: TextStyle(
                          color: AppTheme.accentLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryPurple, AppTheme.accentCyan],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.textPrimary, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryPurple, Colors.transparent],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.build, color: AppTheme.textPrimary, size: 20),
            SizedBox(width: 12),
            Text('Coming soon! More features on the way.'),
          ],
        ),
        backgroundColor: AppTheme.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Modern Menu Card with gradient and animation
class MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: gradient.colors.first.withOpacity(0.2),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.colors.first.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}