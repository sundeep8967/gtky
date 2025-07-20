import 'package:flutter/material.dart';
import '../../models/restaurant_model.dart';
import '../../services/dining_plan_service.dart';

class CreatePlanScreen extends StatefulWidget {
  final RestaurantModel restaurant;

  const CreatePlanScreen({
    super.key,
    required this.restaurant,
  });

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final DiningPlanService _diningPlanService = DiningPlanService();
  final TextEditingController _descriptionController = TextEditingController();
  
  DateTime? _selectedTime;
  int _maxMembers = 4;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Set default time to 1 hour from now
    _selectedTime = DateTime.now().add(const Duration(hours: 1));
  }

  Future<void> _selectTime() async {
    final DateTime now = DateTime.now();
    final DateTime minTime = now.add(const Duration(minutes: 30));
    final DateTime maxTime = now.add(const Duration(hours: 2));

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime ?? minTime),
    );

    if (pickedTime != null) {
      final DateTime selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // Validate time range
      if (selectedDateTime.isBefore(minTime)) {
        _showErrorDialog('Please select a time at least 30 minutes from now');
        return;
      }

      if (selectedDateTime.isAfter(maxTime)) {
        _showErrorDialog('Please select a time within 2 hours from now');
        return;
      }

      setState(() {
        _selectedTime = selectedDateTime;
      });
    }
  }

  Future<void> _createPlan() async {
    if (_selectedTime == null) {
      _showErrorDialog('Please select a time for your dining plan');
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      String? planId = await _diningPlanService.createDiningPlan(
        restaurantId: widget.restaurant.id,
        plannedTime: _selectedTime!,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        maxMembers: _maxMembers,
      );

      if (planId != null) {
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dining plan created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showErrorDialog('Failed to create dining plan. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Error creating plan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Dining Plan'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: widget.restaurant.photoUrl != null
                            ? Image.network(
                                widget.restaurant.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.restaurant, size: 30);
                                },
                              )
                            : const Icon(Icons.restaurant, size: 30),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.restaurant.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.restaurant.cuisineTypes.join(', '),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.local_offer, color: Colors.green[700], size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.restaurant.discountPercentage.toInt()}% discount',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Time selection
            Text(
              'When would you like to dine?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a time between 30 minutes and 2 hours from now',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            
            InkWell(
              onTap: _selectTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _selectedTime != null
                            ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                            : 'Select time',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Group size
            Text(
              'Maximum group size',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                for (int i = 2; i <= 4; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 4 ? 8 : 0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _maxMembers = i;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _maxMembers == i
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _maxMembers == i
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            '$i people',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _maxMembers == i
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Description (optional)
            Text(
              'Description (optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add any special notes or preferences...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createPlan,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Create Dining Plan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'How it works',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• You\'ll be matched with people from different companies\n'
                    '• Everyone gets a 15% discount at this partner restaurant\n'
                    '• You\'ll receive a unique code to verify your arrival\n'
                    '• Plans are automatically matched based on time and location',
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
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}