import 'package:flutter/material.dart';
import '../../models/restaurant_model.dart';
import '../../services/restaurant_service.dart';
import '../../services/location_service.dart';
import '../restaurants/create_plan_screen.dart';
// import 'restaurant_details_screen.dart'; // Commented out to avoid compilation error

class RestaurantDiscoveryScreen extends StatefulWidget {
  const RestaurantDiscoveryScreen({super.key});

  @override
  State<RestaurantDiscoveryScreen> createState() => _RestaurantDiscoveryScreenState();
}

class _RestaurantDiscoveryScreenState extends State<RestaurantDiscoveryScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  final LocationService _locationService = LocationService();
  
  List<RestaurantModel> _restaurants = [];
  List<RestaurantModel> _filteredRestaurants = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCuisine = 'All';
  bool _showMapView = false;
  
  final List<String> _cuisineTypes = [
    'All', 'Italian', 'Chinese', 'Mexican', 'Indian', 'Japanese', 
    'American', 'Thai', 'Mediterranean', 'French', 'Korean'
  ];

  @override
  void initState() {
    super.initState();
    _loadPartnerRestaurants();
  }

  Future<void> _loadPartnerRestaurants() async {
    try {
      setState(() => _isLoading = true);
      
      // Get user's current location
      final position = await _locationService.getCurrentPosition();
      
      // Load partner restaurants only
      final restaurants = await _restaurantService.getPartnerRestaurantsNearby(
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
      
      // If no restaurants found, add sample data
      if (restaurants.isEmpty) {
        await _restaurantService.addSamplePartnerRestaurants();
        final newRestaurants = await _restaurantService.getPartnerRestaurantsNearby(
          latitude: position?.latitude,
          longitude: position?.longitude,
        );
        restaurants.addAll(newRestaurants);
      }
      
      setState(() {
        _restaurants = restaurants;
        _filteredRestaurants = restaurants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading restaurants: $e')),
        );
      }
    }
  }

  void _filterRestaurants() {
    setState(() {
      _filteredRestaurants = _restaurants.where((restaurant) {
        final matchesSearch = restaurant.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            restaurant.address.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCuisine = _selectedCuisine == 'All' || 
                             restaurant.cuisineTypes.contains(_selectedCuisine);
        return matchesSearch && matchesCuisine;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Restaurants'),
        actions: [
          IconButton(
            icon: Icon(_showMapView ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _showMapView = !_showMapView;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search restaurants...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _filterRestaurants();
                  },
                ),
                const SizedBox(height: 12),
                // Cuisine Filter
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cuisineTypes.length,
                    itemBuilder: (context, index) {
                      final cuisine = _cuisineTypes[index];
                      final isSelected = _selectedCuisine == cuisine;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cuisine),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCuisine = cuisine;
                            });
                            _filterRestaurants();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Results Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRestaurants.isEmpty
                    ? _buildEmptyState()
                    : _showMapView
                        ? _buildMapView()
                        : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.restaurant_menu,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No partner restaurants found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadPartnerRestaurants,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Map View',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Google Maps integration coming soon',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = _filteredRestaurants[index];
        return _buildRestaurantCard(restaurant);
      },
    );
  }

  Widget _buildRestaurantCard(RestaurantModel restaurant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Navigate to restaurant details - placeholder implementation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening ${restaurant.name} details'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Restaurant Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                    ),
                    child: restaurant.photoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              restaurant.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.restaurant, size: 40);
                              },
                            ),
                          )
                        : const Icon(Icons.restaurant, size: 40),
                  ),
                  const SizedBox(width: 16),
                  // Restaurant Info
                  Expanded(
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'PARTNER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          restaurant.cuisineTypes.join(', '),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${restaurant.rating.toStringAsFixed(1)} (${restaurant.reviewCount})',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              restaurant.priceRange,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          restaurant.address,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Discount Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${restaurant.discountPercentage.toInt()}% discount for GTKY groups',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreatePlanScreen(restaurant: restaurant),
                      ),
                    );
                  },
                  child: const Text('Create Dining Plan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}