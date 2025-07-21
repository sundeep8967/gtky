import 'package:flutter/material.dart';
import 'brand_animation_presets.dart';
import 'enhanced_micro_interactions.dart';
import 'sound_effects.dart';
import 'performance_optimizer.dart';
import 'particle_animation.dart';

class AnimatedPricingCard extends StatefulWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final VoidCallback? onUpgrade;
  final bool isLoading;
  final bool isPopular;

  const AnimatedPricingCard({
    super.key,
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    this.onUpgrade,
    this.isLoading = false,
    this.isPopular = false,
  });

  @override
  State<AnimatedPricingCard> createState() => _AnimatedPricingCardState();
}

class _AnimatedPricingCardState extends State<AnimatedPricingCard>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _mainController = PerformanceOptimizer.createOptimizedController(
      duration: GTKYAnimations.slow,
      vsync: this,
    );
    
    _particleController = PerformanceOptimizer.createOptimizedController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _pulseController = PerformanceOptimizer.createOptimizedController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: GTKYAnimations.brandBounce,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: GTKYAnimations.brandEaseOut,
    ));

    _startAnimations();
  }

  void _startAnimations() {
    _mainController.forward();
    if (widget.isPopular && PerformanceOptimizer.shouldEnableComplexAnimations()) {
      _particleController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Stack(
            children: [
              // Particle effect for popular plan
              if (widget.isPopular && PerformanceOptimizer.shouldEnableComplexAnimations())
                Positioned.fill(
                  child: ParticleSystem(
                    particleCount: PerformanceOptimizer.getOptimizedParticleCount(10),
                    particleColor: GTKYAnimations.primaryColor.withValues(alpha: 0.3),
                    isActive: true,
                    child: Container(),
                  ),
                ),
              
              // Main card
              _buildPricingCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPricingCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: widget.isPopular
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  GTKYAnimations.primaryColor,
                  GTKYAnimations.secondaryColor,
                ],
              )
            : null,
        color: widget.isPopular ? null : Colors.white,
        border: widget.isPopular 
            ? null 
            : Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: widget.isPopular 
                ? GTKYAnimations.primaryColor.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: widget.isPopular ? 20 : 10,
            spreadRadius: widget.isPopular ? 5 : 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Popular badge
          if (widget.isPopular)
            Positioned(
              top: -10,
              left: 0,
              right: 0,
              child: Center(
                child: GTKYAnimations.pulse(
                  controller: _pulseController,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Text(
                      'MOST POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Card content
          Padding(
            padding: EdgeInsets.all(widget.isPopular ? 24 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isPopular) const SizedBox(height: 20),
                
                // Title
                GTKYAnimations.slideIn(
                  controller: _mainController,
                  delay: GTKYAnimations.fast,
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: widget.isPopular ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Price
                GTKYAnimations.slideIn(
                  controller: _mainController,
                  delay: GTKYAnimations.medium,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.price,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: widget.isPopular ? Colors.white : GTKYAnimations.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          widget.period,
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.isPopular 
                                ? Colors.white.withValues(alpha: 0.8)
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Features
                ...List.generate(widget.features.length, (index) {
                  return GTKYAnimations.slideIn(
                    controller: _mainController,
                    delay: Duration(milliseconds: 400 + (index * 100)),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: widget.isPopular ? Colors.white : Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.features[index],
                              style: TextStyle(
                                fontSize: 16,
                                color: widget.isPopular 
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                
                const SizedBox(height: 32),
                
                // Upgrade button
                GTKYAnimations.slideIn(
                  controller: _mainController,
                  delay: Duration(milliseconds: 600 + (widget.features.length * 100)),
                  child: SizedBox(
                    width: double.infinity,
                    child: EnhancedButton(
                      onPressed: widget.onUpgrade,
                      isLoading: widget.isLoading,
                      style: widget.isPopular ? GTKYButtonStyle.accent : GTKYButtonStyle.primary,
                      backgroundColor: widget.isPopular ? Colors.white : null,
                      foregroundColor: widget.isPopular ? GTKYAnimations.primaryColor : null,
                      enableGlow: true,
                      child: Text(
                        widget.isLoading ? 'Processing...' : 'Upgrade Now',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Terms
                GTKYAnimations.slideIn(
                  controller: _mainController,
                  delay: Duration(milliseconds: 700 + (widget.features.length * 100)),
                  child: Text(
                    'Cancel anytime. No hidden fees.',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isPopular 
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PricingPlansWidget extends StatefulWidget {
  final VoidCallback? onUpgrade;
  final bool isLoading;

  const PricingPlansWidget({
    super.key,
    this.onUpgrade,
    this.isLoading = false,
  });

  @override
  State<PricingPlansWidget> createState() => _PricingPlansWidgetState();
}

class _PricingPlansWidgetState extends State<PricingPlansWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PerformanceOptimizer.createOptimizedController(
      duration: GTKYAnimations.extraSlow,
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Monthly plan
        AnimatedPricingCard(
          title: 'Premium Monthly',
          price: '\$9.99',
          period: '/month',
          features: const [
            'Unlimited dining plans',
            'Priority matching',
            'Advanced filters',
            'Exclusive events',
            'Analytics dashboard',
            '24/7 support',
          ],
          onUpgrade: widget.onUpgrade,
          isLoading: widget.isLoading,
          isPopular: true,
        ),
        
        const SizedBox(height: 24),
        
        // Annual plan
        AnimatedPricingCard(
          title: 'Premium Annual',
          price: '\$99.99',
          period: '/year',
          features: const [
            'Everything in Monthly',
            '2 months free',
            'Priority event access',
            'Personal networking coach',
            'Custom branding',
            'API access',
          ],
          onUpgrade: () {
            SoundEffects.playSuccess();
            widget.onUpgrade?.call();
          },
          isLoading: widget.isLoading,
        ),
      ],
    );
  }
}