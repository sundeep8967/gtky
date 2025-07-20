import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _companyController = TextEditingController();
  
  final List<String> _selectedFoodPreferences = [];
  bool _isLoading = false;
  bool _linkedInVerified = false;

  final List<String> _foodOptions = [
    'Vegetarian',
    'Vegan',
    'Non-Vegetarian',
    'Italian',
    'Chinese',
    'Indian',
    'Mexican',
    'Thai',
    'Japanese',
    'Mediterranean',
    'Fast Food',
    'Fine Dining',
    'Street Food',
    'Desserts',
    'Healthy',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      
      // Check if LinkedIn is already verified
      _linkedInVerified = await authService.isLinkedInVerified();
      setState(() {});
    }
  }

  Future<void> _connectLinkedIn() async {
    // TODO: Implement LinkedIn OAuth
    // For now, simulate LinkedIn connection
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('LinkedIn Integration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Company Name',
                hintText: 'Enter your company name',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'In production, this would connect to LinkedIn API to verify your company.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_companyController.text.isNotEmpty) {
                setState(() {
                  _linkedInVerified = true;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_linkedInVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your LinkedIn profile'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedFoodPreferences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one food preference'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = FirestoreService();
      final user = authService.currentUser!;

      final userModel = UserModel(
        id: user.uid,
        email: user.email!,
        name: _nameController.text,
        age: int.parse(_ageController.text),
        profilePhotoUrl: user.photoURL,
        company: _companyController.text,
        foodPreferences: _selectedFoodPreferences,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        isVerified: true,
      );

      await firestoreService.updateUser(userModel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing profile: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Let\'s set up your profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This information helps us match you with the right people',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Age field
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 18 || age > 100) {
                    return 'Please enter a valid age (18-100)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // LinkedIn verification
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _linkedInVerified ? Colors.green : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _linkedInVerified ? Icons.check_circle : Icons.business,
                      color: _linkedInVerified ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _linkedInVerified 
                                ? 'LinkedIn Verified' 
                                : 'Verify LinkedIn Profile',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _linkedInVerified 
                                ? 'Company: ${_companyController.text}'
                                : 'Required for company verification',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_linkedInVerified)
                      ElevatedButton(
                        onPressed: _connectLinkedIn,
                        child: const Text('Connect'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Food preferences
              const Text(
                'Food Preferences',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your food preferences (choose multiple)',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _foodOptions.map((food) {
                  final isSelected = _selectedFoodPreferences.contains(food);
                  return FilterChip(
                    label: Text(food),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedFoodPreferences.add(food);
                        } else {
                          _selectedFoodPreferences.remove(food);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Complete button
              ElevatedButton(
                onPressed: _isLoading ? null : _completeProfile,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Complete Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _companyController.dispose();
    super.dispose();
  }
}