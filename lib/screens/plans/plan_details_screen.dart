import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dining_plan_model.dart';
import '../../models/restaurant_model.dart';
import '../../models/user_model.dart';
import '../../services/dining_plan_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/rating_service.dart';
import '../../services/safety_service.dart';
import 'arrival_verification_screen.dart';
import '../ratings/post_meal_rating_screen.dart';
import '../safety/report_user_screen.dart';

class PlanDetailsScreen extends StatefulWidget {
  final DiningPlanModel plan;
  final RestaurantModel? restaurant;

  const PlanDetailsScreen({
    super.key,
    required this.plan,
    this.restaurant,
  });

  @override
  State<PlanDetailsScreen> createState() => _PlanDetailsScreenState();
}

class _PlanDetailsScreenState extends State<PlanDetailsScreen> {
  final DiningPlanService _diningPlanService = DiningPlanService();
  final FirestoreService _firestoreService = FirestoreService();
  final RatingService _ratingService = RatingService();
  final SafetyService _safetyService = SafetyService();
  
  List<UserModel> _planMembers = [];
  bool _isLoading = true;
  bool _isJoining = false;
  bool _hasRatedRestaurant = false;

  @override
  void initState() {
    super.initState();
    _loadPlanMembers();
    _checkRatingStatus();
  }

  Future<void> _checkRatingStatus() async {
    if (widget.restaurant != null) {
      final hasRated = await _ratingService.hasUserRatedRestaurant(
        widget.restaurant!.id,
        widget.plan.id,
      );
      setState(() {
        _hasRatedRestaurant = hasRated;
      });
    }
  }

  Future<void> _loadPlanMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final members = <UserModel>[];
      for (String memberId in widget.plan.memberIds) {
        final userDoc = await _firestoreService.getUser(memberId);
        if (userDoc != null) {
          final userData = userDoc as Map<String, dynamic>;
          userData['id'] = memberId;
          final user = UserModel.fromJson(userData);
          members.add(user);
        }
      }
      
      setState(() {
        _planMembers = members;
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
        title: const Text('Plan Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRestaurantSection(),
            const SizedBox(height: 24),
            _buildPlanDetailsSection(),
            const SizedBox(height: 24),
            if (widget.plan.memberCodes != null) ...[
              _buildCodeSection(),
              const SizedBox(height: 24),
            ],
            _buildMembersSection(),
            const SizedBox(height: 24),
            _buildActionSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantSection() {
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
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: widget.restaurant!.photoUrl != null
                          ? Image.network(
                              widget.restaurant!.photoUrl!,
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
                          widget.restaurant!.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.restaurant!.cuisineTypes.join(', '),
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
                              '${widget.restaurant!.discountPercentage.toInt()}% GTKY discount',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              if (widget.restaurant!.address.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.restaurant!.address,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              const Text('Restaurant information not available'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildDetailRow(
              Icons.access_time,
              'Time',
              '${widget.plan.plannedTime.hour.toString().padLeft(2, '0')}:${widget.plan.plannedTime.minute.toString().padLeft(2, '0')}',
            ),
            
            _buildDetailRow(
              Icons.calendar_today,
              'Date',
              '${widget.plan.plannedTime.day}/${widget.plan.plannedTime.month}/${widget.plan.plannedTime.year}',
            ),
            
            _buildDetailRow(
              Icons.group,
              'Group Size',
              '${widget.plan.memberIds.length}/${widget.plan.maxMembers} people',
            ),
            
            _buildDetailRow(
              Icons.info_outline,
              'Status',
              widget.plan.status.toString().split('.').last.toUpperCase(),
            ),
            
            if (widget.plan.description != null && widget.plan.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.note,
                'Description',
                widget.plan.description!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Members (${widget.plan.memberIds.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (_planMembers.isEmpty) ...[
              const Text('No member information available'),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _planMembers.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final member = _planMembers[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: member.profilePhotoUrl != null 
                          ? NetworkImage(member.profilePhotoUrl!)
                          : null,
                      child: member.profilePhotoUrl == null 
                          ? Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?')
                          : null,
                    ),
                    title: Row(
                      children: [
                        Text(member.name),
                        if (member.isPremium) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber[600],
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(member.company),
                    onTap: () => _showMemberActions(member),
                    trailing: index == 0 
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Text(
                              'Creator',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCodeSection() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    
    if (currentUser == null || widget.plan.memberCodes == null) {
      return const SizedBox.shrink();
    }

    final userCode = widget.plan.memberCodes![currentUser.uid];
    final hasArrived = widget.plan.arrivedMemberIds?.contains(currentUser.uid) ?? false;
    final isUserInPlan = widget.plan.memberIds.contains(currentUser.uid);

    if (!isUserInPlan || userCode == null) {
      return const SizedBox.shrink();
    }

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
            
            Center(
              child: Container(
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
            ),
            const SizedBox(height: 12),
            
            Text(
              hasArrived 
                  ? 'You have successfully checked in!'
                  : 'Show this code to restaurant staff when you arrive.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: hasArrived ? Colors.green[700] : Colors.blue[700],
              ),
              textAlign: TextAlign.center,
            ),
            
            if (!hasArrived) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArrivalVerificationScreen(
                          plan: widget.plan,
                          restaurant: widget.restaurant,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text('Verify Arrival'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            
            // Show rating button if plan is completed and user hasn't rated yet
            if (widget.plan.status == PlanStatus.completed && 
                widget.restaurant != null && 
                !_hasRatedRestaurant) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostMealRatingScreen(
                          plan: widget.plan,
                          restaurant: widget.restaurant!,
                        ),
                      ),
                    );
                    if (result == true) {
                      _checkRatingStatus(); // Refresh rating status
                    }
                  },
                  icon: const Icon(Icons.star),
                  label: const Text('Rate Your Experience'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            
            // Show thank you message if already rated
            if (widget.plan.status == PlanStatus.completed && _hasRatedRestaurant) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Thank you for rating your experience!',
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

  Widget _buildActionSection() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    
    if (currentUser == null) {
      return const SizedBox.shrink();
    }
    
    final isCurrentUserInPlan = widget.plan.memberIds.contains(currentUser.uid);
    final canJoin = !isCurrentUserInPlan && 
                   widget.plan.status == PlanStatus.open && 
                   widget.plan.availableSpots > 0;
    
    if (isCurrentUserInPlan) {
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
                  'You are already part of this plan',
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
    
    if (!canJoin) {
      return Card(
        color: Colors.grey[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.plan.availableSpots == 0 
                      ? 'This plan is full'
                      : 'This plan is no longer accepting new members',
                  style: TextStyle(
                    color: Colors.grey[600],
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
              'Join This Plan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a request to join this dining plan. The plan creator will be notified and can accept or decline your request.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isJoining ? null : _requestToJoin,
                icon: _isJoining 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_isJoining ? 'Sending Request...' : 'Request to Join'),
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

  Future<void> _requestToJoin() async {
    setState(() {
      _isJoining = true;
    });

    try {
      final success = await _diningPlanService.joinDiningPlan(widget.plan.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Join request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to discovery screen
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
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _showMemberActions(UserModel member) async {
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
    if (currentUser == null || member.id == currentUser.uid) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: member.profilePhotoUrl != null
                    ? NetworkImage(member.profilePhotoUrl!)
                    : null,
                child: member.profilePhotoUrl == null
                    ? Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?')
                    : null,
              ),
              title: Text(member.name),
              subtitle: Text(member.company),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('Report User'),
              subtitle: const Text('Report inappropriate behavior'),
              onTap: () {
                Navigator.pop(context);
                _reportUser(member);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.orange),
              title: const Text('Block User'),
              subtitle: const Text('Block this user from future interactions'),
              onTap: () {
                Navigator.pop(context);
                _blockUser(member);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportUser(UserModel user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportUserScreen(reportedUser: user),
      ),
    );
    
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your report. We take safety seriously.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _blockUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block ${user.name}? You won\'t see their dining plans or be matched with them in the future.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
        if (currentUser != null) {
          await _safetyService.blockUser(
            blockerId: currentUser.uid,
            blockedUserId: user.id,
            reason: 'Blocked from dining plan',
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.name} has been blocked'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to block user: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}