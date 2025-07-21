import 'package:flutter/material.dart';
import 'dart:math' as math;

class ElasticScrollView extends StatefulWidget {
  final Widget child;
  final double elasticity;
  final Duration snapBackDuration;
  final Curve snapBackCurve;

  const ElasticScrollView({
    super.key,
    required this.child,
    this.elasticity = 0.3,
    this.snapBackDuration = const Duration(milliseconds: 500),
    this.snapBackCurve = Curves.elasticOut,
  });

  @override
  State<ElasticScrollView> createState() => _ElasticScrollViewState();
}

class _ElasticScrollViewState extends State<ElasticScrollView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  double _overscroll = 0.0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.snapBackDuration,
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.snapBackCurve),
    );
    
    _animation.addListener(() {
      setState(() {
        _overscroll = _overscroll * (1 - _animation.value);
      });
    });
    
    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _overscroll = 0.0;
          _isAnimating = false;
        });
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleOverscroll(double delta) {
    if (!_isAnimating) {
      setState(() {
        _overscroll += delta * widget.elasticity;
        _overscroll = _overscroll.clamp(-200.0, 200.0);
      });
    }
  }

  void _snapBack() {
    if (_overscroll.abs() > 0.1 && !_isAnimating) {
      setState(() {
        _isAnimating = true;
      });
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is OverscrollNotification) {
          _handleOverscroll(notification.overscroll);
        } else if (notification is ScrollEndNotification) {
          _snapBack();
        }
        return false;
      },
      child: Transform.translate(
        offset: Offset(0, _overscroll),
        child: widget.child,
      ),
    );
  }
}

class RubberBandScrollPhysics extends ScrollPhysics {
  final double rubberBandFactor;

  const RubberBandScrollPhysics({
    ScrollPhysics? parent,
    this.rubberBandFactor = 0.3,
  }) : super(parent: parent);

  @override
  RubberBandScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return RubberBandScrollPhysics(
      parent: buildParent(ancestor),
      rubberBandFactor: rubberBandFactor,
    );
  }

  double _rubberBandClamp(double value, double min, double max) {
    if (value < min) {
      return min - (min - value) * rubberBandFactor;
    } else if (value > max) {
      return max + (value - max) * rubberBandFactor;
    }
    return value;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    final double result = _rubberBandClamp(
      value,
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    return result - value;
  }
}

class WaveScrollEffect extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final double frequency;
  final Duration duration;

  const WaveScrollEffect({
    super.key,
    required this.child,
    this.amplitude = 10.0,
    this.frequency = 2.0,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<WaveScrollEffect> createState() => _WaveScrollEffectState();
}

class _WaveScrollEffectState extends State<WaveScrollEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          setState(() {
            _scrollOffset = notification.metrics.pixels;
          });
        }
        return false;
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              widget.amplitude * math.sin(_animation.value + _scrollOffset * 0.01),
              0,
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

class ScrollRevealAnimation extends StatefulWidget {
  final Widget child;
  final double threshold;
  final Duration duration;
  final Curve curve;

  const ScrollRevealAnimation({
    super.key,
    required this.child,
    this.threshold = 0.1,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<ScrollRevealAnimation> createState() => _ScrollRevealAnimationState();
}

class _ScrollRevealAnimationState extends State<ScrollRevealAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkVisibility(ScrollNotification notification) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final visibleHeight = math.max(
      0.0,
      math.min(size.height, screenHeight - position.dy),
    );
    
    final visibilityRatio = visibleHeight / size.height;
    
    if (visibilityRatio >= widget.threshold && !_isVisible) {
      setState(() {
        _isVisible = true;
      });
      _controller.forward();
    } else if (visibilityRatio < widget.threshold && _isVisible) {
      setState(() {
        _isVisible = false;
      });
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _checkVisibility(notification);
        return false;
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}