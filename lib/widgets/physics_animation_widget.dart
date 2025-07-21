import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class PhysicsAnimationWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double dampingRatio;
  final double frequency;
  final bool enablePhysics;

  const PhysicsAnimationWidget({
    super.key,
    required this.child,
    this.onTap,
    this.dampingRatio = 0.8,
    this.frequency = 2.0,
    this.enablePhysics = true,
  });

  @override
  State<PhysicsAnimationWidget> createState() => _PhysicsAnimationWidgetState();
}

class _PhysicsAnimationWidgetState extends State<PhysicsAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startPhysicsAnimation() {
    if (!widget.enablePhysics) return;

    final simulation = SpringSimulation(
      SpringDescription(
        mass: 1.0,
        stiffness: 100.0 * widget.frequency,
        damping: 2.0 * widget.dampingRatio * 10.0,
      ),
      0.0, // starting position
      1.0, // ending position
      0.0, // starting velocity
    );

    _controller.animateWith(simulation);
  }

  void _handleTap() {
    _startPhysicsAnimation();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_animation.value * 0.1),
            child: widget.child,
          );
        },
      ),
    );
  }
}

class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Duration duration;
  final double bounceScale;

  const BouncyButton({
    super.key,
    required this.child,
    this.onPressed,
    this.duration = const Duration(milliseconds: 200),
    this.bounceScale = 0.95,
  });

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.bounceScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

class WaveAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double amplitude;
  final int waveCount;

  const WaveAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
    this.amplitude = 10.0,
    this.waveCount = 3,
  });

  @override
  State<WaveAnimation> createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<WaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159 * widget.waveCount,
    ).animate(_controller);

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, widget.amplitude * sin(_animation.value)),
          child: widget.child,
        );
      },
    );
  }
}

double sin(double value) {
  // Simple sine approximation for wave effect
  return (value % (2 * 3.14159)) / 3.14159 - 1;
}