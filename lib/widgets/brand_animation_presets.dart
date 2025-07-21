import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom animation presets for the GTKY brand
class GTKYAnimations {
  // Brand colors
  static const Color primaryColor = Color(0xFF6B73FF);
  static const Color secondaryColor = Color(0xFF9C27B0);
  static const Color accentColor = Color(0xFF00BCD4);
  
  // Animation durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration extraSlow = Duration(milliseconds: 800);

  // Custom curves
  static const Curve brandEaseIn = Curves.easeInCubic;
  static const Curve brandEaseOut = Curves.easeOutCubic;
  static const Curve brandBounce = Curves.elasticOut;
  static const Curve brandSmooth = Curves.easeInOutCubic;

  /// Creates a branded slide-in animation
  static Widget slideIn({
    required Widget child,
    required AnimationController controller,
    SlideDirection direction = SlideDirection.up,
    Duration delay = Duration.zero,
  }) {
    final slideAnimation = Tween<Offset>(
      begin: _getSlideOffset(direction),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay.inMilliseconds / controller.duration!.inMilliseconds,
        1.0,
        curve: brandSmooth,
      ),
    ));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay.inMilliseconds / controller.duration!.inMilliseconds,
        1.0,
        curve: brandEaseOut,
      ),
    ));

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }

  /// Creates a branded scale animation with glow effect
  static Widget scaleWithGlow({
    required Widget child,
    required AnimationController controller,
    Color glowColor = primaryColor,
    Duration delay = Duration.zero,
  }) {
    final scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay.inMilliseconds / controller.duration!.inMilliseconds,
        1.0,
        curve: brandBounce,
      ),
    ));

    return AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, _) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: glowColor.withOpacity(0.3 * scaleAnimation.value),
                  blurRadius: 20 * scaleAnimation.value,
                  spreadRadius: 5 * scaleAnimation.value,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// Creates a branded floating animation
  static Widget floating({
    required Widget child,
    required AnimationController controller,
    double amplitude = 10.0,
  }) {
    final floatAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(controller);

    return AnimatedBuilder(
      animation: floatAnimation,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, math.sin(floatAnimation.value) * amplitude),
          child: child,
        );
      },
    );
  }

  /// Creates a branded pulse animation
  static Widget pulse({
    required Widget child,
    required AnimationController controller,
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    final pulseAnimation = Tween<double>(
      begin: minScale,
      end: maxScale,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: brandSmooth,
    ));

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, _) {
        return Transform.scale(
          scale: pulseAnimation.value,
          child: child,
        );
      },
    );
  }

  /// Creates a branded shimmer effect
  static Widget shimmer({
    required Widget child,
    required AnimationController controller,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
  }) {
    final shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));

    return AnimatedBuilder(
      animation: shimmerAnimation,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                shimmerAnimation.value - 0.3,
                shimmerAnimation.value,
                shimmerAnimation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }

  static Offset _getSlideOffset(SlideDirection direction) {
    switch (direction) {
      case SlideDirection.up:
        return const Offset(0, 0.3);
      case SlideDirection.down:
        return const Offset(0, -0.3);
      case SlideDirection.left:
        return const Offset(0.3, 0);
      case SlideDirection.right:
        return const Offset(-0.3, 0);
    }
  }
}

enum SlideDirection { up, down, left, right }

/// Branded micro-interaction widgets
class GTKYMicroInteractions {
  /// Creates a tap-to-scale micro-interaction
  static Widget tapToScale({
    required Widget child,
    required VoidCallback? onTap,
    double scaleDown = 0.95,
    Duration duration = GTKYAnimations.fast,
  }) {
    return _TapToScaleWidget(
      onTap: onTap,
      scaleDown: scaleDown,
      duration: duration,
      child: child,
    );
  }

  /// Creates a hover glow effect
  static Widget hoverGlow({
    required Widget child,
    Color glowColor = GTKYAnimations.primaryColor,
    double glowRadius = 20.0,
  }) {
    return _HoverGlowWidget(
      glowColor: glowColor,
      glowRadius: glowRadius,
      child: child,
    );
  }

  /// Creates a ripple effect on tap
  static Widget rippleEffect({
    required Widget child,
    required VoidCallback? onTap,
    Color rippleColor = GTKYAnimations.primaryColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: rippleColor.withOpacity(0.3),
        highlightColor: rippleColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}

class _TapToScaleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;

  const _TapToScaleWidget({
    required this.child,
    required this.onTap,
    required this.scaleDown,
    required this.duration,
  });

  @override
  State<_TapToScaleWidget> createState() => _TapToScaleWidgetState();
}

class _TapToScaleWidgetState extends State<_TapToScaleWidget>
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
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: GTKYAnimations.brandEaseOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
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

class _HoverGlowWidget extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;

  const _HoverGlowWidget({
    required this.child,
    required this.glowColor,
    required this.glowRadius,
  });

  @override
  State<_HoverGlowWidget> createState() => _HoverGlowWidgetState();
}

class _HoverGlowWidgetState extends State<_HoverGlowWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: GTKYAnimations.medium,
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: GTKYAnimations.brandEaseOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovering = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovering = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withOpacity(0.3 * _glowAnimation.value),
                  blurRadius: widget.glowRadius * _glowAnimation.value,
                  spreadRadius: 5 * _glowAnimation.value,
                ),
              ],
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Performance optimization utilities
class AnimationPerformance {
  /// Optimizes animations for better performance
  static Widget optimized({
    required Widget child,
    bool enableAnimations = true,
  }) {
    if (!enableAnimations) {
      return child;
    }
    
    return RepaintBoundary(
      child: child,
    );
  }

  /// Creates a performance-aware animation controller
  static AnimationController createController({
    required Duration duration,
    required TickerProvider vsync,
    bool reduceMotion = false,
  }) {
    return AnimationController(
      duration: reduceMotion ? Duration.zero : duration,
      vsync: vsync,
    );
  }
}