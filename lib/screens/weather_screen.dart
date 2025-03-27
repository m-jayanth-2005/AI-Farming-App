import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'dart:io';

final logger = Logger();

// Weather data model
class WeatherData {
  final String location;
  final double temperature;
  final String condition;
  final double windSpeed;
  final int humidity;
  final String iconCode;

  WeatherData({
    required this.location,
    required this.temperature,
    required this.condition,
    required this.windSpeed,
    required this.humidity,
    required this.iconCode,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      location: json['name'] ?? 'Unknown',
      temperature: (json['main']['temp'] ?? 0).toDouble(),
      condition: json['weather'][0]['description'] ?? 'Unknown',
      windSpeed: (json['wind']['speed'] ?? 0).toDouble(),
      humidity: json['main']['humidity'] ?? 0,
      iconCode: json['weather'][0]['icon'] ?? '01d',
    );
  }

  factory WeatherData.empty() {
    return WeatherData(
      location: 'Unknown',
      temperature: 0,
      condition: 'Unknown',
      windSpeed: 0,
      humidity: 0,
      iconCode: '01d',
    );
  }
}

class WeatherApiClient {
  static const String apiKey = '8ba53915fee10bd9cf54e896183b1021';

  Future<WeatherData> getWeatherForCity(String city) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$apiKey'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return WeatherData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  WeatherScreenState createState() => WeatherScreenState();
}

class WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _cityController =
      TextEditingController(text: 'Vijayawada');
  final WeatherApiClient _apiClient = WeatherApiClient();

  bool _isLoading = false;
  String _errorMessage = '';
  WeatherData? _weatherData;

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeatherData() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a city name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final weatherData = await _apiClient.getWeatherForCity(city);
      setState(() {
        _weatherData = weatherData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $_errorMessage'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchWeatherData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          hintText: 'Enter city name',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _fetchWeatherData(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _fetchWeatherData,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else if (_errorMessage.isNotEmpty && _weatherData == null)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load weather data',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(_errorMessage),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchWeatherData,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              else if (_weatherData != null)
                _buildWeatherCard(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    final weather = _weatherData!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue, Colors.lightBlueAccent],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weather.location,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateTime.now().toString().substring(0, 10),
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Icon(
                _getWeatherIcon(weather.iconCode),
                size: 64,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weather.temperature.round()}°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    weather.condition,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.water_drop, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${weather.humidity}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.air, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${weather.windSpeed} m/s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String iconCode) {
    switch (iconCode.substring(0, 2)) {
      case '01':
        return Icons.wb_sunny;
      case '02':
        return Icons.cloud_sync;
      case '03':
      case '04':
        return Icons.cloud;
      case '09':
      case '10':
        return Icons.grain;
      case '11':
        return Icons.thunderstorm;
      case '13':
        return Icons.ac_unit;
      case '50':
        return Icons.blur_on;
      default:
        return Icons.wb_sunny;
    }
  }
}

class ImagePickerWidget extends StatefulWidget {
  const ImagePickerWidget({super.key});

  @override
  ImagePickerWidgetState createState() => ImagePickerWidgetState();
}

class ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _image;
  XFile? _webImage;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _getImage() async {
    final picker = ImagePicker();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (kIsWeb) {
          setState(() {
            _webImage = pickedFile;
            _isLoading = false;
          });
        } else {
          setState(() {
            _image = File(pickedFile.path);
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
          if (_image != null || _webImage != null) _buildImagePreview(),
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
            const Text('Vijayawada, Andhra Pradesh, India',
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
        child: Image.network(_webImage!.path),
      );
    } else if (_image != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.file(_image!),
      );
    }
    return Container();
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
