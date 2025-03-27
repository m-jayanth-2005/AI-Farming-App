import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:isolate';
import 'dart:async';

class ApiService {
  static String get baseUrl => dotenv.env['BACKEND_URL'] ?? "http://127.0.0.1:8001";

  // Singleton HTTP client to enable connection pooling
  static final http.Client _client = http.Client();

  // Dedicated isolate for API operations
  static Isolate? _apiIsolate;
  static SendPort? _apiSendPort;
  static final ReceivePort _receivePort = ReceivePort();
  static final Map<int, Completer<Map<String, dynamic>>> _pendingRequests = {};
  static int _requestId = 0;
  static final Completer<void> _isolateReady = Completer<void>();

  // Initialize the API isolate
  static Future<void> initialize() async {
    if (_apiIsolate != null) return;

    _receivePort.listen((message) {
      if (message is SendPort) {
        // Store the SendPort to communicate with the isolate
        _apiSendPort = message;
        _isolateReady.complete();
      } else if (message is Map<String, dynamic>) {
        // Handle response from isolate
        final requestId = message['requestId'] as int;
        final Completer<Map<String, dynamic>>? completer = _pendingRequests[requestId];
        if (completer != null) {
          if (message.containsKey('error')) {
            completer.completeError(Exception(message['error']));
          } else {
            completer.complete(message['data']);
          }
          _pendingRequests.remove(requestId);
        }
      }
    });

    // Create a persistent isolate
    _apiIsolate = await Isolate.spawn(
      _isolateEntryPoint,
      _receivePort.sendPort,
    );

    // Wait for isolate to be ready
    await _isolateReady.future;
  }

  // Clean up resources
  static void dispose() {
    _apiIsolate?.kill(priority: Isolate.immediate);
    _apiIsolate = null;
    _apiSendPort = null;
    _client.close();
    _receivePort.close();
    _pendingRequests.clear();
  }

  // Send request to isolate and get response
  static Future<Map<String, dynamic>> _sendRequest(
    String method,
    Map<String, dynamic> params,
  ) async {
    await initialize();

    final requestId = _requestId++;
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[requestId] = completer;

    _apiSendPort!.send({
      'requestId': requestId,
      'method': method,
      'params': params,
      'baseUrl': baseUrl,
    });

    return completer.future;
  }

  // Main isolate entry point that handles all API requests
  static void _isolateEntryPoint(SendPort sendPort) async {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    // Create a dedicated HTTP client for this isolate
    final client = http.Client();

    receivePort.listen((message) async {
      if (message is Map<String, dynamic>) {
        final requestId = message['requestId'] as int;
        final method = message['method'] as String;
        final params = message['params'] as Map<String, dynamic>;
        final baseUrl = message['baseUrl'] as String;

        try {
          Map<String, dynamic> result;

          switch (method) {
            case 'analyzeSoil':
              result = await _analyzeSoilTask(client, baseUrl, params);
              break;
            case 'detectPlantDisease':
              result = await _detectPlantDiseaseTask(client, baseUrl, params);
              break;
            case 'getWeather':
              result = await _getWeatherTask(client, baseUrl, params);
              break;
            case 'getRecommendation':
              result = await _getRecommendationTask(client, baseUrl, params);
              break;
            case 'chat':
              result = await _chatTask(client, baseUrl, params);
              break;
            default:
              throw Exception('Unknown method: $method');
          }

          sendPort.send({
            'requestId': requestId,
            'data': result,
          });
        } catch (e) {
          sendPort.send({
            'requestId': requestId,
            'error': e.toString(),
          });
        }
      }
    });
  }

  // API task implementations
  static Future<Map<String, dynamic>> _analyzeSoilTask(
    http.Client client, String baseUrl, Map<String, dynamic> params) async {
    final soilData = params['soilData'];

    try {
      final response = await client.post(
        Uri.parse('$baseUrl/predict-soil/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(soilData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Soil Analysis Failed: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception('Soil Analysis Error: $e');
    }
  }

  static Future<Map<String, dynamic>> _detectPlantDiseaseTask(
    http.Client client, String baseUrl, Map<String, dynamic> params) async {
    final filePath = params['filePath'];

    try {
      File file = File(filePath);
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/predict-disease/'));
      request.files.add(await http.MultipartFile.fromPath('image', file.path));

      var response = await request.send();
      var responseBody = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        return jsonDecode(responseBody.body);
      } else {
        throw Exception("Disease Detection Failed: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception('Disease Detection Error: $e');
    }
  }
  static Future<Map<String, dynamic>> detectPlantDiseaseBytes(Uint8List imageBytes) async {
    try {
      final url = Uri.parse('$baseUrl/disease-detection/');

      var request = http.MultipartRequest('POST', url);
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'image.jpg', // Provide a filename
      ));

      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);

      if (responseBody.statusCode == 200) {
        return jsonDecode(responseBody.body);
      } else {
        throw Exception('Disease Detection Failed: ${responseBody.statusCode}');
      }
    } catch (e) {
      throw Exception('Disease Detection Error: $e');
    }
  }

  static Future<Map<String, dynamic>> _getWeatherTask(
    http.Client client, String baseUrl, Map<String, dynamic> params) async {
    final latitude = params['latitude'];
    final longitude = params['longitude'];

    try {
      final response = await client.get(
        Uri.parse('$baseUrl/weather/?latitude=$latitude&longitude=$longitude'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Weather Fetch Failed: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception('Weather Fetch Error: $e');
    }
  }

  static Future<Map<String, dynamic>> _getRecommendationTask(
    http.Client client, String baseUrl, Map<String, dynamic> params) async {
    final soilData = params['soilData'];
    final disease = params['disease'];
    final weatherData = params['weatherData'];

    try {
      var queryParameters = <String, dynamic>{};

      if (soilData != null) {
        queryParameters['soilData'] = jsonEncode(soilData);
      }
      if (disease != null) {
        queryParameters['disease'] = disease;
      }
      if (weatherData != null) {
        queryParameters['weatherData'] = jsonEncode(weatherData);
      }

      final url = Uri.http(Uri.parse(baseUrl).authority, '/getRecommendation/', queryParameters);

      final response = await client.get(
        url,
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Recommendation Failed: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception('Recommendation Error: $e');
    }
  }
  

  // Chat task implementation for Groq AI
  static Future<Map<String, dynamic>> _chatTask(
    http.Client client, String baseUrl, Map<String, dynamic> params) async {
    final message = params['message'];

    try {
      final response = await client.post(
        Uri.parse('$baseUrl/chat'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": message}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Chat Failed: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception('Chat Error: $e');
    }
  }

  // Public API methods
  static Future<Map<String, dynamic>> analyzeSoil(Map<String, dynamic> soilData) async {
    return _sendRequest('analyzeSoil', {'soilData': soilData});
  }

  static Future<Map<String, dynamic>> detectPlantDisease(File file) async {
    return _sendRequest('detectPlantDisease', {'filePath': file.path});
  }

  static Future<Map<String, dynamic>> getWeather(double latitude, double longitude) async {
    return _sendRequest('getWeather', {'latitude': latitude, 'longitude': longitude});
  }

  static Future<Map<String, dynamic>> getRecommendation({
    Map<String, dynamic>? soilData,
    String? disease,
    Map<String, dynamic>? weatherData,
  }) async {
    return _sendRequest('getRecommendation', {
      'soilData': soilData,
      'disease': disease,
      'weatherData': weatherData,
    });
  }
  

  // Chat method for Genai AI
  static Future<Map<String, dynamic>> chat(String message) async {
    return _sendRequest('chat', {'message': message});
  }

 
}
