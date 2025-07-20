import 'package:flutter/material.dart';
import '../../models/dining_plan_model.dart';
import '../../models/restaurant_model.dart';
import '../../services/dining_plan_service.dart';
import '../../services/restaurant_service.dart';

class RestaurantStaffScreen extends StatefulWidget {
  const RestaurantStaffScreen({super.key});

  @override
  State<RestaurantStaffScreen> createState() => _RestaurantStaffScreenState();
}

class _RestaurantStaffScreenState extends State<RestaurantStaffScreen> {
  final DiningPlanService _diningPlanService = DiningPlanService();
  final RestaurantService _restaurantService = RestaurantService();
  final TextEditingController _codeController = TextEditingController();
  
  List<DiningPlanModel> _activePlans = [];
  bool _isLoading = true;
  String _selectedRestaurantId = '';
  List<RestaurantModel> _restaurants = [];

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    try {
      final restaurants = await _restaurantService.getAllPartnerRestaurants();
      setState(() {
        _restaurants = restaurants;
        if (restaurants.isNotEmpty) {
          _selectedRestaurantId = restaurants.first.id;
        }
        _isLoading = false;
      });
      if (_selectedRestaurantId.isNotEmpty) {
        _loadActivePlans();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadActivePlans() async {
    if (_selectedRestaurantId.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final plans = await _diningPlanService.getActivePlansForRestaurant(_selectedRestaurantId);
      setState(() {
        _activePlans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Staff Portal'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          _buildRestaurantSelector(),
          _buildCodeVerificationSection(),
          const Divider(),
          Expanded(child: _buildActivePlansSection()),
        ],
      ),
    );
  }

  Widget _buildRestaurantSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Restaurant',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedRestaurantId.isEmpty ? null : _selectedRestaurantId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _restaurants.map((restaurant) {
              return DropdownMenuItem(
                value: restaurant.id,
                child: Text(restaurant.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedRestaurantId = value ?? '';
              });
              _loadActivePlans();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCodeVerificationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify Customer Code',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Enter 2-digit code',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. 42',
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _verifyCode,
                    child: const Text('Verify'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivePlansSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activePlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No active GTKY plans',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Active dining plans will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Active GTKY Plans (${_activePlans.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _activePlans.length,
            itemBuilder: (context, index) {
              return _buildPlanCard(_activePlans[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(DiningPlanModel plan) {
    final arrivedCount = plan.arrivedMemberIds?.length ?? 0;
    final totalMembers = plan.memberIds.length;
    final isCompleted = arrivedCount == totalMembers;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Plan ${plan.id.substring(0, 8)}...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCompleted ? Colors.green[200]! : Colors.orange[200]!,
                    ),
                  ),
                  child: Text(
                    isCompleted ? 'All Arrived' : 'In Progress',
                    style: TextStyle(
                      color: isCompleted ? Colors.green[700] : Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${plan.plannedTime.hour.toString().padLeft(2, '0')}:${plan.plannedTime.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                Icon(Icons.group, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '$arrivedCount/$totalMembers arrived',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            if (plan.memberCodes != null) ...[
              Text(
                'Customer Codes:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: plan.memberCodes!.entries.map((entry) {
                  final hasArrived = plan.arrivedMemberIds?.contains(entry.key) ?? false;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasArrived ? Colors.green[100] : Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasArrived ? Colors.green[300]! : Colors.blue[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.value,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: hasArrived ? Colors.green[700] : Colors.blue[700],
                          ),
                        ),
                        if (hasArrived) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green[700],
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            
            if (isCompleted) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All customers arrived! Apply 15% GTKY discount.',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 2) {
      _showMessage('Please enter a 2-digit code', isError: true);
      return;
    }

    // Find the plan with this code
    DiningPlanModel? matchingPlan;
    String? userId;
    
    for (var plan in _activePlans) {
      if (plan.memberCodes != null) {
        for (var entry in plan.memberCodes!.entries) {
          if (entry.value == code) {
            matchingPlan = plan;
            userId = entry.key;
            break;
          }
        }
      }
      if (matchingPlan != null) break;
    }

    if (matchingPlan == null) {
      _showMessage('Code not found. Please check the code and try again.', isError: true);
      return;
    }

    // Check if user already arrived
    if (matchingPlan.arrivedMemberIds?.contains(userId) ?? false) {
      _showMessage('This customer has already been verified.', isError: true);
      return;
    }

    // Mark user as arrived
    final success = await _diningPlanService.markUserArrived(matchingPlan.id, userId!);
    
    if (success) {
      _showMessage('Customer verified successfully!');
      _codeController.clear();
      _loadActivePlans(); // Refresh the list
    } else {
      _showMessage('Failed to verify customer. Please try again.', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}