import 'package:flutter/material.dart';
import 'brand_animation_presets.dart';
import 'enhanced_micro_interactions.dart';
import 'sound_effects.dart';
import 'performance_optimizer.dart';

class AnimatedPremiumFeatures extends StatefulWidget {
  final List<PremiumFeature> features;
  final bool isPremium;

  const AnimatedPremiumFeatures({
    super.key,
    required this.features,
    this.isPremium = false,
  });

  @override
  State<AnimatedPremiumFeatures> createState() => _AnimatedPremiumFeaturesState();
}

class _AnimatedPremiumFeaturesState extends State<AnimatedPremiumFeatures>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late List<AnimationController> _featureControllers;

  @override
  void initState() {
    super.initState();
    
    _mainController = PerformanceOptimizer.createOptimizedController(
      duration: GTKYAnimations.extraSlow,
      vsync: this,
    );

    _featureControllers = List.generate(
      widget.features.length,
      (index) => PerformanceOptimizer.createOptimizedController(
        duration: GTKYAnimations.medium,
        vsync: this,
      ),
    );

    _startAnimations();
  }

  void _startAnimations() {
    _mainController.forward();
    
    for (int i = 0; i < _featureControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 200 + (i * 150)), () {
        if (mounted) {
          _featureControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    for (var controller in _featureControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.features.length, (index) {
        return GTKYAnimations.slideIn(
          controller: _featureControllers[index],
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildFeatureCard(widget.features[index], index),
          ),
        );
      }),
    );
  }

  Widget _buildFeatureCard(PremiumFeature feature, int index) {
    return EnhancedCard(
      onTap: () {
        SoundEffects.playSelection();
        _showFeatureDetails(feature);
      },
      child: Row(
        children: [
          // Icon with glow effect
          GTKYAnimations.scaleWithGlow(
            controller: _featureControllers[index],
            glowColor: feature.color,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: feature.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                feature.icon,
                color: feature.color,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        feature.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (widget.isPremium || feature.isAvailable)
                      GTKYAnimations.pulse(
                        controller: _featureControllers[index],
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                      )
                    else
                      Icon(
                        Icons.lock,
                        color: Colors.grey,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  feature.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (feature.badge != null) ...[
                  const SizedBox(height: 8),
                  GTKYAnimations.floating(
                    controller: _featureControllers[index],
                    amplitude: 2.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: feature.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: feature.color.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        feature.badge!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: feature.color,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFeatureDetails(PremiumFeature feature) {
    showDialog(
      context: context,
      builder: (context) => FeatureDetailDialog(feature: feature),
    );
  }
}

class FeatureDetailDialog extends StatefulWidget {
  final PremiumFeature feature;

  const FeatureDetailDialog({super.key, required this.feature});

  @override
  State<FeatureDetailDialog> createState() => _FeatureDetailDialogState();
}

class _FeatureDetailDialogState extends State<FeatureDetailDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PerformanceOptimizer.createOptimizedController(
      duration: GTKYAnimations.medium,
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
    return GTKYAnimations.scaleWithGlow(
      controller: _controller,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(widget.feature.icon, color: widget.feature.color),
            const SizedBox(width: 12),
            Text(widget.feature.title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.feature.description),
            if (widget.feature.details != null) ...[
              const SizedBox(height: 16),
              Text(
                widget.feature.details!,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        actions: [
          EnhancedButton(
            style: GTKYButtonStyle.outline,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class PremiumFeature {
  final String title;
  final String description;
  final String? details;
  final IconData icon;
  final Color color;
  final bool isAvailable;
  final String? badge;

  const PremiumFeature({
    required this.title,
    required this.description,
    this.details,
    required this.icon,
    required this.color,
    this.isAvailable = false,
    this.badge,
  });
}

// Predefined premium features
class GTKYPremiumFeatures {
  static List<PremiumFeature> get features => [
    PremiumFeature(
      title: 'Unlimited Dining Plans',
      description: 'Create and join unlimited dining plans per month',
      details: 'Free users are limited to 5 dining plans per month. Premium members can create and join as many as they want.',
      icon: Icons.restaurant_menu,
      color: GTKYAnimations.primaryColor,
      badge: 'POPULAR',
    ),
    PremiumFeature(
      title: 'Priority Matching',
      description: 'Get matched with professionals faster',
      details: 'Your profile will be shown first to other users, increasing your chances of getting matched.',
      icon: Icons.flash_on,
      color: Colors.orange,
      badge: 'NEW',
    ),
    PremiumFeature(
      title: 'Advanced Filters',
      description: 'Filter by company, industry, experience level',
      details: 'Use advanced search filters to find exactly the type of professionals you want to meet.',
      icon: Icons.tune,
      color: GTKYAnimations.secondaryColor,
    ),
    PremiumFeature(
      title: 'Exclusive Events',
      description: 'Access to premium networking events',
      details: 'Join exclusive events with C-level executives and industry leaders.',
      icon: Icons.event,
      color: GTKYAnimations.accentColor,
      badge: 'EXCLUSIVE',
    ),
    PremiumFeature(
      title: 'Analytics Dashboard',
      description: 'Track your networking progress and insights',
      details: 'See detailed analytics about your networking activities, connections made, and career growth.',
      icon: Icons.analytics,
      color: Colors.green,
    ),
    PremiumFeature(
      title: 'Concierge Support',
      description: '24/7 priority customer support',
      details: 'Get instant help from our dedicated premium support team.',
      icon: Icons.support_agent,
      color: Colors.blue,
    ),
  ];
}