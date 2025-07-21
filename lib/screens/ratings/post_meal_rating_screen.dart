import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dining_plan_model.dart';
import '../../models/restaurant_model.dart';
import '../../models/user_model.dart';
import '../../services/rating_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class PostMealRatingScreen extends StatefulWidget {
  final DiningPlanModel plan;
  final RestaurantModel restaurant;

  const PostMealRatingScreen({
    super.key,
    required this.plan,
    required this.restaurant,
  });

  @override
  State<PostMealRatingScreen> createState() => _PostMealRatingScreenState();
}

class _PostMealRatingScreenState extends State<PostMealRatingScreen> {
  final RatingService _ratingService = RatingService();
  final FirestoreService _firestoreService = FirestoreService();
  final PageController _pageController = PageController();
  
  int _currentPage = 0;
  int _restaurantRating = 0;
  String _restaurantComment = '';
  List<String> _restaurantTags = [];
  
  Map<String, int> _userRatings = {};
  Map<String, String> _userComments = {};
  List<UserModel> _groupMembers = [];
  
  bool _isSubmitting = false;

  final List<String> _availableTags = [
    'Great food',
    'Excellent service',
    'Good ambiance',
    'Value for money',
    'Quick service',
    'Clean restaurant',
    'Friendly staff',
    'Good portions',
    'Fresh ingredients',
    'Would recommend',
  ];

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
  }

  Future<void> _loadGroupMembers() async {
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
    if (currentUser == null) return;

    List<UserModel> members = [];
    for (String memberId in widget.plan.memberIds) {
      if (memberId != currentUser.uid) { // Exclude current user
        final user = await _firestoreService.getUser(memberId);
        if (user != null) {
          members.add(user);
        }
      }
    }
    
    setState(() {
      _groupMembers = members;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Your Experience'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
        },
        children: [
          _buildRestaurantRatingPage(),
          _buildUserRatingPage(),
          _buildSummaryPage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildRestaurantRatingPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          const SizedBox(height: 24),
          
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
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.restaurant, size: 30),
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
                        Text(
                          widget.restaurant.address,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'How was your dining experience?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Star rating
          _buildStarRating(),
          
          const SizedBox(height: 24),
          
          // Tags selection
          Text(
            'What did you like? (Optional)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildTagSelection(),
          
          const SizedBox(height: 24),
          
          // Comment
          Text(
            'Additional comments (Optional)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Share your thoughts about the restaurant...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _restaurantComment = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserRatingPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          const SizedBox(height: 24),
          
          Text(
            'Rate Your Dining Companions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Help build a trustworthy community (Optional & Anonymous)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (_groupMembers.isEmpty) ...[
            const Center(
              child: Text('No other members to rate'),
            ),
          ] else ...[
            ..._groupMembers.map((member) => _buildUserRatingCard(member)),
          ],
        ],
      ),
    );
  }

  Widget _buildUserRatingCard(UserModel user) {
    final rating = _userRatings[user.id] ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: user.profilePhotoUrl != null
                      ? NetworkImage(user.profilePhotoUrl!)
                      : null,
                  child: user.profilePhotoUrl == null
                      ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U')
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.company,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Star rating for user
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _userRatings[user.id] = index + 1;
                    });
                  },
                  child: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
            
            if (rating > 0) ...[
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Optional comment (anonymous)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _userComments[user.id] = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          const SizedBox(height: 24),
          
          Text(
            'Review Your Ratings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Restaurant rating summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Restaurant Rating',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(widget.restaurant.name),
                      const Spacer(),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < _restaurantRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ),
                    ],
                  ),
                  if (_restaurantTags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _restaurantTags.map((tag) => Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // User ratings summary
          if (_userRatings.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Companion Ratings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_userRatings.length} companion(s) rated',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRatings,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Submit Ratings'),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Thank you for helping improve the GTKY community!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: index <= _currentPage ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStarRating() {
    return Row(
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _restaurantRating = index + 1;
            });
          },
          child: Icon(
            index < _restaurantRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 40,
          ),
        );
      }),
    );
  }

  Widget _buildTagSelection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableTags.map((tag) {
        final isSelected = _restaurantTags.contains(tag);
        return FilterChip(
          label: Text(tag),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _restaurantTags.add(tag);
              } else {
                _restaurantTags.remove(tag);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('Previous'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentPage < 2 ? () {
                if (_currentPage == 0 && _restaurantRating == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please rate the restaurant')),
                  );
                  return;
                }
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } : null,
              child: Text(_currentPage < 2 ? 'Next' : 'Complete'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRatings() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Submit restaurant rating
      if (_restaurantRating > 0) {
        await _ratingService.submitRestaurantRating(
          restaurantId: widget.restaurant.id,
          rating: _restaurantRating,
          comment: _restaurantComment.isNotEmpty ? _restaurantComment : null,
          tags: _restaurantTags,
          planId: widget.plan.id,
        );
      }

      // Submit user ratings
      for (final entry in _userRatings.entries) {
        if (entry.value > 0) {
          await _ratingService.submitUserRating(
            ratedUserId: entry.key,
            rating: entry.value,
            comment: _userComments[entry.key],
            planId: widget.plan.id,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ratings submitted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting ratings: $e')),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}