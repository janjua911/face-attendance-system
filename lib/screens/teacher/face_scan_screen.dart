import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/cloudinary_service.dart';
import '../../services/face_recognition_service.dart';

class FaceScanScreen extends StatefulWidget {
  final String sessionId;
  final String courseId;
  final Map<String, String> enrolledStudents; // uid → name

  const FaceScanScreen({
    super.key,
    required this.sessionId,
    required this.courseId,
    required this.enrolledStudents,
  });

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraReady = false;
  bool _isProcessing = false;
  String _statusMessage = 'Camera ready — Capture face';
  Color _statusColor = Colors.white;
  String? _lastIdentified;
  final Set<String> _markedInSession = {};

  final CloudinaryService _cloudinary = CloudinaryService();
  final FaceRecognitionService _faceService = FaceRecognitionService();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _statusMessage = 'No camera found!');
        return;
      }

      // Front camera prefer karo
      CameraDescription selectedCamera = _cameras.first;
      for (var cam in _cameras) {
        if (cam.lensDirection == CameraLensDirection.front) {
          selectedCamera = cam;
          break;
        }
      }

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraReady = true);
    } catch (e) {
      setState(() => _statusMessage = 'Camera error: $e');
    }
  }

  Future<void> _captureAndRecognize() async {
    if (_isProcessing || !_isCameraReady) return;
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = '📸 Capturing...';
      _statusColor = Colors.yellow;
    });

    try {
      // Photo capture karo
      final XFile photo = await _cameraController!.takePicture();
      final bytes = await photo.readAsBytes();

      setState(() => _statusMessage = '☁️ Uploading...');

      // Cloudinary pe upload karo
      final url = await _cloudinary.uploadImage(
        bytes,
        'scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (url == null) {
        setState(() {
          _statusMessage = '❌ Upload failed — Try again';
          _statusColor = Colors.red;
          _isProcessing = false;
        });
        return;
      }

      setState(() => _statusMessage = '🧠 Recognizing...');

      // Face recognize karo
      final result = await _faceService.recognizeFromUrl(url);

      if (!result['success']) {
        setState(() {
          _statusMessage = '❌ ${result['message']}';
          _statusColor = Colors.red;
          _isProcessing = false;
        });
        return;
      }

      if (!result['identified']) {
        setState(() {
          _statusMessage = '❓ Unknown Person — Try again';
          _statusColor = Colors.orange;
          _isProcessing = false;
        });
        return;
      }

      final String uid = result['uid'];
      final String name = result['name'];
      final double confidence = result['confidence'];

      // Check — is student enrolled in this course?
      if (!widget.enrolledStudents.containsKey(uid)) {
        setState(() {
          _statusMessage =
              '⚠️ $name — Not enrolled in this course!';
          _statusColor = Colors.orange;
          _isProcessing = false;
        });
        return;
      }

      // Check — already marked?
      if (_markedInSession.contains(uid)) {
        setState(() {
          _statusMessage =
              '⚠️ $name — Already marked present!';
          _statusColor = Colors.yellow;
          _isProcessing = false;
        });
        return;
      }

      // Mark attendance!
      final db = FirebaseFirestore.instance;
      final docRef = db.collection('attendance').doc();

      await docRef.set({
        'attendanceId': docRef.id,
        'sessionId': widget.sessionId,
        'courseId': widget.courseId,
        'studentId': uid,
        'studentName': name,
        'status': 'present',
        'markedAt': Timestamp.now(),
        'method': 'face',
        'confidence': confidence,
        'photoUrl': url,
      });

      _markedInSession.add(uid);

      setState(() {
        _lastIdentified = name;
        _statusMessage =
            '✅ $name — Present! (${(confidence * 100).toStringAsFixed(1)}%)';
        _statusColor = Colors.green;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
        _statusColor = Colors.red;
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Face Scan'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_markedInSession.length}/${widget.enrolledStudents.length} marked',
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Camera Preview
          Expanded(
            child: _isCameraReady
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: CameraPreview(_cameraController!),
                  )
                : const Center(
                    child: CircularProgressIndicator(
                        color: Colors.white)),
          ),

          // Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Column(
              children: [
                // Status Message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _statusColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isProcessing)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white),
                        ),
                      if (_isProcessing)
                        const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Capture Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isProcessing ? null : _captureAndRecognize,
                    icon: const Icon(Icons.camera_alt,
                        color: Colors.white),
                    label: const Text(
                      'Scan Face',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Done Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Done Scanning',
                        style: TextStyle(color: Colors.white54)),
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