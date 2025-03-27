import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Constants for reusable values
  static const double gridPadding = 16.0;
  static const double iconSize = 48.0;
  static const double textFontSize = 16.0;
  static const Color iconColor = Colors.green;
  static const double cardElevation = 4.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Farming App'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Navigate to notifications screen
              Navigator.pushNamed(context, '/notifications');
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(gridPadding),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: gridPadding,
          mainAxisSpacing: gridPadding,
          children: const <Widget>[
            _GridItem(
              title: 'AI Recommendations',
              route: '/ai_recommendation',
              icon: Icons.lightbulb,
            ),
            _GridItem(
              title: 'Plant Disease Detection',
              route: '/plant_disease',
              icon: Icons.sick,
            ),
            _GridItem(
              title: 'Soil Analysis',
              route: '/soil_analysis',
              icon: Icons.landscape,
            ),
            _GridItem(
              title: 'Weather Information',
              route: '/weather',
              icon: Icons.cloud,
            ),
            _GridItem(
              title: 'Crop Planning',
              route: '/crop_planning',
              icon: Icons.calendar_today,
            ),
            _GridItem(
              title: 'Irrigation',
              route: '/irrigation',
              icon: Icons.opacity,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTaskDialog(context);
        },
        tooltip: 'Add New Task',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Drawer Menu
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Welcome, Farmer!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pushNamed(context, '/help');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              // Handle logout logic
            },
          ),
        ],
      ),
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 0, // Set the current index
      onTap: (index) {
        // Handle navigation
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  // Add Task Dialog
  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Task'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Task Name',
                  hintText: 'e.g., Water the crops',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter task details',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Due Date',
                  hintText: 'MM/DD/YYYY',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Save task logic
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// Reusable Grid Item Widget
class _GridItem extends StatelessWidget {
  final String title;
  final String route;
  final IconData icon;

  const _GridItem({
    required this.title,
    required this.route,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        try {
          await Navigator.pushNamed(context, route);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to navigate to $route: $e'),
            ),
          );
        }
      },
      child: Card(
        elevation: HomeScreen.cardElevation,
        child: Padding(
          padding: const EdgeInsets.all(HomeScreen.gridPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: HomeScreen.iconSize,
                color: HomeScreen.iconColor,
              ),
              const SizedBox(height: HomeScreen.gridPadding / 2),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: HomeScreen.textFontSize),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
