import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String _customBaseUrl = '';

  String get baseUrl {
    if (_customBaseUrl.isNotEmpty) return _customBaseUrl;
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8080';
      }
    } catch (e) {
      // Platform check will fail on web
    }
    return 'http://localhost:8080';
  }

  void setCustomBaseUrl(String url) {
    _customBaseUrl = url;
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<http.Response> get(String path) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();
    return http.get(url, headers: headers);
  }

  Future<http.Response> post(String path, dynamic body) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();
    return http.post(url, headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> put(String path, dynamic body) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();
    return http.put(url, headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> delete(String path) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();
    return http.delete(url, headers: headers);
  }

  // Multipart request for image uploading
  Future<String?> uploadImage(String path, File imageFile) async {
    final url = Uri.parse('$baseUrl$path');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final request = http.MultipartRequest('POST', url);
    if (token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final multipartFile = await http.MultipartFile.fromPath('file', imageFile.path);
    request.files.add(multipartFile);

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url']; // Returns the server upload path or Cloudinary URL
      }
    } catch (e) {
      // Log upload error
    }
    return null;
  }
}
