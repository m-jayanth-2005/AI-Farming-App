import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class PlantDiseaseScreen extends StatefulWidget {
  const PlantDiseaseScreen({super.key});

  @override
  PlantDiseaseScreenState createState() => PlantDiseaseScreenState();
}

class PlantDiseaseScreenState extends State<PlantDiseaseScreen> {
  File? _image;
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = null;
        _errorMessage = null;
      });
      _processImage();
    }
  }

  Future<void> _processImage() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous error messages
    });

    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://127.0.0.1:8001')); // Replace with your API endpoint
      request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

      var response = await request.send();
      var responseBody = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        setState(() {
          _result = json.decode(responseBody.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to detect disease: ${response.statusCode}. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_image != null)
                Column(
                  children: [
                    if (kIsWeb)
                      const Text("Web Image Preview Placeholder")
                    else
                      Image.file(
                        _image!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _getImage, // Disable button while loading
                child: const Text('Select Image'),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_result != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Disease: ${_result!['disease_name'] ?? 'Unknown'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Confidence: ${(_result!['confidence'] * 100).toStringAsFixed(2)}%',
                      ),
                      if (_result!['disease_info'] != null)
                        Text('Info: ${_result!['disease_info']}'),
                    ],
                  ),
                ),
              if (_image == null && _errorMessage == null && _result == null && !_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Please select an image to detect plant disease."),
                )
            ],
          ),
        ),
      ),
    );
  }
}
