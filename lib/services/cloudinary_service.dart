import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Replace these with your Cloudinary credentials
  static const String cloudName = "t3pfmxtw";
  static const String uploadPreset = "livestock_preset";

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonMap = jsonDecode(responseData);

        // Return the secure URL string from Cloudinary
        return jsonMap['secure_url'] as String;
      } else {
        print("Cloudinary Upload Failed with status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Cloudinary Upload Error: $e");
      return null;
    }
  }
}