import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:mime/mime.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000"; // Emulator IP for localhost

  static Future<String> analyzeSoil(File image) async {
    var uri = Uri.parse("$baseUrl/analyze_soil");
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    var response = await request.send();
    return response.statusCode == 200
        ? await response.stream.bytesToString()
        : "Error analyzing soil.";
  }

  static Future<String> detectDisease(File image) async {
    var uri = Uri.parse("$baseUrl/detect_disease");
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    var response = await request.send();
    return response.statusCode == 200
        ? await response.stream.bytesToString()
        : "Error detecting disease.";
  }

  static Future<String> getWeather() async {
    var uri = Uri.parse("$baseUrl/weather");
    var response = await http.get(uri);
    return response.statusCode == 200 ? response.body : "Error fetching weather.";
  }
}
