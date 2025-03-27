import 'package:flutter/material.dart';

class DataProvider with ChangeNotifier {
  Map<String, dynamic>? soilData;
  Map<String, dynamic>? weatherData;

  void setSoilData(Map<String, dynamic> data) {
    soilData = data;
    notifyListeners();
  }

  void setWeatherData(Map<String, dynamic> data) {
    weatherData = data;
    notifyListeners();
  }
}