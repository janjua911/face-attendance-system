import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'face_scan_screen.dart';

class AttendanceSessionScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const AttendanceSessionScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<AttendanceSessionScreen> createState() =>
      _AttendanceSessionScreenState();
}

class _AttendanceSessionScreenState
    extends State<AttendanceSessionScreen> {
  String? _sessionId;
  bool _sessionStarted = false;
  bool _isLoading = false;
  final Map<String, String> _markedStudents = {}; // uid → method

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
    _showSnack('Session started! ✅', Colors.green);
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

    // Refresh marked students after face scan
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
    setState(() => _markedStudents.clear());
    setState(() => _markedStudents.addAll(marked));
  }

  // Teacher PIN verify karo before manual
  Future<bool> _verifyTeacherPin() async {
    String enteredPin = '';
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.orange),
            SizedBox(width: 8),
            Text('Teacher PIN',
                style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Manual attendance sirf teacher kar sakta hai.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter 4-digit PIN (1234)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                counterStyle:
                    const TextStyle(color: Colors.white38),
              ),
              onChanged: (val) => enteredPin = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
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
                backgroundColor: Colors.orange),
            child: const Text('Verify',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Manual attendance dialog
  Future<void> _showManualAttendance() async {
    // PIN verify karo pehle
    bool verified = await _verifyTeacherPin();
    if (!verified) {
      _showSnack('❌ Wrong PIN! Only teacher can do manual.', Colors.red);
      return;
    }

    // Refresh marked students
    await _refreshMarkedStudents();

    // Enrolled students fetch karo
    final snapshot = await FirebaseFirestore.instance
        .collection('enrollments')
        .where('courseId', isEqualTo: widget.courseId)
        .where('status', isEqualTo: 'approved')
        .get();

    // Sirf UNMARKED students dikho
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
      _showSnack('✅ Sab students already marked hain!', Colors.green);
      return;
    }

    // Manual attendance dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Row(
          children: [
            Icon(Icons.how_to_reg, color: Colors.orange),
            SizedBox(width: 8),
            Text('Manual Attendance',
                style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${unmarkedStudents.length} unmarked students:',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: unmarkedStudents.length,
                  itemBuilder: (ctx, i) {
                    final student = unmarkedStudents[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                Colors.orange.withOpacity(0.2),
                            child: Text(
                              student['name'][0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(student['name'],
                                style: const TextStyle(
                                    color: Colors.white)),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _markManual(
                                  student['uid'], student['name']);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(6)),
                            ),
                            child: const Text('Present',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close',
                style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }

  Future<void> _markManual(String studentId, String studentName) async {
    if (_sessionId == null) return;

    // Double mark check
    if (_markedStudents.containsKey(studentId)) {
      _showSnack('$studentName already marked!', Colors.orange);
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
    _showSnack('✅ $studentName — Manually marked Present', Colors.green);
  }

  Future<void> _endSession() async {
    if (_sessionId == null) return;

    // Confirm dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('End Session?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Remaining students will be marked ABSENT automatically.',
          style: TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Session',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final db = FirebaseFirestore.instance;

    // All enrolled students
    final enrollments = await db
        .collection('enrollments')
        .where('courseId', isEqualTo: widget.courseId)
        .where('status', isEqualTo: 'approved')
        .get();

    // Mark remaining as absent
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

    // Close session
    await db.collection('sessions').doc(_sessionId).update({
      'endTime': Timestamp.now(),
      'status': 'closed',
    });

    setState(() => _isLoading = false);
    _showSnack('Session ended! ✅', Colors.teal);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.pop(context);
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
        title: Text(widget.courseName),
      ),
      body: Column(
        children: [
          // Session Status
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _sessionStarted
                  ? Colors.green.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _sessionStarted
                    ? Colors.green.withOpacity(0.4)
                    : Colors.white12,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _sessionStarted
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: _sessionStarted
                      ? Colors.green
                      : Colors.white38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _sessionStarted
                        ? 'Session Active — ${_markedStudents.length} marked'
                        : 'Session not started yet',
                    style: TextStyle(
                      color: _sessionStarted
                          ? Colors.green
                          : Colors.white38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Students List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('enrollments')
                  .where('courseId', isEqualTo: widget.courseId)
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Koi student enrolled nahi',
                        style: TextStyle(color: Colors.white38)),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (ctx, i) {
                    final data = snapshot.data!.docs[i].data()
                        as Map<String, dynamic>;
                    final studentId = data['studentId'];
                    final studentName = data['studentName'];
                    final method = _markedStudents[studentId];
                    final isMarked = method != null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isMarked
                            ? Colors.green.withOpacity(0.1)
                            : const Color(0xFF16213E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isMarked
                              ? Colors.green.withOpacity(0.3)
                              : Colors.white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isMarked
                                ? Colors.green.withOpacity(0.2)
                                : Colors.teal.withOpacity(0.2),
                            child: Text(
                              studentName[0].toUpperCase(),
                              style: TextStyle(
                                color: isMarked
                                    ? Colors.green
                                    : Colors.teal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(studentName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                          if (isMarked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: method == 'face'
                                    ? Colors.blue.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(6),
                              ),
                              child: Text(
                                method == 'face'
                                    ? '🤖 Face'
                                    : '✋ Manual',
                                style: TextStyle(
                                  color: method == 'face'
                                      ? Colors.blue
                                      : Colors.orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            const Text('—',
                                style: TextStyle(
                                    color: Colors.white24)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Bottom Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: !_sessionStarted
                ? SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _startSession,
                      icon: const Icon(Icons.play_arrow,
                          color: Colors.white),
                      label: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text('Start Session',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          // Face Scan
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _openFaceScan,
                              icon: const Icon(Icons.face,
                                  color: Colors.white),
                              label: const Text('Face Scan',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Manual (PIN Protected)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showManualAttendance,
                              icon: const Icon(Icons.edit,
                                  color: Colors.white),
                              label: const Text('Manual 🔒',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // End Session
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isLoading ? null : _endSession,
                          icon: const Icon(Icons.stop,
                              color: Colors.white),
                          label: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('End Session',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}