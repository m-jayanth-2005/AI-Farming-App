import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String weatherData = "Fetching weather...";

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  void fetchWeather() async {
    String response = await ApiService.getWeather();
    setState(() {
      weatherData = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Weather Forecast'), backgroundColor: Colors.green),
      body: Center(
        child: Text(weatherData, style: TextStyle(fontSize: 18, color: Colors.blue)),
      ),
    );
  }
}
