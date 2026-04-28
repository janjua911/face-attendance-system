import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/embedding_service.dart';

class FixEmbeddingsScreen extends StatefulWidget {
  const FixEmbeddingsScreen({super.key});

  @override
  State<FixEmbeddingsScreen> createState() =>
      _FixEmbeddingsScreenState();
}

class _FixEmbeddingsScreenState extends State<FixEmbeddingsScreen> {
  bool _isProcessing = false;
  String _currentStatus = '';
  List<Map<String, dynamic>> _studentStatuses = [];
  bool _loaded = false;

  final EmbeddingService _embeddingService = EmbeddingService();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('students')
        .get();

    List<Map<String, dynamic>> statuses = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final embedding = data['faceEmbedding'] as List? ?? [];
      final status = data['embeddingStatus'] ?? 'unknown';
      statuses.add({
        'uid': data['uid'],
        'name': data['name'],
        'photoUrls': data['photoUrls'] ?? [],
        'embeddingStatus': status,
        'embeddingSize': embedding.length,
        'validPhotos': data['validPhotos'] ?? 0,
      });
    }

    setState(() {
      _studentStatuses = statuses;
      _loaded = true;
    });
  }

  Future<void> _fixSingleStudent(Map<String, dynamic> student) async {
    final photoUrls = List<String>.from(student['photoUrls']);

    if (photoUrls.isEmpty) {
      _showSnack('${student['name']} ki koi photos nahi!', Colors.red);
      return;
    }

    setState(() {
      _isProcessing = true;
      _currentStatus =
          '🔄 Processing ${student['name']}...';
    });

    final result = await _embeddingService.generateAndSaveEmbedding(
      studentUid: student['uid'],
      photoUrls: photoUrls,
      onProgress: (msg) =>
          setState(() => _currentStatus = msg),
    );

    setState(() => _isProcessing = false);

    if (result['success']) {
      _showSnack(
        '✅ ${student['name']} — Done! ${result['validPhotos']}/${result['totalPhotos']} photos',
        Colors.green,
      );
    } else {
      _showSnack(
        '❌ ${student['name']} — Failed: ${result['message']}',
        Colors.red,
      );
    }

    await _loadStudents();
  }

  Future<void> _fixAllPending() async {
    final pending = _studentStatuses
        .where((s) =>
            s['embeddingStatus'] != 'complete' ||
            s['embeddingSize'] != 512)
        .toList();

    if (pending.isEmpty) {
      _showSnack('✅ Sab students ke embeddings already complete hain!',
          Colors.green);
      return;
    }

    setState(() {
      _isProcessing = true;
      _currentStatus = 'Starting...';
    });

    int success = 0;
    int failed = 0;

    for (var student in pending) {
      final photoUrls = List<String>.from(student['photoUrls']);
      if (photoUrls.isEmpty) {
        failed++;
        continue;
      }

      setState(() =>
          _currentStatus = '🔄 Processing: ${student['name']}');

      final result =
          await _embeddingService.generateAndSaveEmbedding(
        studentUid: student['uid'],
        photoUrls: photoUrls,
        onProgress: (msg) =>
            setState(() => _currentStatus = msg),
      );

      if (result['success']) {
        success++;
      } else {
        failed++;
      }
    }

    setState(() {
      _isProcessing = false;
      _currentStatus = '✅ Done! Success: $success, Failed: $failed';
    });

    _showSnack(
        '✅ Complete! $success success, $failed failed', Colors.green);
    await _loadStudents();
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
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        title: const Text('Fix Embeddings'),
      ),
      body: Column(
        children: [
          // Status Card
          if (_isProcessing)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.purple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.purple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_currentStatus,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                  ),
                ],
              ),
            ),

          // Fix All Button
          if (!_isProcessing && _loaded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _fixAllPending,
                  icon: const Icon(Icons.auto_fix_high,
                      color: Colors.white),
                  label: const Text('Fix All Pending Embeddings',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Students List
          Expanded(
            child: !_loaded
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Colors.purple))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _studentStatuses.length,
                    itemBuilder: (ctx, i) {
                      final student = _studentStatuses[i];
                      final status =
                          student['embeddingStatus'];
                      final size = student['embeddingSize'];
                      final isComplete =
                          status == 'complete' && size == 512;

                      Color statusColor = isComplete
                          ? Colors.green
                          : status == 'failed'
                              ? Colors.red
                              : Colors.orange;

                      String statusText = isComplete
                          ? '✅ Complete (${student['validPhotos']} photos)'
                          : status == 'failed'
                              ? '❌ Failed'
                              : '⏳ Pending';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: statusColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  statusColor.withOpacity(0.2),
                              child: Text(
                                student['name'][0].toUpperCase(),
                                style:
                                    TextStyle(color: statusColor),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(student['name'],
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight:
                                              FontWeight.bold)),
                                  Text(statusText,
                                      style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12)),
                                  Text(
                                    '${(student['photoUrls'] as List).length} photos available',
                                    style: const TextStyle(
                                        color: Colors.white24,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            if (!isComplete && !_isProcessing)
                              ElevatedButton(
                                onPressed: () =>
                                    _fixSingleStudent(student),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                ),
                                child: const Text('Fix',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12)),
                              ),
                            if (isComplete)
                              Icon(Icons.check_circle,
                                  color: Colors.green, size: 28),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}