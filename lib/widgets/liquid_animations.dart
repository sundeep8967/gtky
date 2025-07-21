import 'package:flutter/material.dart';
import 'dart:math' as math;

class LiquidButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color liquidColor;
  final Duration animationDuration;
  final double borderRadius;

  const LiquidButton({
    super.key,
    required this.child,
    this.onPressed,
    this.liquidColor = const Color(0xFF007AFF),
    this.animationDuration = const Duration(milliseconds: 800),
    this.borderRadius = 25.0,
  });

  @override
  State<LiquidButton> createState() => _LiquidButtonState();
}

class _LiquidButtonState extends State<LiquidButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _liquidAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _liquidAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.2, curve: Curves.easeInOut),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: CustomPaint(
              painter: LiquidPainter(
                progress: _liquidAnimation.value,
                color: widget.liquidColor,
                borderRadius: widget.borderRadius,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: widget.liquidColor,
                    width: 2,
                  ),
                ),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class LiquidPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double borderRadius;

  LiquidPainter({
    required this.progress,
    required this.color,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = size.height * 0.1;
    final waveLength = size.width / 2;
    
    // Create liquid wave effect
    path.moveTo(0, size.height);
    
    for (double x = 0; x <= size.width; x += 1) {
      final y = size.height - (size.height * progress) + 
          waveHeight * math.sin((x / waveLength) * 2 * math.pi + progress * 4 * math.pi);
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Clip to rounded rectangle
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    canvas.clipRRect(rrect);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LiquidPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class RippleEffect extends StatefulWidget {
  final Widget child;
  final Color rippleColor;
  final Duration duration;
  final VoidCallback? onTap;

  const RippleEffect({
    super.key,
    required this.child,
    this.rippleColor = const Color(0xFF007AFF),
    this.duration = const Duration(milliseconds: 600),
    this.onTap,
  });

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rippleAnimation;
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _tapPosition = details.localPosition;
    });
    _controller.forward().then((_) {
      _controller.reset();
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      child: CustomPaint(
        painter: RipplePainter(
          progress: _rippleAnimation.value,
          tapPosition: _tapPosition,
          color: widget.rippleColor,
        ),
        child: widget.child,
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  final double progress;
  final Offset? tapPosition;
  final Color color;

  RipplePainter({
    required this.progress,
    this.tapPosition,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (tapPosition == null || progress == 0) return;

    final paint = Paint()
      ..color = color.withOpacity(0.3 * (1 - progress))
      ..style = PaintingStyle.fill;

    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height);
    final radius = maxRadius * progress;

    canvas.drawCircle(tapPosition!, radius, paint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.tapPosition != tapPosition;
  }
}

class MorphingShape extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final List<BorderRadius> shapes;
  final bool autoPlay;

  const MorphingShape({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 3),
    this.shapes = const [
      BorderRadius.all(Radius.circular(8)),
      BorderRadius.all(Radius.circular(25)),
      BorderRadius.only(
        topLeft: Radius.circular(25),
        bottomRight: Radius.circular(25),
      ),
    ],
    this.autoPlay = true,
  });

  @override
  State<MorphingShape> createState() => _MorphingShapeState();
}

class _MorphingShapeState extends State<MorphingShape>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentShapeIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.autoPlay) {
      _startMorphing();
    }
  }

  void _startMorphing() {
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentShapeIndex = (_currentShapeIndex + 1) % widget.shapes.length;
        });
        _controller.reset();
        _controller.forward();
      }
    });
    _controller.forward();
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
        final currentShape = widget.shapes[_currentShapeIndex];
        final nextShape = widget.shapes[(_currentShapeIndex + 1) % widget.shapes.length];
        
        final morphedRadius = BorderRadius.lerp(
          currentShape,
          nextShape,
          _animation.value,
        );

        return Container(
          decoration: BoxDecoration(
            borderRadius: morphedRadius,
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            border: Border.all(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: morphedRadius ?? BorderRadius.zero,
            child: widget.child,
          ),
        );
      },
    );
  }
}