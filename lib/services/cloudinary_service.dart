import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  static const String cloudName = 'dmspsohsu';
  static const String uploadPreset = 'pgjfgtbl';

  // Upload image bytes to Cloudinary
  Future<String?> uploadImage(Uint8List imageBytes, String fileName) async {
    try {
      var uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      var request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'face_attendance/students';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName,
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonData['secure_url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}