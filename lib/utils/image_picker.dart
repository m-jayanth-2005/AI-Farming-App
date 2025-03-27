import 'dart:io';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ImagePickerWidget extends StatefulWidget {
  const ImagePickerWidget({super.key});

  @override
  ImagePickerWidgetState createState() => ImagePickerWidgetState();
}

class ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _image;
  XFile? _webImage; // Store XFile for web
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _getImage() async {
    final picker = ImagePicker();
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous error
    });
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (kIsWeb) {
          setState(() {
            _webImage = pickedFile; // Store XFile for web
            _isLoading = false;
          });
        } else {
          setState(() {
            _image = File(pickedFile.path); // Store File for other platforms
            _isLoading = false;
          });
        }

        if (mounted) {
          logger.d('Image selected');
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Error picking image: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error picking image: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _buildLocationCard(),
          const SizedBox(height: 16),
          if (_image != null || _webImage != null) _buildImagePreview(), // Modified this line
          const SizedBox(height: 16),
          _buildImageSelectionButton(),
          const SizedBox(height: 16),
          if (_isLoading) const CircularProgressIndicator(),
          if (_errorMessage != null) _buildErrorCard(),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Hyderabad, Telangana, India',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (kIsWeb && _webImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(_webImage!.path), // Display from XFile path (web)
      );
    } else if (_image != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.file(_image!), // Display from File (non-web)
      );
    }
    return Container(); // Return an empty container if no image
  }

  Widget _buildImageSelectionButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _getImage,
      icon: const Icon(Icons.camera_alt),
      label: const Text('Select Photo'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade100,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _getImage,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}