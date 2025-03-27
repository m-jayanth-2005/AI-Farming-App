import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

// Use a singleton pattern for logger
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

// Model class for recommendations
class Recommendation {
  final String title;
  final String content;
  final String icon;
  final Color color;
  final List<String> details;
  final DateTime timestamp;
  
  const Recommendation({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
    required this.details,
    required this.timestamp,
  });
}

class AIRecommendationScreen extends StatefulWidget {
  const AIRecommendationScreen({super.key});

  @override
  State<AIRecommendationScreen> createState() => _AIRecommendationScreenState();
}

class _AIRecommendationScreenState extends State<AIRecommendationScreen> {
  bool _isLoading = true;
  final List<Recommendation> _recommendations = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    try {
      // Simulate network request
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _recommendations.addAll([
          Recommendation(
            title: 'Crop Selection',
            content: 'Consider planting corn and soybeans for rotation.',
            icon: 'agriculture',
            color: Colors.green.shade700,
            details: [
              'Corn requires high nitrogen levels',
              'Soybeans fix nitrogen in soil',
              'Rotation helps prevent pest buildup',
              'Expected yield increase: 15-20%'
            ],
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
          ),
          Recommendation(
            title: 'Pest Control',
            content: 'Use neem oil for natural pest control.',
            icon: 'pest_control',
            color: Colors.orange.shade800,
            details: [
              'Effective against aphids and mites',
              'Apply every 7-14 days',
              'Safe for beneficial insects when dry',
              'Best applied in early morning or evening'
            ],
            timestamp: DateTime.now().subtract(const Duration(hours: 12)),
          ),
          Recommendation(
            title: 'Fertilization',
            content: 'Apply nitrogen-rich fertilizer during the growing season.',
            icon: 'eco',
            color: Colors.blue.shade700,
            details: [
              'Apply 150-180 lbs N per acre for corn',
              'Split application recommended',
              'Consider soil test results',
              'Avoid application before heavy rain'
            ],
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          Recommendation(
            title: 'Water Management',
            content: 'Implement drip irrigation to optimize water usage.',
            icon: 'water_drop',
            color: Colors.lightBlue.shade700,
            details: [
              'Reduces water usage by 30-50%',
              'Minimizes weed growth',
              'Decreases runoff and erosion',
              'Initial setup cost: 1,200-1,800  per acre'
            ],
            timestamp: DateTime.now(),
          ),
        ]);
        _isLoading = false;
      });
      
      logger.i('Successfully loaded ${_recommendations.length} recommendations');
    } catch (e) {
      logger.e('Error fetching recommendations',error: e);
      setState(() {
        _errorMessage = 'Unable to load recommendations. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Recommendations'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
                _recommendations.clear();
              });
              _fetchRecommendations();
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              logger.d('Filter button pressed');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filtering coming soon')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRecommendations,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildBody(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          logger.d('FAB pressed');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request new recommendation coming soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading recommendations...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchRecommendations,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_recommendations.isEmpty) {
      return const Center(
        child: Text('No recommendations available at this time.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Recommendations',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Last updated: ${DateTime.now().toString().substring(0, 16)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Based on your farm data, here are some personalized recommendations:',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _recommendations.length,
            itemBuilder: (context, index) {
              return _buildRecommendationCard(_recommendations[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(Recommendation recommendation) {
    return Card(
      elevation: 3.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: recommendation.color,
          child: Icon(
            _getIconData(recommendation.icon),
            color: Colors.white,
          ),
        ),
        title: Text(
          recommendation.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(recommendation.content),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(recommendation.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...recommendation.details.map((detail) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(child: Text(detail)),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.bookmark_border),
                      label: const Text('Save'),
                      onPressed: () {
                        logger.d('Save pressed for: ${recommendation.title}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${recommendation.title} saved')),
                        );
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      onPressed: () {
                        logger.d('Share pressed for: ${recommendation.title}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sharing ${recommendation.title}...')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'agriculture':
        return Icons.agriculture;
      case 'pest_control':
        return Icons.pest_control;
      case 'eco':
        return Icons.eco;
      case 'water_drop':
        return Icons.water_drop;
      default:
        return Icons.star;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return 'Added ${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return 'Added ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return 'Added ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Added just now';
    }
  }
}