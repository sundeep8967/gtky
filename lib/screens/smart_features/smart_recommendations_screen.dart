import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/advanced_matching_service.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../models/restaurant_model.dart';
import '../../models/dining_plan_model.dart';

class SmartRecommendationsScreen extends StatefulWidget {
  const SmartRecommendationsScreen({super.key});

  @override
  State<SmartRecommendationsScreen> createState() => _SmartRecommendationsScreenState();
}

class _SmartRecommendationsScreenState extends State<SmartRecommendationsScreen>
    with SingleTickerProviderStateMixin {
  final AdvancedMatchingService _matchingService = AdvancedMatchingService();
  final LocationService _locationService = LocationService();
  
  late TabController _tabController;
  
  List<RestaurantModel> _recommendedRestaurants = [];
  List<DiningPlanModel> _optimizedPlans = [];
  List<DateTime> _optimalTimings = [];
  List<String> _preferredCuisines = [];
  Map<String, double> _userPreferences = {};
  
  bool _isLoading = true;
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSmartRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSmartRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (currentUser != null) {
        // Get user location
        final position = await _locationService.getCurrentPosition();
        _userLat = position?.latitude;
        _userLng = position?.longitude;

        if (_userLat != null && _userLng != null) {
          // Load all recommendations in parallel
          final results = await Future.wait([
            _matchingService.getPersonalizedRecommendations(
              userId: currentUser.uid,
              userLat: _userLat!,
              userLng: _userLng!,
            ),
            _matchingService.getOptimizedPlans(
              userId: currentUser.uid,
              userLat: _userLat!,
              userLng: _userLng!,
            ),
            _matchingService.getOptimalTimings(
              userId: currentUser.uid,
              restaurantId: 'default', // You might want to select a specific restaurant
              targetDate: DateTime.now(),
            ),
            _matchingService.getMatchingCuisines(currentUser.uid),
            _matchingService.analyzeUserPreferences(currentUser.uid),
          ]);

          if (mounted) {
            setState(() {
              _recommendedRestaurants = results[0] as List<RestaurantModel>;
              _optimizedPlans = results[1] as List<DiningPlanModel>;
              _optimalTimings = results[2] as List<DateTime>;
              _preferredCuisines = results[3] as List<String>;
              _userPreferences = results[4] as Map<String, double>;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recommendations: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Recommendations'),
        backgroundColor: Colors.purple[50],
        foregroundColor: Colors.purple[700],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.purple[700],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.purple[600],
          tabs: const [
            Tab(text: 'Restaurants', icon: Icon(Icons.restaurant)),
            Tab(text: 'Plans', icon: Icon(Icons.group)),
            Tab(text: 'Timings', icon: Icon(Icons.schedule)),
            Tab(text: 'Insights', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRestaurantsTab(),
                _buildPlansTab(),
                _buildTimingsTab(),
                _buildInsightsTab(),
              ],
            ),
    );
  }

  Widget _buildRestaurantsTab() {
    if (_recommendedRestaurants.isEmpty) {
      return _buildEmptyState(
        icon: Icons.restaurant,
        title: 'No restaurant recommendations yet',
        subtitle: 'Complete a few dining plans to get personalized recommendations',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recommendedRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = _recommendedRestaurants[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        restaurant.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${restaurant.discountPercentage}% OFF',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  restaurant.cuisineTypes.join(', '),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      restaurant.averageRating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_calculateDistance(restaurant)} km away',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to restaurant details or create plan
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('View ${restaurant.name} details')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlansTab() {
    if (_optimizedPlans.isEmpty) {
      return _buildEmptyState(
        icon: Icons.group,
        title: 'No optimized plans available',
        subtitle: 'Check back later for plans that match your preferences',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _optimizedPlans.length,
      itemBuilder: (context, index) {
        final plan = _optimizedPlans[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dining Plan #${plan.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.blue[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${plan.plannedTime.hour.toString().padLeft(2, '0')}:${plan.plannedTime.minute.toString().padLeft(2, '0')}',
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.group, color: Colors.green[600], size: 16),
                    const SizedBox(width: 4),
                    Text('${plan.memberIds.length}/${plan.maxMembers} people'),
                  ],
                ),
                if (plan.description != null && plan.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    plan.description!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to plan details
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('View plan ${plan.id} details')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Join Plan'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimingsTab() {
    if (_optimalTimings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.schedule,
        title: 'No timing recommendations',
        subtitle: 'We\'ll suggest optimal dining times based on your preferences',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _optimalTimings.length,
      itemBuilder: (context, index) {
        final timing = _optimalTimings[index];
        final isToday = timing.day == DateTime.now().day;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.schedule,
                color: Colors.orange[600],
              ),
            ),
            title: Text(
              '${timing.hour.toString().padLeft(2, '0')}:${timing.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              isToday ? 'Today' : '${timing.day}/${timing.month}/${timing.year}',
            ),
            trailing: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Create plan for ${timing.hour}:${timing.minute.toString().padLeft(2, '0')}')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Plan'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cuisine preferences
          _buildInsightCard(
            title: 'Your Cuisine Preferences',
            icon: Icons.restaurant_menu,
            color: Colors.purple,
            child: _preferredCuisines.isEmpty
                ? const Text('Complete more dining plans to see your cuisine preferences')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _preferredCuisines.take(5).map((cuisine) {
                      return Chip(
                        label: Text(cuisine),
                        backgroundColor: Colors.purple[100],
                        labelStyle: TextStyle(color: Colors.purple[700]),
                      );
                    }).toList(),
                  ),
          ),
          
          const SizedBox(height: 16),
          
          // Time preferences
          _buildInsightCard(
            title: 'Dining Time Patterns',
            icon: Icons.access_time,
            color: Colors.blue,
            child: Column(
              children: [
                _buildPreferenceBar('Morning (6-11 AM)', _userPreferences['time_morning'] ?? 0.0, Colors.orange),
                _buildPreferenceBar('Lunch (11 AM-4 PM)', _userPreferences['time_lunch'] ?? 0.0, Colors.green),
                _buildPreferenceBar('Evening (4-9 PM)', _userPreferences['time_evening'] ?? 0.0, Colors.blue),
                _buildPreferenceBar('Night (9 PM+)', _userPreferences['time_night'] ?? 0.0, Colors.purple),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quality preferences
          if (_userPreferences['quality_threshold'] != null)
            _buildInsightCard(
              title: 'Quality Standards',
              icon: Icons.star,
              color: Colors.amber,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You prefer restaurants with ${(_userPreferences['quality_threshold']! * 5).toStringAsFixed(1)}+ star ratings',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _userPreferences['quality_threshold'],
                    backgroundColor: Colors.amber[100],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[600]!),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('${(value * 100).toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _calculateDistance(RestaurantModel restaurant) {
    if (_userLat == null || _userLng == null) return '?';
    
    // Simple distance calculation (you might want to use a more accurate method)
    final latDiff = (_userLat! - restaurant.latitude).abs();
    final lngDiff = (_userLng! - restaurant.longitude).abs();
    final distance = (latDiff + lngDiff) * 111; // Rough conversion to km
    
    return distance.toStringAsFixed(1);
  }
}