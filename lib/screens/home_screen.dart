import 'package:flutter/material.dart';
import 'soil_analysis_screen.dart';
import 'plant_disease_screen.dart';
import 'weather_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Farming App'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/farming_logo.png', height: 150), // Add logo
          SizedBox(height: 20),
          CustomButton(
            text: "Soil Health Analysis",
            icon: Icons.agriculture,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SoilAnalysisScreen()),
            ),
          ),
          CustomButton(
            text: "Plant Disease Detection",
            icon: Icons.eco,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PlantDiseaseScreen()),
            ),
          ),
          CustomButton(
            text: "Weather Forecast",
            icon: Icons.wb_sunny,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WeatherScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  CustomButton({required this.text, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(icon, size: 30, color: Colors.white),
        label: Text(text, style: TextStyle(fontSize: 18, color: Colors.white)),
        onPressed: onTap,
      ),
    );
  }
}
