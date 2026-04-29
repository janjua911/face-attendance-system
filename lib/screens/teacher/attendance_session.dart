import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'face_scan_screen.dart';

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

class AttendanceSessionScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const AttendanceSessionScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<AttendanceSessionScreen> createState() => _AttendanceSessionScreenState();
}

class _AttendanceSessionScreenState extends State<AttendanceSessionScreen> {
  String? _sessionId;
  bool _sessionStarted = false;
  bool _isLoading = false;
  final Map<String, String> _markedStudents = {};

  Future<void> _startSession() async {
    setState(() => _isLoading = true);
    final db = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docRef = db.collection('sessions').doc();

    await docRef.set({
      'sessionId': docRef.id,
      'courseId': widget.courseId,
      'teacherId': uid,
      'date': DateTime.now().toIso8601String().split('T')[0],
      'startTime': Timestamp.now(),
      'endTime': null,
      'status': 'active',
    });

    setState(() {
      _sessionId = docRef.id;
      _sessionStarted = true;
      _isLoading = false;
    });
    _showSnack('Session started successfully!', AppTheme.success);
  }

  Future<void> _openFaceScan() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('enrollments')
        .where('courseId', isEqualTo: widget.courseId)
        .where('status', isEqualTo: 'approved')
        .get();

    Map<String, String> enrolledStudents = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      enrolledStudents[data['studentId']] = data['studentName'];
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FaceScanScreen(
          sessionId: _sessionId!,
          courseId: widget.courseId,
          enrolledStudents: enrolledStudents,
        ),
      ),
    );

    await _refreshMarkedStudents();
  }

  Future<void> _refreshMarkedStudents() async {
    if (_sessionId == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('sessionId', isEqualTo: _sessionId)
        .get();

    Map<String, String> marked = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      marked[data['studentId']] = data['method'];
    }
    setState(() {
      _markedStudents.clear();
      _markedStudents.addAll(marked);
    });
  }

  Future<bool> _verifyTeacherPin() async {
    String enteredPin = '';
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.lock, color: AppTheme.warning),
            SizedBox(width: 8),
            Text('Teacher PIN', style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Manual attendance requires teacher verification.',
              style: TextStyle(color: AppTheme.textHint, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter 4-digit PIN (1234)',
                hintStyle: const TextStyle(color: AppTheme.textHint),
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterStyle: const TextStyle(color: AppTheme.textHint),
              ),
              onChanged: (val) => enteredPin = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textHint)),
          ),
          ElevatedButton(
            onPressed: () {
              if (enteredPin == '1234') {
                Navigator.pop(ctx, true);
              } else {
                Navigator.pop(ctx, false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Verify', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showManualAttendance() async {
    bool verified = await _verifyTeacherPin();
    if (!verified) {
      _showSnack('Wrong PIN! Only teacher can mark manually.', AppTheme.error);
      return;
    }

    await _refreshMarkedStudents();

    final snapshot = await FirebaseFirestore.instance
        .collection('enrollments')
        .where('courseId', isEqualTo: widget.courseId)
        .where('status', isEqualTo: 'approved')
        .get();

    List<Map<String, dynamic>> unmarkedStudents = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final uid = data['studentId'];
      if (!_markedStudents.containsKey(uid)) {
        unmarkedStudents.add({
          'uid': uid,
          'name': data['studentName'],
        });
      }
    }

    if (!mounted) return;

    if (unmarkedStudents.isEmpty) {
      _showSnack('All students have been marked already!', AppTheme.success);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.how_to_reg, color: AppTheme.warning),
                  SizedBox(width: 12),
                  Text(
                    'Manual Attendance',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${unmarkedStudents.length} students waiting for marking',
                style: const TextStyle(color: AppTheme.textHint),
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: unmarkedStudents.length,
                itemBuilder: (ctx, i) {
                  final student = unmarkedStudents[i];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.warning.withOpacity(0.2),
                          child: Text(
                            student['name'][0].toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            student['name'],
                            style: const TextStyle(color: AppTheme.textPrimary),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _markManual(student['uid'], student['name']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Present',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _markManual(String studentId, String studentName) async {
    if (_sessionId == null) return;

    if (_markedStudents.containsKey(studentId)) {
      _showSnack('$studentName already marked!', AppTheme.warning);
      return;
    }

    final db = FirebaseFirestore.instance;
    final docRef = db.collection('attendance').doc();

    await docRef.set({
      'attendanceId': docRef.id,
      'sessionId': _sessionId,
      'courseId': widget.courseId,
      'studentId': studentId,
      'studentName': studentName,
      'status': 'present',
      'markedAt': Timestamp.now(),
      'method': 'manual',
    });

    setState(() => _markedStudents[studentId] = 'manual');
    _showSnack('$studentName — Manually marked Present', AppTheme.success);
  }

  Future<void> _endSession() async {
    if (_sessionId == null) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_rounded, color: AppTheme.error),
            SizedBox(width: 8),
            Text('End Session?', style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: const Text(
          'Remaining students will be marked ABSENT automatically.',
          style: TextStyle(color: AppTheme.textHint),
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
            child: const Text('End Session', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final db = FirebaseFirestore.instance;

    final enrollments = await db
        .collection('enrollments')
        .where('courseId', isEqualTo: widget.courseId)
        .where('status', isEqualTo: 'approved')
        .get();

    for (var doc in enrollments.docs) {
      final data = doc.data();
      final studentId = data['studentId'];

      if (!_markedStudents.containsKey(studentId)) {
        final docRef = db.collection('attendance').doc();
        await docRef.set({
          'attendanceId': docRef.id,
          'sessionId': _sessionId,
          'courseId': widget.courseId,
          'studentId': studentId,
          'studentName': data['studentName'],
          'status': 'absent',
          'markedAt': Timestamp.now(),
          'method': 'auto',
        });
      }
    }

    await db.collection('sessions').doc(_sessionId).update({
      'endTime': Timestamp.now(),
      'status': 'closed',
    });

    setState(() => _isLoading = false);
    _showSnack('Session ended successfully!', AppTheme.success);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.pop(context);
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: _buildGradientAppBar(),
      body: Column(
        children: [
          _buildSessionStatusCard(),
          Expanded(child: _buildStudentList()),
          _buildActionButtons(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildGradientAppBar() {
    return AppBar(
      title: Text(
        widget.courseName,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
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

  Widget _buildSessionStatusCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _sessionStarted ? AppTheme.success.withOpacity(0.3) : AppTheme.textHint.withOpacity(0.2),
        ),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _sessionStarted ? AppTheme.success.withOpacity(0.15) : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _sessionStarted ? Icons.radio_button_checked : Icons.radio_button_off,
              color: _sessionStarted ? AppTheme.success : AppTheme.textHint,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sessionStarted ? 'Session Active' : 'No Active Session',
                  style: TextStyle(
                    color: _sessionStarted ? AppTheme.success : AppTheme.textHint,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _sessionStarted ? '${_markedStudents.length} students marked' : 'Start a session to take attendance',
                  style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('enrollments')
          .where('courseId', isEqualTo: widget.courseId)
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 48, color: AppTheme.textHint),
                SizedBox(height: 12),
                Text('No enrolled students', style: TextStyle(color: AppTheme.textHint)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (ctx, i) {
            final data = snapshot.data!.docs[i].data() as Map<String, dynamic>;
            final studentId = data['studentId'];
            final studentName = data['studentName'];
            final method = _markedStudents[studentId];
            final isMarked = method != null;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isMarked ? AppTheme.success.withOpacity(0.3) : AppTheme.textHint.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isMarked ? AppTheme.success : AppTheme.textHint,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: isMarked ? AppTheme.success.withOpacity(0.2) : AppTheme.surfaceLight,
                      child: Text(
                        studentName[0].toUpperCase(),
                        style: TextStyle(
                          color: isMarked ? AppTheme.success : AppTheme.textHint,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      studentName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (isMarked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: method == 'face' 
                            ? AppTheme.info.withOpacity(0.2) 
                            : AppTheme.warning.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            method == 'face' ? Icons.face : Icons.edit,
                            size: 14,
                            color: method == 'face' ? AppTheme.info : AppTheme.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            method == 'face' ? 'Face' : 'Manual',
                            style: TextStyle(
                              color: method == 'face' ? AppTheme.info : AppTheme.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Icon(Icons.pending, color: AppTheme.textHint, size: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButtons() {
    if (!_sessionStarted) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _startSession,
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Start Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openFaceScan,
                  icon: const Icon(Icons.face, color: Colors.white),
                  label: const Text('Face Scan', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.info,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showManualAttendance,
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text('Manual', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warning,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _endSession,
              icon: const Icon(Icons.stop, color: Colors.white),
              label: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('End Session', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}