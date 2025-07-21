import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dining_plan_model.dart';
import '../../models/restaurant_model.dart';
import '../../services/dining_plan_service.dart';
import '../../services/restaurant_service.dart';
import '../../services/auth_service.dart';
import 'plan_details_screen.dart';

class PlanDiscoveryScreen extends StatefulWidget {
  const PlanDiscoveryScreen({super.key});

  @override
  State<PlanDiscoveryScreen> createState() => _PlanDiscoveryScreenState();
}

class _PlanDiscoveryScreenState extends State<PlanDiscoveryScreen> {
  final DiningPlanService _diningPlanService = DiningPlanService();
  final RestaurantService _restaurantService = RestaurantService();
  
  List<DiningPlanModel> _allPlans = [];
  List<DiningPlanModel> _filteredPlans = [];
  Map<String, RestaurantModel> _restaurantCache = {};
  
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Filter options
  String _selectedTimeFilter = 'All';
  String _selectedCuisineFilter = 'All';
  // double _maxDistance = 10.0; // km - TODO: Implement distance filtering
  
  final List<String> _timeFilters = [
    'All',
    'Next 2 hours',
    'Today',
    'This week'
  ];
  
  final List<String> _cuisineFilters = [
    'All',
    'Italian',
    'Japanese',
    'Mediterranean',
    'American',
    'Chinese',
    'Mexican',
    'Indian',
    'Thai',
    'French'
  ];

  @override
  void initState() {
    super.initState();
    _loadOpenPlans();
  }

  Future<void> _loadOpenPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get all open plans from other users
      final allPlans = await _diningPlanService.getOpenPlansForDiscovery(currentUser.uid);
      
      // Load restaurant data for each plan
      for (var plan in allPlans) {
        if (!_restaurantCache.containsKey(plan.restaurantId)) {
          final restaurant = await _restaurantService.getRestaurantById(plan.restaurantId);
          if (restaurant != null) {
            _restaurantCache[plan.restaurantId] = restaurant;
          }
        }
      }

      setState(() {
        _allPlans = allPlans;
        _filteredPlans = allPlans;
        _isLoading = false;
      });
      
      _applyFilters();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load plans: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<DiningPlanModel> filtered = List.from(_allPlans);
    
    // Time filter
    if (_selectedTimeFilter != 'All') {
      DateTime now = DateTime.now();
      DateTime filterTime;
      
      switch (_selectedTimeFilter) {
        case 'Next 2 hours':
          filterTime = now.add(const Duration(hours: 2));
          filtered = filtered.where((plan) => 
              plan.plannedTime.isAfter(now) && 
              plan.plannedTime.isBefore(filterTime)).toList();
          break;
        case 'Today':
          DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
          filtered = filtered.where((plan) => 
              plan.plannedTime.isAfter(now) && 
              plan.plannedTime.isBefore(endOfDay)).toList();
          break;
        case 'This week':
          DateTime endOfWeek = now.add(Duration(days: 7 - now.weekday));
          filtered = filtered.where((plan) => 
              plan.plannedTime.isAfter(now) && 
              plan.plannedTime.isBefore(endOfWeek)).toList();
          break;
      }
    }
    
    // Cuisine filter
    if (_selectedCuisineFilter != 'All') {
      filtered = filtered.where((plan) {
        final restaurant = _restaurantCache[plan.restaurantId];
        return restaurant?.cuisineTypes.contains(_selectedCuisineFilter) ?? false;
      }).toList();
    }
    
    // Sort by planned time (soonest first)
    filtered.sort((a, b) => a.plannedTime.compareTo(b.plannedTime));
    
    setState(() {
      _filteredPlans = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Plans'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          if (_selectedTimeFilter != 'All' || _selectedCuisineFilter != 'All')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedTimeFilter != 'All')
                    FilterChip(
                      label: Text(_selectedTimeFilter),
                      onSelected: (bool selected) {
                        if (!selected) {
                          setState(() {
                            _selectedTimeFilter = 'All';
                          });
                          _applyFilters();
                        }
                      },
                      onDeleted: () {
                        setState(() {
                          _selectedTimeFilter = 'All';
                        });
                        _applyFilters();
                      },
                    ),
                  if (_selectedCuisineFilter != 'All')
                    FilterChip(
                      label: Text(_selectedCuisineFilter),
                      onSelected: (bool selected) {
                        if (!selected) {
                          setState(() {
                            _selectedCuisineFilter = 'All';
                          });
                          _applyFilters();
                        }
                      },
                      onDeleted: () {
                        setState(() {
                          _selectedCuisineFilter = 'All';
                        });
                        _applyFilters();
                      },
                    ),
                ],
              ),
            ),
          
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadOpenPlans,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Finding open dining plans...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOpenPlans,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_filteredPlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _allPlans.isEmpty 
                  ? 'No open plans available'
                  : 'No plans match your filters',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _allPlans.isEmpty
                  ? 'Be the first to create a dining plan!'
                  : 'Try adjusting your filters or check back later',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (_selectedTimeFilter != 'All' || _selectedCuisineFilter != 'All') ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedTimeFilter = 'All';
                    _selectedCuisineFilter = 'All';
                  });
                  _applyFilters();
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPlans.length,
      itemBuilder: (context, index) {
        return _buildPlanCard(_filteredPlans[index]);
      },
    );
  }

  Widget _buildPlanCard(DiningPlanModel plan) {
    final restaurant = _restaurantCache[plan.restaurantId];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlanDetailsScreen(
                plan: plan,
                restaurant: restaurant,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant info
              Row(
                children: [
                  // Restaurant image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: restaurant?.photoUrl != null
                          ? Image.network(
                              restaurant!.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.restaurant, size: 25);
                              },
                            )
                          : const Icon(Icons.restaurant, size: 25),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Restaurant details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant?.name ?? 'Loading...',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (restaurant != null) ...[
                          Text(
                            restaurant.cuisineTypes.join(', '),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.local_offer, color: Colors.green[700], size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${restaurant.discountPercentage.toInt()}% off',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Available spots
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Text(
                      '${plan.availableSpots} spots',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Plan details
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${plan.plannedTime.hour.toString().padLeft(2, '0')}:${plan.plannedTime.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${plan.plannedTime.day}/${plan.plannedTime.month}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.group, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${plan.memberIds.length}/${plan.maxMembers}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              
              if (plan.description != null && plan.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  plan.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Join button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showJoinDialog(plan),
                  icon: const Icon(Icons.add),
                  label: const Text('Request to Join'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Plans'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time filter
            Text(
              'Time',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedTimeFilter,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _timeFilters.map((filter) {
                return DropdownMenuItem(
                  value: filter,
                  child: Text(filter),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTimeFilter = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Cuisine filter
            Text(
              'Cuisine',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCuisineFilter,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _cuisineFilters.map((filter) {
                return DropdownMenuItem(
                  value: filter,
                  child: Text(filter),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCuisineFilter = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedTimeFilter = 'All';
                _selectedCuisineFilter = 'All';
              });
              Navigator.pop(context);
              _applyFilters();
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyFilters();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(DiningPlanModel plan) {
    final restaurant = _restaurantCache[plan.restaurantId];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Dining Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (restaurant != null) ...[
              Text(
                restaurant.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                restaurant.cuisineTypes.join(', '),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Time: ${plan.plannedTime.hour.toString().padLeft(2, '0')}:${plan.plannedTime.minute.toString().padLeft(2, '0')} on ${plan.plannedTime.day}/${plan.plannedTime.month}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Group size: ${plan.memberIds.length}/${plan.maxMembers} people',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (plan.description != null && plan.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Note: ${plan.description}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Join Request',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your request will be sent to the plan creator. You\'ll be notified when they respond.',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _requestToJoinPlan(plan);
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestToJoinPlan(DiningPlanModel plan) async {
    try {
      final success = await _diningPlanService.joinDiningPlan(plan.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Join request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOpenPlans(); // Refresh the list
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send join request. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}