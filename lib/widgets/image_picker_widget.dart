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

  Future<void> _getImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (kIsWeb) {
          setState(() {
            _webImage = pickedFile; // Store XFile for web
          });
        } else {
          setState(() {
            _image = File(pickedFile.path); // Store File for other platforms
          });
        }
        if (mounted) {
          logger.d('Image selected');
        }
      }
    } catch (e) {
      logger.e('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (_image == null && _webImage == null)
          const Text('No image selected.')
        else if (kIsWeb && _webImage != null)
          Image.network(_webImage!.path) // Display from XFile path (web)
        else if (_image != null)
          Image.file(_image!), // Display from File (non-web)
        ElevatedButton(
          onPressed: _getImage,
          child: const Text('Select Image'),
        ),
      ],
    );
  }
}
