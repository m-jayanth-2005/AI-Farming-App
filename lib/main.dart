import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(AIFarmingApp());
}

class AIFarmingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Farming App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Arial',
      ),
      home: HomeScreen(),
    );
  }
}
