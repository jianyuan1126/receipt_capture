import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String apiUrl = 'https://www.singaporersvp.com/receipt/ask.php';
  static const String cloudName = 'dzlbskq1i';
  static const String uploadPreset = 'receipt_preset';
  
  static Future<String> submitImage(File imageFile) async {
    try {
      debugPrint('Attempting to upload file: ${imageFile.path}');
      debugPrint('File exists: ${await imageFile.exists()}');
      debugPrint('File size: ${await imageFile.length()} bytes');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );

      // Add file as multipart
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // Add upload preset
      request.fields['upload_preset'] = uploadPreset;

      // Send request
      debugPrint('Sending request to Cloudinary...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('Cloudinary Response Status: ${response.statusCode}');
      debugPrint('Cloudinary Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final imageUrl = responseData['secure_url'];
        debugPrint('Step 1: Image uploaded to Cloudinary: $imageUrl');
        
        // Call API with Cloudinary URL
        final apiFullUrl = '$apiUrl?url=$imageUrl';
        debugPrint('Step 2: Full API URL: $apiFullUrl');
        
        final apiResponse = await http.get(Uri.parse(apiFullUrl));
        debugPrint('Step 3: API Response Status: ${apiResponse.statusCode}');
        debugPrint('Step 3: API Response Body: ${apiResponse.body}');
        
        return apiResponse.body;
      } else {
        debugPrint('Cloudinary Error: ${response.body}');
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error in submitImage: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Error uploading image: $e');
    }
  }
} 