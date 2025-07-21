import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/slide_fade_transition.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/success_animation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _showSuccess = false;
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.signInWithGoogle();

      if (result != null) {
        // Show success animation
        setState(() {
          _showSuccess = true;
        });
        await Future.delayed(const Duration(milliseconds: 1500));
      } else if (result == null) {
        // User cancelled sign-in
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign-in was cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: $e'),
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
    if (_showSuccess) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SuccessAnimation(
                size: 120,
                onComplete: () {
                  // Navigation will be handled by AuthWrapper
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to GTKY!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B73FF),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo and title with animation
              SlideFadeTransition(
                delay: const Duration(milliseconds: 200),
                child: AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoAnimation.value,
                      child: const Icon(
                        Icons.restaurant_menu,
                        size: 80,
                        color: Color(0xFF6B73FF),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SlideFadeTransition(
                delay: const Duration(milliseconds: 400),
                child: const Text(
                  'GTKY',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B73FF),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              SlideFadeTransition(
                delay: const Duration(milliseconds: 600),
                child: const Text(
                  'Get To Know You',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              
              // Description
              SlideFadeTransition(
                delay: const Duration(milliseconds: 800),
                child: const Text(
                  'Connect with professionals from different companies over shared meals',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              
              // Features list
              SlideFadeTransition(
                delay: const Duration(milliseconds: 1000),
                child: _buildFeatureItem(
                  Icons.people_outline,
                  'Cross-company networking',
                ),
              ),
              const SizedBox(height: 16),
              SlideFadeTransition(
                delay: const Duration(milliseconds: 1200),
                child: _buildFeatureItem(
                  Icons.restaurant,
                  '15% discount at partner restaurants',
                ),
              ),
              const SizedBox(height: 16),
              SlideFadeTransition(
                delay: const Duration(milliseconds: 1400),
                child: _buildFeatureItem(
                  Icons.verified_user,
                  'Verified professionals only',
                ),
              ),
              const SizedBox(height: 48),
              
              // Sign in button
              SlideFadeTransition(
                delay: const Duration(milliseconds: 1600),
                child: AnimatedButton(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  isLoading: _isLoading,
                  backgroundColor: const Color(0xFF6B73FF),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_isLoading)
                        Image.asset(
                          'assets/google_logo.png',
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.login, color: Colors.white),
                        ),
                      if (!_isLoading) const SizedBox(width: 12),
                      Text(
                        _isLoading ? 'Signing in...' : 'Continue with Google',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Terms and privacy
              SlideFadeTransition(
                delay: const Duration(milliseconds: 1800),
                child: const Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF6B73FF),
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}