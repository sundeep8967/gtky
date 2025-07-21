import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/restaurant_model.dart';

class SocialFeaturesScreen extends StatefulWidget {
  const SocialFeaturesScreen({super.key});

  @override
  State<SocialFeaturesScreen> createState() => _SocialFeaturesScreenState();
}

class _SocialFeaturesScreenState extends State<SocialFeaturesScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _diningMemories = [];
  List<RestaurantModel> _favoriteRestaurants = [];
  List<UserModel> _favoriteUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSocialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSocialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (currentUser != null) {
        // Load dining memories, favorite restaurants, and favorite users
        final results = await Future.wait([
          _loadDiningMemories(currentUser.uid),
          _loadFavoriteRestaurants(currentUser.uid),
          _loadFavoriteUsers(currentUser.uid),
        ]);

        if (mounted) {
          setState(() {
            _diningMemories = results[0] as List<Map<String, dynamic>>;
            _favoriteRestaurants = results[1] as List<RestaurantModel>;
            _favoriteUsers = results[2] as List<UserModel>;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading social data: $e')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadDiningMemories(String userId) async {
    try {
      final ratingsSnapshot = await _firestoreService.getCollection(
        'ratings',
        where: [
          {'field': 'userId', 'operator': '==', 'value': userId}
        ],
        orderBy: [
          {'field': 'createdAt', 'descending': true}
        ],
        limit: 20,
      );

      List<Map<String, dynamic>> memories = [];
      
      for (var doc in ratingsSnapshot.docs) {
        final ratingData = doc.data() as Map<String, dynamic>;
        
        // Get plan details
        if (ratingData['planId'] != null) {
          final planDoc = await _firestoreService.getDocument('dining_plans', ratingData['planId']);
          if (planDoc.exists) {
            final planData = planDoc.data() as Map<String, dynamic>;
            
            // Get restaurant details
            final restaurantDoc = await _firestoreService.getDocument('restaurants', planData['restaurantId']);
            if (restaurantDoc.exists) {
              final restaurantData = restaurantDoc.data() as Map<String, dynamic>;
              
              memories.add({
                'id': doc.id,
                'planId': ratingData['planId'],
                'restaurantName': restaurantData['name'],
                'restaurantImage': restaurantData['imageUrl'],
                'cuisineTypes': restaurantData['cuisineTypes'],
                'rating': ratingData['restaurantRating'],
                'date': ratingData['createdAt'],
                'groupSize': (planData['memberIds'] as List).length,
                'photos': ratingData['photos'] ?? [],
                'experience': ratingData['experience'] ?? '',
              });
            }
          }
        }
      }
      
      return memories;
    } catch (e) {
      print('Error loading dining memories: $e');
      return [];
    }
  }

  Future<List<RestaurantModel>> _loadFavoriteRestaurants(String userId) async {
    try {
      final userDoc = await _firestoreService.getDocument('users', userId);
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final favoriteRestaurantIds = List<String>.from(userData['favoriteRestaurants'] ?? []);
        
        List<RestaurantModel> favorites = [];
        for (String restaurantId in favoriteRestaurantIds) {
          final restaurantDoc = await _firestoreService.getDocument('restaurants', restaurantId);
          if (restaurantDoc.exists) {
            favorites.add(RestaurantModel.fromMap(restaurantDoc.data() as Map<String, dynamic>, restaurantDoc.id));
          }
        }
        
        return favorites;
      }
    } catch (e) {
      print('Error loading favorite restaurants: $e');
    }
    return [];
  }

  Future<List<UserModel>> _loadFavoriteUsers(String userId) async {
    try {
      final userDoc = await _firestoreService.getDocument('users', userId);
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final favoriteUserIds = List<String>.from(userData['favoriteUsers'] ?? []);
        
        List<UserModel> favorites = [];
        for (String favoriteUserId in favoriteUserIds) {
          final favoriteUserDoc = await _firestoreService.getDocument('users', favoriteUserId);
          if (favoriteUserDoc.exists) {
            favorites.add(UserModel.fromMap(favoriteUserDoc.data() as Map<String, dynamic>, favoriteUserId));
          }
        }
        
        return favorites;
      }
    } catch (e) {
      print('Error loading favorite users: $e');
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Features'),
        backgroundColor: Colors.pink[50],
        foregroundColor: Colors.pink[700],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.pink[700],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.pink[600],
          tabs: const [
            Tab(text: 'Memories', icon: Icon(Icons.photo_album)),
            Tab(text: 'Restaurants', icon: Icon(Icons.favorite)),
            Tab(text: 'Friends', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMemoriesTab(),
                _buildFavoriteRestaurantsTab(),
                _buildFavoriteUsersTab(),
              ],
            ),
    );
  }

  Widget _buildMemoriesTab() {
    if (_diningMemories.isEmpty) {
      return _buildEmptyState(
        icon: Icons.photo_album,
        title: 'No dining memories yet',
        subtitle: 'Complete some dining plans to create memories!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _diningMemories.length,
      itemBuilder: (context, index) {
        final memory = _diningMemories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant image
              if (memory['restaurantImage'] != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Image.network(
                    memory['restaurantImage'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.restaurant, size: 64),
                    ),
                  ),
                ),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memory['restaurantName'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (memory['cuisineTypes'] as List).join(', '),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber[600], size: 16),
                        const SizedBox(width: 4),
                        Text('${memory['rating']}/5'),
                        const SizedBox(width: 16),
                        Icon(Icons.group, color: Colors.blue[600], size: 16),
                        const SizedBox(width: 4),
                        Text('${memory['groupSize']} people'),
                        const Spacer(),
                        Text(
                          _formatDate(memory['date']),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                    if (memory['experience'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        memory['experience'],
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _shareMemory(memory),
                            icon: const Icon(Icons.share, size: 16),
                            label: const Text('Share'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _addToFavorites(memory['restaurantId']),
                          icon: const Icon(Icons.favorite_border, size: 16),
                          label: const Text('Favorite'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFavoriteRestaurantsTab() {
    if (_favoriteRestaurants.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite,
        title: 'No favorite restaurants yet',
        subtitle: 'Add restaurants to your favorites from dining memories!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = _favoriteRestaurants[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: restaurant.photoUrl?.isNotEmpty == true
                  ? NetworkImage(restaurant.photoUrl!)
                  : null,
              child: restaurant.photoUrl?.isEmpty != false
                  ? const Icon(Icons.restaurant)
                  : null,
            ),
            title: Text(restaurant.name),
            subtitle: Text(restaurant.cuisineTypes.join(', ')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.amber[600], size: 16),
                const SizedBox(width: 4),
                Text(restaurant.averageRating.toStringAsFixed(1)),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeFromFavoriteRestaurants(restaurant.id),
                  icon: const Icon(Icons.favorite, color: Colors.red),
                ),
              ],
            ),
            onTap: () {
              // Navigate to restaurant details
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('View ${restaurant.name} details')),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFavoriteUsersTab() {
    if (_favoriteUsers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people,
        title: 'No favorite dining partners yet',
        subtitle: 'Add users to your favorites after great dining experiences!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteUsers.length,
      itemBuilder: (context, index) {
        final user = _favoriteUsers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: user.profilePhotoUrl?.isNotEmpty == true
                  ? NetworkImage(user.profilePhotoUrl!)
                  : null,
              child: user.profilePhotoUrl?.isEmpty != false
                  ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U')
                  : null,
            ),
            title: Text(user.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.company),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber[600], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${user.trustScore.toStringAsFixed(1)} trust score',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              onPressed: () => _removeFromFavoriteUsers(user.id),
              icon: const Icon(Icons.favorite, color: Colors.red),
            ),
            onTap: () {
              // Show user profile or invite to plan
              _showUserActions(user);
            },
          ),
        );
      },
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

  void _shareMemory(Map<String, dynamic> memory) {
    final text = 'Had an amazing dining experience at ${memory['restaurantName']}! '
        'Rated it ${memory['rating']}/5 stars. '
        '${memory['experience'].isNotEmpty ? memory['experience'] : ''} '
        '#GTKY #DiningExperience';
    
    Share.share(text);
  }

  Future<void> _addToFavorites(String restaurantId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (currentUser != null) {
        final userDoc = await _firestoreService.getDocument('users', currentUser.uid);
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final favoriteRestaurants = List<String>.from(userData['favoriteRestaurants'] ?? []);
          
          if (!favoriteRestaurants.contains(restaurantId)) {
            favoriteRestaurants.add(restaurantId);
            
            await _firestoreService.updateDocument(
              'users',
              currentUser.uid,
              {'favoriteRestaurants': favoriteRestaurants},
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Added to favorite restaurants!')),
            );
            
            _loadSocialData(); // Refresh data
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to favorites: $e')),
      );
    }
  }

  Future<void> _removeFromFavoriteRestaurants(String restaurantId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (currentUser != null) {
        final userDoc = await _firestoreService.getDocument('users', currentUser.uid);
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final favoriteRestaurants = List<String>.from(userData['favoriteRestaurants'] ?? []);
          
          favoriteRestaurants.remove(restaurantId);
          
          await _firestoreService.updateDocument(
            'users',
            currentUser.uid,
            {'favoriteRestaurants': favoriteRestaurants},
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorites')),
          );
          
          _loadSocialData(); // Refresh data
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing from favorites: $e')),
      );
    }
  }

  Future<void> _removeFromFavoriteUsers(String userId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (currentUser != null) {
        final userDoc = await _firestoreService.getDocument('users', currentUser.uid);
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final favoriteUsers = List<String>.from(userData['favoriteUsers'] ?? []);
          
          favoriteUsers.remove(userId);
          
          await _firestoreService.updateDocument(
            'users',
            currentUser.uid,
            {'favoriteUsers': favoriteUsers},
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorite users')),
          );
          
          _loadSocialData(); // Refresh data
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing from favorites: $e')),
      );
    }
  }

  void _showUserActions(UserModel user) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('View ${user.name}\'s profile')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text('Invite to Dining Plan'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invite ${user.name} to a dining plan')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Send message to ${user.name}')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    
    DateTime dateTime;
    if (date is String) {
      dateTime = DateTime.parse(date);
    } else {
      dateTime = date.toDate();
    }
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}