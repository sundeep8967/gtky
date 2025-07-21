import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'brand_animation_presets.dart';
import 'sound_effects.dart';
import 'performance_optimizer.dart';

/// Enhanced button with advanced micro-interactions
class EnhancedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? elevation;
  final bool isLoading;
  final ButtonStyle style;
  final bool enableHaptic;
  final bool enableGlow;

  const EnhancedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.elevation,
    this.isLoading = false,
    this.style = ButtonStyle.primary,
    this.enableHaptic = true,
    this.enableGlow = true,
  });

  @override
  State<EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<EnhancedButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _glowController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rippleAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _pressController = PerformanceOptimizer.createOptimizedController(
      duration: GTKYAnimations.fast,
      vsync: this,
    );
    
    _glowController = PerformanceOptimizer.createOptimizedController(
      duration: GTKYAnimations.medium,
      vsync: this,
    );
    
    _rippleController = PerformanceOptimizer.createOptimizedController(
      duration: GTKYAnimations.slow,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: GTKYAnimations.brandEaseOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? 4.0,
      end: (widget.elevation ?? 4.0) * 0.5,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: GTKYAnimations.brandEaseOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: GTKYAnimations.brandEaseOut,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: GTKYAnimations.brandEaseOut,
    ));
  }

  @override
  void dispose() {
    _pressController.dispose();
    _glowController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _pressController.forward();
      if (widget.enableGlow) {
        _glowController.forward();
      }
      if (widget.enableHaptic) {
        SoundEffects.playTap();
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _handleTapEnd();
  }

  void _handleTapCancel() {
    _handleTapEnd();
  }

  void _handleTapEnd() {
    setState(() => _isPressed = false);
    _pressController.reverse();
    _glowController.reverse();
    _rippleController.forward().then((_) {
      _rippleController.reset();
    });
  }

  Color get _backgroundColor {
    switch (widget.style) {
      case ButtonStyle.primary:
        return widget.backgroundColor ?? GTKYAnimations.primaryColor;
      case ButtonStyle.secondary:
        return widget.backgroundColor ?? GTKYAnimations.secondaryColor;
      case ButtonStyle.accent:
        return widget.backgroundColor ?? GTKYAnimations.accentColor;
      case ButtonStyle.outline:
        return Colors.transparent;
    }
  }

  Color get _foregroundColor {
    switch (widget.style) {
      case ButtonStyle.outline:
        return widget.foregroundColor ?? GTKYAnimations.primaryColor;
      default:
        return widget.foregroundColor ?? Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _elevationAnimation,
          _glowAnimation,
          _rippleAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                boxShadow: [
                  // Elevation shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: _elevationAnimation.value * 2,
                    offset: Offset(0, _elevationAnimation.value),
                  ),
                  // Glow effect
                  if (widget.enableGlow && _glowAnimation.value > 0)
                    BoxShadow(
                      color: _backgroundColor.withOpacity(0.4 * _glowAnimation.value),
                      blurRadius: 20 * _glowAnimation.value,
                      spreadRadius: 5 * _glowAnimation.value,
                    ),
                ],
              ),
              child: Material(
                color: _backgroundColor,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                child: Container(
                  padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                    border: widget.style == ButtonStyle.outline
                        ? Border.all(color: _foregroundColor, width: 2)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripple effect
                      if (_rippleAnimation.value > 0)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                            child: CustomPaint(
                              painter: RipplePainter(
                                progress: _rippleAnimation.value,
                                color: _foregroundColor.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                      
                      // Content
                      widget.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(_foregroundColor),
                              ),
                            )
                          : DefaultTextStyle(
                              style: TextStyle(
                                color: _foregroundColor,
                                fontWeight: FontWeight.w600,
                              ),
                              child: widget.child,
                            ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum ButtonStyle { primary, secondary, accent, outline }

/// Enhanced card with micro-interactions
class EnhancedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Color? color;
  final bool enableHover;
  final bool enablePress;
  final bool enableGlow;

  const EnhancedCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding,
    this.elevation,
    this.borderRadius,
    this.color,
    this.enableHover = true,
    this.enablePress = true,
    this.enableGlow = true,
  });

  @override
  State<EnhancedCard> createState() => _EnhancedCardState();
}

class _EnhancedCardState extends State<EnhancedCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pressController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  bool _isHovering = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _hoverController = PerformanceOptimizer.createOptimizedController(
      duration: GTKYAnimations.medium,
      vsync: this,
    );
    
    _pressController = PerformanceOptimizer.createOptimizedController(
      duration: GTKYAnimations.fast,
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? 2.0,
      end: (widget.elevation ?? 2.0) + 6.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: GTKYAnimations.brandEaseOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: GTKYAnimations.brandEaseOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: GTKYAnimations.brandEaseOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _handleHoverEnter(PointerEnterEvent event) {
    if (widget.enableHover) {
      setState(() => _isHovering = true);
      _hoverController.forward();
    }
  }

  void _handleHoverExit(PointerExitEvent event) {
    if (widget.enableHover) {
      setState(() => _isHovering = false);
      _hoverController.reverse();
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enablePress && widget.onTap != null) {
      setState(() => _isPressed = true);
      _pressController.forward();
      SoundEffects.playTap();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enablePress) {
      setState(() => _isPressed = false);
      _pressController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enablePress) {
      setState(() => _isPressed = false);
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _handleHoverEnter,
      onExit: _handleHoverExit,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_elevationAnimation, _scaleAnimation, _glowAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: widget.margin,
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                  boxShadow: [
                    // Main shadow
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: _elevationAnimation.value,
                      offset: Offset(0, _elevationAnimation.value / 2),
                    ),
                    // Glow effect
                    if (widget.enableGlow && _glowAnimation.value > 0)
                      BoxShadow(
                        color: GTKYAnimations.primaryColor.withOpacity(0.2 * _glowAnimation.value),
                        blurRadius: 15 * _glowAnimation.value,
                        spreadRadius: 2 * _glowAnimation.value,
                      ),
                  ],
                ),
                child: Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                  ),
                  color: widget.color,
                  child: Padding(
                    padding: widget.padding ?? const EdgeInsets.all(16),
                    child: widget.child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom ripple painter
class RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.max(size.width, size.height) / 2;
    final radius = maxRadius * progress;

    final paint = Paint()
      ..color = color.withOpacity(1.0 - progress)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Floating action button with enhanced interactions
class EnhancedFAB extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final double size;
  final bool enablePulse;

  const EnhancedFAB({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.size = 56.0,
    this.enablePulse = false,
  });

  @override
  State<EnhancedFAB> createState() => _EnhancedFABState();
}

class _EnhancedFABState extends State<EnhancedFAB>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pressController = PerformanceOptimizer.createOptimizedController(
      duration: GTKYAnimations.fast,
      vsync: this,
    );
    
    _pulseController = PerformanceOptimizer.createOptimizedController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: GTKYAnimations.brandEaseOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: GTKYAnimations.brandSmooth,
    ));

    if (widget.enablePulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _pressController.forward();
    SoundEffects.playTap();
  }

  void _handleTapUp(TapUpDetails details) {
    _pressController.reverse();
  }

  void _handleTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value * _pulseAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? GTKYAnimations.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                  if (widget.enablePulse)
                    BoxShadow(
                      color: (widget.backgroundColor ?? GTKYAnimations.primaryColor)
                          .withOpacity(0.3 * _pulseAnimation.value),
                      blurRadius: 20 * _pulseAnimation.value,
                      spreadRadius: 5 * _pulseAnimation.value,
                    ),
                ],
              ),
              child: Center(child: widget.child),
            ),
          );
        },
      ),
    );
  }
}