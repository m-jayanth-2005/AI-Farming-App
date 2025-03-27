import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
// Import logger
// Import DataProvider

import 'dart:convert';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Lock orientation to portrait for better UI experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Farming Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Farming Assistant',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.landscape), text: 'Soil'),
            Tab(icon: Icon(Icons.healing), text: 'Disease'),
            Tab(icon: Icon(Icons.cloud), text: 'Weather'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Recommend'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const SoilAnalysisScreen(),
          const DiseaseDetectionScreen(),
          const WeatherScreen(),
          ChatBotScreen(),
        ],
      ),
    );
  }
}

// SOIL ANALYSIS SCREEN
class SoilAnalysisScreen extends StatefulWidget {
  const SoilAnalysisScreen({super.key});

  @override
  State<SoilAnalysisScreen> createState() => _SoilAnalysisScreenState();
}

class _SoilAnalysisScreenState extends State<SoilAnalysisScreen>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _phController = TextEditingController(text: '6.5'); // Add this line
  final _moistureController = TextEditingController(text: '45.0'); // Add this line
  final _nitrogenController = TextEditingController(text: '40');
  final _phosphorusController = TextEditingController(text: '40');
  final _potassiumController = TextEditingController(text: '40');

  bool _isLoading = false;
  Map<String, dynamic>? _soilResult;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _phController.dispose();
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _moistureController.dispose();
    super.dispose();
  }

  Future<void> _analyzeSoil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final soilData = {
        "ph": double.parse(_phController.text),
        "N": int.parse(_nitrogenController.text),
        "P": int.parse(_phosphorusController.text),
        "K": int.parse(_potassiumController.text),
        "moisture": double.parse(_moistureController.text),
      };

      final result = await ApiService.analyzeSoil(soilData);

      if (mounted) {
        setState(() {
          _soilResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError("Failed to analyze soil: $e");
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Input card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Soil Nutrient Analysis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildNumberField(
                      controller: _nitrogenController,
                      label: 'Nitrogen (N)',
                      suffix: 'mg/kg',
                    ),
                    const SizedBox(height: 12),
                    _buildNumberField(
                      controller: _phosphorusController,
                      label: 'Phosphorus (P)',
                      suffix: 'mg/kg',
                    ),
                    const SizedBox(height: 12),
                    _buildNumberField(
                      controller: _potassiumController,
                      label: 'Potassium (K)',
                      suffix: 'mg/kg',
                    ),// Inside build:
                    _buildNumberField(
                      controller: _phController,
                      label: 'pH Level',
                      suffix: '', // No suffix for pH
                    ),
                    
                    const SizedBox(height: 12),
                    _buildNumberField(
                      controller: _moistureController,
                      label: 'Moisture',
                      suffix: '%',
                    ),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _analyzeSoil,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Analyze Soil'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Results
          if (_soilResult != null) _buildSoilResultCard(_soilResult!),
        ],
      ),
    );
  }

  Widget _buildNumberField({
  required TextEditingController controller,
  required String label,
  required String suffix,
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      suffixText: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    keyboardType: TextInputType.numberWithOptions(decimal: true), // Allow decimals
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')), // Allow decimal input
    ],
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Please enter a value';
      }

      final number = double.tryParse(value); // Parse as double
      if (number == null || number < 0 || number > 150) {
        return 'Enter a value between 0 and 150';
      }

      return null;
    },
  );
}

  Widget _buildSoilResultCard(Map<String, dynamic> result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Soil Analysis Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildResultRow('Soil Type', result['soilType'] ?? 'Unknown'),
            _buildResultRow('pH Level', result['pH']?.toString() ?? 'N/A'),
            _buildResultRow('Fertility Level', result['fertility'] ?? 'N/A'),

            const Divider(height: 32),

            const Text(
              'Recommended Crops:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final crop in result['recommendedCrops'] ?? [])
                  Chip(
                    label: Text(crop),
                    backgroundColor: Colors.green.shade100,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

// DISEASE DETECTION SCREEN
class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen>
    with AutomaticKeepAliveClientMixin {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes; // Use Uint8List for web
  bool _isLoading = false;
  Map<String, dynamic>? _diseaseResult;

  @override
  bool get wantKeepAlive => true;

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes(); // Read as bytes for web
        setState(() {
          _imageBytes = bytes;
          _diseaseResult = null;
        });

        _detectDisease();
      }
    } catch (e) {
      _showError("Failed to pick image: $e");
    }
  }

  Future<void> _detectDisease() async {
    if (_imageBytes == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.detectPlantDiseaseBytes(_imageBytes!); // Use bytes method

      if (mounted) {
        setState(() {
          _diseaseResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError("Failed to detect disease: $e");
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ... (rest of the UI code)

          // Image preview
          if (_imageBytes != null)
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: kIsWeb
                        ? Image.memory(
                            _imageBytes!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          )
                        : Image.memory(
                            _imageBytes!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _isLoading
                        ? const Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 8),
                                Text('Analyzing image...'),
                              ],
                            ),
                          )
                        : _diseaseResult != null
                            ? _buildDiseaseResultView(_diseaseResult!)
                            : const Text('Processing image...'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ... (rest of
  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildDiseaseResultView(Map<String, dynamic> result) {
    final disease = result['disease'] ?? 'Unknown';
    final confidence = result['confidence'] ?? 0.0;
    final description = result['description'] ?? 'No information available';
    final treatment = result['treatment'] ?? 'No treatment information available';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              disease == 'healthy' ? Icons.check_circle : Icons.warning,
              color: disease == 'healthy' ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Detected: $disease',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Confidence: ${(confidence * 100).toStringAsFixed(1)}%'),
        const Divider(height: 24),
        const Text(
          'Description:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(description),
        const SizedBox(height: 16),
        const Text(
          'Treatment:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(treatment),
      ],
    );
  }
}

// WEATHER SCREEN
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = false;
  Map<String,dynamic>? _weatherData;

  // Default coordinates (can be replaced with actual location)
  final double _latitude = 17.3850;
  final double _longitude = 78.4867;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.getWeather(_latitude, _longitude);

      if (mounted) {
        setState(() {
          _weatherData = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError("Failed to fetch weather: $e");
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      onRefresh: _fetchWeather,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading && _weatherData == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_weatherData != null)
              _buildWeatherCard(_weatherData!)
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Failed to load weather data'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchWeather,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Weather impact on farming
            if (_weatherData != null)
              _buildFarmingImpactCard(_weatherData!),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(Map<String, dynamic> weather) {
    final temp = weather['temperature']?.toString() ?? 'N/A';
    final humidity = weather['humidity']?.toString() ?? 'N/A';
    final forecast = weather['forecast'] ?? 'No forecast available';
    final windSpeed = weather['windSpeed']?.toString() ?? 'N/A';
    final rainfall = weather['rainfall']?.toString() ?? 'N/A';

    return Card(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _getWeatherIcon(forecast),
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  '$temp°C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  forecast,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildWeatherDetailRow(
                  Icons.water_drop,
                  'Humidity',
                  '$humidity%',
                ),
                const Divider(height: 24),
                _buildWeatherDetailRow(
                  Icons.air,
                  'Wind Speed',
                  '$windSpeed km/h',
                ),
                const Divider(height: 24),
                _buildWeatherDetailRow(
                  Icons.umbrella,
                  'Rainfall',
                  '$rainfall mm',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmingImpactCard(Map<String, dynamic> weather) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Impact on Farming',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildImpactItem(
              Icons.water_drop,
              'Irrigation Needs',
              _getIrrigationAdvice(weather),
            ),
            const SizedBox(height: 12),
            _buildImpactItem(
              Icons.bug_report,
              'Pest Risk',
              _getPestRiskAdvice(weather),
            ),
            const SizedBox(height: 12),
            _buildImpactItem(
              Icons.spa,
              'Crop Health',
              _getCropHealthAdvice(weather),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildImpactItem(IconData icon, String label, String advice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(advice),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getWeatherIcon(String forecast) {
    final lowercaseForecast = forecast.toLowerCase();

    if (lowercaseForecast.contains('rain')) {
      return Icons.water;
    } else if (lowercaseForecast.contains('cloud')) {
      return Icons.cloud;
    } else if (lowercaseForecast.contains('sun') ||
        lowercaseForecast.contains('clear')) {
      return Icons.wb_sunny;
    } else if (lowercaseForecast.contains('storm')) {
      return Icons.thunderstorm;
    } else if (lowercaseForecast.contains('snow')) {
      return Icons.ac_unit;
    } else if (lowercaseForecast.contains('wind')) {
      return Icons.air;
    } else {
      return Icons.cloud_queue;
    }
  }

  String _getIrrigationAdvice(Map<String, dynamic> weather) {
    final rainfall = weather['rainfall'] ?? 0.0;
    final temperature = weather['temperature'] ?? 25.0;

    if (rainfall > 20) {
      return 'Irrigation not needed due to recent rainfall. Monitor field drainage.';
    } else if (rainfall > 5) {
      return 'Light irrigation may be needed depending on crop type and stage.';
    } else if (temperature > 30) {
      return 'Increased irrigation needed due to high temperatures and evaporation rates.';
    } else {
      return 'Regular irrigation recommended based on crop water requirements.';
    }
  }

  String _getPestRiskAdvice(Map<String, dynamic> weather) {
    final humidity = weather['humidity'] ?? 50;
    final temperature = weather['temperature'] ?? 25.0;

    if (humidity > 80 && temperature > 25) {
      return 'High risk of fungaldiseases and pests due to warm, humid conditions. Consider preventive measures.';
    } else if (humidity > 70) {
      return 'Moderate risk of fungal development. Monitor crops closely.';
    } else if (temperature > 30) {
      return 'Watch for increased insect activity due to high temperatures.';
    } else {
      return 'Low to moderate pest risk. Maintain regular monitoring.';
    }
  }

  String _getCropHealthAdvice(Map<String, dynamic> weather) {
    final forecast = (weather['forecast'] ?? '').toLowerCase();
    final temperature = weather['temperature'] ?? 25.0;

    if (forecast.contains('storm')) {
      return 'Risk of physical damage to crops. Consider protective measures if possible.';
    } else if (temperature < 10) {
      return 'Cold stress risk for sensitive crops. Consider protective measures.';
    } else if (temperature > 35) {
      return 'Heat stress risk. Ensure adequate irrigation and consider shade for sensitive crops.';
    } else if (forecast.contains('clear') || forecast.contains('sun')) {
      return 'Good conditions for photosynthesis. Optimal time for foliar applications.';
    } else {
      return 'Average growing conditions. Follow standard crop management practices.';
    }
  }
}







class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  Future<void> _sendMessage(String message) async {
    setState(() {
      _messages.add({"role": "user", "message": message});
    });

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8001/chat'), // Replace with your backend URL
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"message": message}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _messages.add({"role": "bot", "message": data['response']});
      });
    } else {
      setState(() {
        _messages.add({"role": "bot", "message": "Error: Unable to fetch response."});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Farming Chatbot'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Text(message['message']!),
                  subtitle: Text(message['role'] == 'user' ? 'You' : 'Bot'),
                  tileColor: message['role'] == 'user' ? Colors.green[50] : Colors.blue[50],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything about farming...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _sendMessage(_controller.text);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
