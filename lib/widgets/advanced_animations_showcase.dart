import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A showcase widget demonstrating various advanced animations
class AdvancedAnimationsShowcase extends StatefulWidget {
  const AdvancedAnimationsShowcase({super.key});

  @override
  State<AdvancedAnimationsShowcase> createState() => _AdvancedAnimationsShowcaseState();
}

class _AdvancedAnimationsShowcaseState extends State<AdvancedAnimationsShowcase>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _breathingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _breathingAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _breathingController.repeat(reverse: true);
    _pulseController.repeat();
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Animations'),
        backgroundColor: const Color(0xFF6B73FF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Breathing Animation'),
            _buildBreathingDemo(),
            const SizedBox(height: 32),
            
            _buildSectionTitle('Pulse Animation'),
            _buildPulseDemo(),
            const SizedBox(height: 32),
            
            _buildSectionTitle('Rotation Animation'),
            _buildRotationDemo(),
            const SizedBox(height: 32),
            
            _buildSectionTitle('Combined Animations'),
            _buildCombinedDemo(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6B73FF),
        ),
      ),
    );
  }

  Widget _buildBreathingDemo() {
    return Center(
      child: AnimatedBuilder(
        animation: _breathingAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _breathingAnimation.value,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blue.withOpacity(0.8),
                    Colors.purple.withOpacity(0.6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 20 * _breathingAnimation.value,
                    spreadRadius: 5 * _breathingAnimation.value,
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 40,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPulseDemo() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6B73FF),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B73FF).withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications,
                color: Colors.white,
                size: 30,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRotationDemo() {
    return Center(
      child: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.red],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.refresh,
                color: Colors.white,
                size: 30,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCombinedDemo() {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _breathingAnimation,
          _pulseAnimation,
          _rotationAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _breathingAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value * 0.5,
              child: Container(
                width: 120 * _pulseAnimation.value,
                height: 120 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Colors.purple,
                      Colors.blue,
                      Colors.green,
                      Colors.yellow,
                      Colors.red,
                      Colors.purple,
                    ],
                    transform: GradientRotation(_rotationAnimation.value),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 20 * _breathingAnimation.value,
                      spreadRadius: 5 * _breathingAnimation.value,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Utility class for creating custom animation curves
class CustomCurves {
  static const Curve elasticInOut = Curves.elasticInOut;
  static const Curve bounceInOut = Curves.bounceInOut;
  
  static Curve customBounce = const _CustomBounceCurve();
  static Curve customElastic = const _CustomElasticCurve();
}

class _CustomBounceCurve extends Curve {
  const _CustomBounceCurve();

  @override
  double transform(double t) {
    if (t < 0.5) {
      return 8 * t * t * t * t;
    } else {
      return 1 - 8 * (1 - t) * (1 - t) * (1 - t) * (1 - t);
    }
  }
}

class _CustomElasticCurve extends Curve {
  const _CustomElasticCurve();

  @override
  double transform(double t) {
    if (t == 0 || t == 1) return t;
    return math.pow(2, -10 * t) * math.sin((t - 0.1) * 5 * math.pi) + 1;
  }
}