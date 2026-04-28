import 'add_student.dart';
import 'add_teacher.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'course_management.dart';
import 'pending_registrations.dart';
import 'all_students.dart';
import 'all_attendance.dart';
import 'teacher_management.dart';
import 'fix_embeddings.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text('Admin Panel', 
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.indigo, Colors.indigoAccent],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, Admin 👑',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Manage your university system',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Quick Actions',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Menu Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _MenuCard(
                    icon: Icons.person_add,
                    title: 'Add Student',
                    subtitle: 'Register new student',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AddStudentScreen()));
                    },
                  ),
                  _MenuCard(
                    icon: Icons.person,
                    title: 'Add Teacher',
                    subtitle: 'Register new teacher',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const TeacherManagementScreen()));
                    },
                  ),
                  _MenuCard(
                    icon: Icons.book,
                    title: 'Manage Courses',
                    subtitle: 'Create & assign courses',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CourseManagementScreen()));
                    },
                  ),
                  _MenuCard(
                    icon: Icons.how_to_reg,
                    title: 'Registrations',
                    subtitle: 'Approve student requests',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(context,
                           MaterialPageRoute(builder: (_) => const PendingRegistrationsScreen()));
                    },
                  ),
                  _MenuCard(
                    icon: Icons.people,
                    title: 'All Students',
                    subtitle: 'View student list',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const AllStudentsScreen()));
                    },
                  ),
                  // ✅ ADDED: Fix Embeddings Card
                  _MenuCard(
                    icon: Icons.psychology,
                    title: 'Fix Embeddings',
                    subtitle: 'Generate missing embeddings',
                    color: Colors.purple,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const FixEmbeddingsScreen())),
                  ),
                  _MenuCard(
                    icon: Icons.bar_chart,
                    title: 'Attendance',
                    subtitle: 'View all records',
                    color: Colors.red,
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AllAttendanceScreen()));
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
} // AdminDashboard class end

// Yeh class honi chahiye file ke end mein:
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}