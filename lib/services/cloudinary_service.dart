import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Cloudinary credentials configuration
  static const String cloudName = "t3pfmxtw";
  static const String uploadPreset = "livestock_preset";

  /// Uploads an image file to Cloudinary and returns the secure URL
  static Future<String?> uploadImage(File imageFile) async {
    return await uploadMedia(imageFile);
  }

  /// Uploads a video file to Cloudinary and returns the secure URL
  static Future<String?> uploadVideo(File videoFile) async {
    return await uploadMedia(videoFile);
  }

  /// Generic media uploader supporting both images and videos
  static Future<String?> uploadMedia(File mediaFile) async {
    try {
      // Cloudinary's unified upload endpoint handles images, videos, and raw files automatically[cite: 8]
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/auto/upload");

      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', mediaFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonMap = jsonDecode(responseData);

        // Return the secure secure_url string from Cloudinary[cite: 8]
        return jsonMap['secure_url'] as String;
      } else {
        print("Cloudinary Media Upload Failed with status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Cloudinary Media Upload Error: $e");
      return null;
    }
  }
}