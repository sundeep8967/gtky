import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/subscription_service.dart';
import '../../services/auth_service.dart';
import '../../models/subscription_model.dart';
import '../../widgets/brand_animation_presets.dart';
import '../../widgets/sound_effects.dart';
import '../../widgets/particle_animation.dart';
import '../../widgets/performance_optimizer.dart';
import '../../widgets/animated_premium_features.dart';
import '../../widgets/animated_pricing_card.dart';
import '../../widgets/enhanced_micro_interactions.dart';

class PremiumUpgradeScreen extends StatefulWidget {
  const PremiumUpgradeScreen({Key? key}) : super(key: key);

  @override
  State<PremiumUpgradeScreen> createState() => _PremiumUpgradeScreenState();
}

class _PremiumUpgradeScreenState extends State<PremiumUpgradeScreen> 
    with TickerProviderStateMixin {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = false;
  SubscriptionModel? _currentSubscription;
  late AnimationController _mainController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _mainController = PerformanceOptimizer.createOptimizedController(
      duration: GTKYAnimations.extraSlow,
      vsync: this,
    );
    _particleController = PerformanceOptimizer.createOptimizedController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _loadCurrentSubscription();
    _mainController.forward();
    if (PerformanceOptimizer.shouldEnableComplexAnimations()) {
      _particleController.repeat();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSubscription() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    
    if (currentUser != null) {
      final subscription = await _subscriptionService.getUserSubscription(currentUser.uid);
      if (mounted) {
        setState(() {
          _currentSubscription = subscription;
        });
      }
    }
  }

  Future<void> _upgradeToPremium() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Simulate payment process
      await _simulatePayment();
      
      // Create premium subscription
      await _subscriptionService.createPremiumSubscription(
        userId: currentUser.uid,
        paymentId: 'simulated_payment_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to GTKY Premium! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upgrade: ${e.toString()}'),
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

  Future<void> _simulatePayment() async {
    await Future.delayed(const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = _currentSubscription?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GTKY Premium'),
        backgroundColor: GTKYAnimations.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: PerformanceOptimizer.optimizeWidget(
        Stack(
          children: [
            // Background particle effect
            if (PerformanceOptimizer.shouldEnableComplexAnimations())
              ParticleSystem(
                particleCount: PerformanceOptimizer.getOptimizedParticleCount(20),
                particleColor: GTKYAnimations.primaryColor.withValues(alpha: 0.05),
                isActive: true,
                child: Container(),
              ),
            
            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GTKYAnimations.slideIn(
                controller: _mainController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium header with animation
                    GTKYAnimations.scaleWithGlow(
                      controller: _mainController,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [GTKYAnimations.primaryColor, GTKYAnimations.secondaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            GTKYAnimations.floating(
                              controller: _particleController,
                              amplitude: 5.0,
                              child: const Icon(
                                Icons.star,
                                size: 64,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GTKYAnimations.slideIn(
                              controller: _mainController,
                              delay: GTKYAnimations.fast,
                              child: const Text(
                                'GTKY Premium',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GTKYAnimations.slideIn(
                              controller: _mainController,
                              delay: GTKYAnimations.medium,
                              child: Text(
                                'Unlock the full potential of professional networking',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Features with animation
                    GTKYAnimations.slideIn(
                      controller: _mainController,
                      delay: GTKYAnimations.slow,
                      child: const Text(
                        'Premium Features',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: GTKYAnimations.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    AnimatedPremiumFeatures(
                      features: GTKYPremiumFeatures.features,
                      isPremium: isPremium,
                    ),

                    const SizedBox(height: 32),

                    // Pricing with animation
                    if (!isPremium) ...[
                      GTKYAnimations.slideIn(
                        controller: _mainController,
                        delay: const Duration(milliseconds: 1200),
                        child: PricingPlansWidget(
                          onUpgrade: _upgradeToPremium,
                          isLoading: _isLoading,
                        ),
                      ),
                    ],

                    // Manage subscription button for premium users
                    if (isPremium) ...[
                      const SizedBox(height: 24),
                      GTKYAnimations.slideIn(
                        controller: _mainController,
                        delay: const Duration(milliseconds: 800),
                        child: SizedBox(
                          width: double.infinity,
                          child: EnhancedButton(
                            style: GTKYButtonStyle.outline,
                            onPressed: () {
                              SoundEffects.playTap();
                              Navigator.pushNamed(context, '/subscription-management');
                            },
                            child: const Text(
                              'Manage Subscription',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}