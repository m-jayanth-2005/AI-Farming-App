import 'package:ai_farming_app/screens/plant_disease_screen.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ai_farming_app/screens/plant_disease_screen.dart'; // Import PlantDiseaseScreen
import 'package:flutter/foundation.dart' show kIsWeb;

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
  static const String apiKey = 'http://127.0.0.1:8001'; // Replace with your API key

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

class SoilNutrient {
  final String name;
  final String value;
  final String unit;
  final double percentage;
  final String status; // 'low', 'optimal', 'high'
  final Color color;

  SoilNutrient({
    required this.name,
    required this.value,
    required this.unit,
    required this.percentage,
    required this.status,
    required this.color,
  });
}

class SoilAnalysisScreen extends StatefulWidget {
  const SoilAnalysisScreen({super.key});

  @override
  State<SoilAnalysisScreen> createState() => _SoilAnalysisScreenState();
}

class _SoilAnalysisScreenState extends State<SoilAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SoilNutrient> nutrients = [];
  bool _isLoading = false;
  Map<String, dynamic>? _soilData;
  WeatherData? _weatherData;
  final WeatherApiClient _weatherApiClient = WeatherApiClient();
  String _weatherErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchSoilData();
    _fetchWeatherData('Bhimavaram');
  }

  Future<void> _fetchWeatherData(String city) async {
    setState(() {
      _isLoading = true;
      _weatherErrorMessage = '';
    });
    try {
      final weatherData = await _weatherApiClient.getWeatherForCity(city);
      setState(() {
        _weatherData = weatherData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _weatherErrorMessage = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $_weatherErrorMessage'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchSoilData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final result = await ApiService2.analyzeSoil({
        "N": 50,
        "P": 30,
        "K": 80,
        "pH": 6.5,
        "moisture": 23.0,
      });
      setState(() {
        _soilData = result;
        _isLoading = false;
        if (result['status'] == 'success') {
          nutrients = _mapSoilDataToNutrients(result['result']);
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to load soil data: ${result['result']}'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to load soil data: $e'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  List<SoilNutrient> _mapSoilDataToNutrients(Map<String, dynamic> data) {
    return [
      SoilNutrient(
        name: 'pH',
        value: data['pH'].toString(),
        unit: '',
        percentage: double.parse(data['pH'].toString()) * 10,
        status: data['pH'] > 6 && data['pH'] < 7.5 ? 'optimal' : 'low',
        color: data['pH'] > 6 && data['pH'] < 7.5 ? Colors.green : Colors.orange,
      ),
      SoilNutrient(
        name: 'Nitrogen (N)',
        value: data['N'].toString(),
        unit: 'ppm',
        percentage: double.parse(data['N'].toString()),
        status: data['N'] > 40 ? 'optimal' : 'low',
        color: data['N'] > 40 ? Colors.green : Colors.orange,
      ),
      SoilNutrient(
        name: 'Phosphorus (P)',
        value: data['P'].toString(),
        unit: 'ppm',
        percentage: double.parse(data['P'].toString()),
        status: data['P'] > 40 ? 'optimal' : 'low',
        color: data['P'] > 40 ? Colors.green : Colors.orange,
      ),
      SoilNutrient(
        name: 'Potassium (K)',
        value: data['K'].toString(),
        unit: 'ppm',
        percentage: double.parse(data['K'].toString()),
        status: data['K'] > 40 ? 'optimal' : 'low',
        color: data['K'] > 40 ? Colors.green : Colors.orange,
      ),
      SoilNutrient(
        name: 'Organic Matter',
        value: data['Organic Matter'].toString(),
        unit: '%',
        percentage: double.parse(data['Organic Matter'].toString()) * 20,
        status: data['Organic Matter'] > 3 ? 'optimal' : 'low',
        color: data['Organic Matter'] > 3 ? Colors.green : Colors.orange,
      ),
      SoilNutrient(
        name: 'Calcium (Ca)',
        value: data['Calcium (Ca)'].toString(),
        unit: 'ppm',
        percentage: double.parse(data['Calcium (Ca)'].toString()) / 16,
        status: data['Calcium (Ca)'] > 1200 ? 'optimal' : 'low',
        color: data['Calcium (Ca)'] > 1200 ? Colors.green : Colors.orange,
      ),
    ];
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
        title: const Text('Smart Farming Assistant'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Soil', icon: Icon(Icons.grass)),
            Tab(text: 'Disease', icon: Icon(Icons.bug_report)),
            Tab(text: 'Weather', icon: Icon(Icons.cloud)),
            Tab(text: 'Recommend', icon: Icon(Icons.lightbulb)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                const PlantDiseaseScreen(),
                _buildWeatherTab(),
                _buildActionsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddSampleDialog();
        },
        tooltip: 'Add New Sample',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildSoilHealthScore(),
          const SizedBox(height: 16),
          _buildNutrientChart(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 8),
                const Text('Farm Location: North Field',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Chip(
                  label: const Text('Recent'),
                  backgroundColor: Colors.green.withOpacity(0.2),
                  avatar: const Icon(Icons.access_time, size: 16),
                ),
              ],
            ),
            const Divider(),
            const Text('Sample collected on May 15, 2023 at 9:30 AM',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoCircle('Soil Type', 'Clay Loam'),
                _buildInfoCircle('Moisture', '23%'),
                _buildInfoCircle('Temp', '18°C'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCircle(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSoilHealthScore() {
    final avgHealth =
        nutrients.map((n) => n.percentage).reduce((a, b) => a + b) / nutrients.length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Soil Health Score',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          height: 80,
                          width: 80,
                          child: CircularProgressIndicator(
                            value: avgHealth / 100,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              avgHealth > 70
                                  ? Colors.green
                                  : avgHealth > 40
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          '${avgHealth.toInt()}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildScoreIndicator('pH Balance', nutrients[0].percentage),
                      const SizedBox(height: 8),
                      _buildScoreIndicator(
                          'Nutrient Levels',
                          (nutrients[1].percentage +
                                  nutrients[2].percentage +
                                  nutrients[3].percentage) /
                              3),
                      const SizedBox(height: 8),
                      _buildScoreIndicator('Organic Content', nutrients[4].percentage),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(String label, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage > 70
                ? Colors.green
                : percentage > 40
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nutrient Levels',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value >= 0 && value < nutrients.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                nutrients[value.toInt()].name.split(' ')[0],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    nutrients.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: nutrients[index].percentage,
                          color: nutrients[index].color,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildLegendItem('Optimal', Colors.green),
                _buildLegendItem('Low', Colors.orange),
                _buildLegendItem('Critical', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildWeatherTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Weather',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildWeatherCard(),
          if (_weatherErrorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Error: $_weatherErrorMessage',
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    if (_weatherData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blue),
                const SizedBox(width: 8),
                Text(_weatherData!.location,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_weatherData!.temperature.toStringAsFixed(1)}°C',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(_weatherData!.condition,
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                Image.network(
                  'http://openweathermap.org/img/w/${_weatherData!.iconCode}.png',
                  width: 60,
                  height: 60,
                  errorBuilder:
                      (BuildContext context, Object exception, StackTrace? stackTrace) {
                    return const Icon(Icons.error_outline);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherInfo('Wind', '${_weatherData!.windSpeed} m/s'),
                _buildWeatherInfo('Humidity', '${_weatherData!.humidity}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Recommended Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildActionCard(
            title: 'Apply Lime',
            subtitle: 'To adjust pH and increase calcium',
            icon: Icons.add_circle,
            color: Colors.blue,
          ),
        _buildActionCard(
          title: 'Nitrogen Fertilizer',
          subtitle: 'For nitrogen deficiency',
          icon: Icons.grass,
          color: Colors.green,
        ),
        _buildActionCard(
          title: 'Potassium Supplement',
          subtitle: 'To boost potassium levels',
          icon: Icons.local_florist,
          color: Colors.orange,
        ),
        _buildActionCard(
          title: 'Organic Compost',
          subtitle: 'Improve soil structure and fertility',
          icon: Icons.compost,
          color: Colors.brown,
        ),
        _buildActionCard(
          title: 'Pest Control',
          subtitle: 'Address pest issues',
          icon: Icons.bug_report,
          color: Colors.red,
        ),
        _buildActionCard(
          title: 'Irrigation',
          subtitle: 'Adjust watering based on moisture levels',
          icon: Icons.water_drop,
          color: Colors.lightBlue,
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }

  void _showAddSampleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Soil Sample'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Sample Name')),
            TextField(decoration: const InputDecoration(labelText: 'Location')),
            ElevatedButton(
              onPressed: () {
                // Implement logic to add new sample
                Navigator.of(context).pop();
              },
              child: const Text('Add Sample'),
            ),
          ],
        ),
      ),
    );
  }
}

// Dummy ApiService2 for demonstration
class ApiService2 {
  static Future<Map<String, dynamic>> analyzeSoil(Map<String, dynamic> data) async {
    // Simulate API call and response
    await Future.delayed(const Duration(seconds: 1));
    return {
      'status': 'success',
      'result': {
        'pH': 6.8,
        'N': 55,
        'P': 45,
        'K': 60,
        'Organic Matter': 3.5,
        'Calcium (Ca)': 1300,
      },
    };
  }
}
