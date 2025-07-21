import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dining_plan_model.dart';
import '../../models/restaurant_model.dart';
import '../../services/dining_plan_service.dart';
import '../../services/auth_service.dart';
import '../../services/arrival_status_service.dart';

class ArrivalVerificationScreen extends StatefulWidget {
  final DiningPlanModel plan;
  final RestaurantModel? restaurant;

  const ArrivalVerificationScreen({
    super.key,
    required this.plan,
    this.restaurant,
  });

  @override
  State<ArrivalVerificationScreen> createState() => _ArrivalVerificationScreenState();
}

class _ArrivalVerificationScreenState extends State<ArrivalVerificationScreen> {
  final DiningPlanService _diningPlanService = DiningPlanService();
  // final ArrivalStatusService _arrivalStatusService = ArrivalStatusService();
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('User not authenticated')),
      );
    }

    final userCode = widget.plan.memberCodes?[currentUser.uid];
    final hasArrived = widget.plan.arrivedMemberIds?.contains(currentUser.uid) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrival Verification'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRestaurantInfo(),
            const SizedBox(height: 24),
            _buildPlanInfo(),
            const SizedBox(height: 24),
            _buildCodeSection(userCode, hasArrived),
            const SizedBox(height: 24),
            _buildArrivalSection(hasArrived),
            const SizedBox(height: 24),
            _buildGroupStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restaurant',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (widget.restaurant != null) ...[
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: widget.restaurant!.photoUrl != null
                          ? Image.network(
                              widget.restaurant!.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.restaurant, size: 25);
                              },
                            )
                          : const Icon(Icons.restaurant, size: 25),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.restaurant!.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.restaurant!.address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.restaurant!.address,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Text('Restaurant information not available'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dining Plan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  'Time: ${widget.plan.plannedTime.hour.toString().padLeft(2, '0')}:${widget.plan.plannedTime.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.group, color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  'Group: ${widget.plan.memberIds.length} people',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeSection(String? userCode, bool hasArrived) {
    return Card(
      color: hasArrived ? Colors.green[50] : Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasArrived ? Icons.check_circle : Icons.qr_code,
                  color: hasArrived ? Colors.green[700] : Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Text(
                  hasArrived ? 'Arrival Confirmed' : 'Your Verification Code',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: hasArrived ? Colors.green[700] : Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (userCode != null) ...[
              // QR Code and Code Display Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: hasArrived ? Colors.green[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasArrived ? Colors.green[200]! : Colors.blue[200]!,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      hasArrived ? 'Verified!' : 'Your Verification Code',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: hasArrived ? Colors.green[700] : Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    if (!hasArrived) ...[
                      // QR Code Display
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[300]!),
                        ),
                        child: Column(
                          children: [
                            // QR Code placeholder (in real implementation, use qr_flutter package)
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.black, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.qr_code,
                                      size: 60,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      userCode,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Scan QR Code',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Manual code display
                      Text(
                        'OR show this code:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.blue[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Code display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: hasArrived ? Colors.green[100] : Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasArrived ? Colors.green[300]! : Colors.blue[300]!,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        userCode,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: hasArrived ? Colors.green[700] : Colors.blue[700],
                          letterSpacing: 8,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      hasArrived 
                          ? 'You have successfully checked in at the restaurant!'
                          : 'Show this to restaurant staff for verification',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasArrived ? Colors.green[700] : Colors.blue[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    if (hasArrived) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.savings, color: Colors.green[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'You\'ll save 15% on your bill!',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Text(
                'Verification code will be available when your group is complete.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildArrivalSection(bool hasArrived) {
    if (hasArrived) {
      return Card(
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You have confirmed your arrival at the restaurant.',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm Arrival',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Once you arrive at the restaurant and show your code to the staff, confirm your arrival here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isConfirming ? null : _confirmArrival,
                icon: _isConfirming 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.location_on),
                label: Text(_isConfirming ? 'Confirming...' : 'Confirm Arrival'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupStatus() {
    final arrivedCount = widget.plan.arrivedMemberIds?.length ?? 0;
    final totalMembers = widget.plan.memberIds.length;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.people, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '$arrivedCount of $totalMembers members have arrived',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            LinearProgressIndicator(
              value: totalMembers > 0 ? arrivedCount / totalMembers : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                arrivedCount == totalMembers ? Colors.green : Colors.blue,
              ),
            ),
            
            if (arrivedCount == totalMembers) ...[
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
                        'All members have arrived! Enjoy your meal with the GTKY discount.',
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

  Future<void> _confirmArrival() async {
    setState(() {
      _isConfirming = true;
    });

    try {
      final success = await _diningPlanService.confirmArrival(widget.plan.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arrival confirmed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to previous screen
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to confirm arrival. Please try again.'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }
}