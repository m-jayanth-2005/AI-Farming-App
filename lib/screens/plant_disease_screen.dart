import 'package:flutter/material.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../widgets/image_picker_widget.dart';

class PlantDiseaseScreen extends StatefulWidget {
  @override
  _PlantDiseaseScreenState createState() => _PlantDiseaseScreenState();
}

class _PlantDiseaseScreenState extends State<PlantDiseaseScreen> {
  File? selectedImage;
  String result = "Upload an image to detect plant disease.";

  void detectDisease() async {
    if (selectedImage != null) {
      String response = await ApiService.detectDisease(selectedImage!);
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
      appBar: AppBar(title: Text('Plant Disease Detection'), backgroundColor: Colors.green),
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
            onPressed: detectDisease,
            child: Text("Detect Disease", style: TextStyle(fontSize: 18)),
          ),
          SizedBox(height: 20),
          Text(result, style: TextStyle(fontSize: 18, color: Colors.red)),
        ],
      ),
    );
  }
}
