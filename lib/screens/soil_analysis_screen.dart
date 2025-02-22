import 'package:flutter/material.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../widgets/image_picker_widget.dart';

class SoilAnalysisScreen extends StatefulWidget {
  @override
  _SoilAnalysisScreenState createState() => _SoilAnalysisScreenState();
}

class _SoilAnalysisScreenState extends State<SoilAnalysisScreen> {
  File? selectedImage;
  String result = "Upload an image to analyze soil.";

  void analyzeSoil() async {
    if (selectedImage != null) {
      String response = await ApiService.analyzeSoil(selectedImage!);
      setState(() {
        result = response;
      });
    } else {
      setState(() {
        result = "Please select an image first.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Soil Health Analysis'), backgroundColor: Colors.green),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ImagePickerWidget(
            onImageSelected: (File image) {
              setState(() {
                selectedImage = image;
              });
            },
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: analyzeSoil,
            child: Text("Analyze Soil", style: TextStyle(fontSize: 18)),
          ),
          SizedBox(height: 20),
          Text(result, style: TextStyle(fontSize: 18, color: Colors.green)),
        ],
      ),
    );
  }
}
