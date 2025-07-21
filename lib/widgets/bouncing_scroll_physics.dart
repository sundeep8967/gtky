import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'dart:math' as math;

class BouncingScrollPhysics extends ScrollPhysics {
  final double bounceFactor;
  final double dampingRatio;

  const BouncingScrollPhysics({
    ScrollPhysics? parent,
    this.bounceFactor = 0.8,
    this.dampingRatio = 0.9,
  }) : super(parent: parent);

  @override
  BouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return BouncingScrollPhysics(
      parent: buildParent(ancestor),
      bounceFactor: bounceFactor,
      dampingRatio: dampingRatio,
    );
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value < position.pixels && position.pixels <= position.minScrollExtent) {
      return value - position.pixels;
    }
    if (position.maxScrollExtent <= position.pixels && position.pixels < value) {
      return value - position.pixels;
    }
    if (value < position.minScrollExtent && position.minScrollExtent < position.pixels) {
      return value - position.minScrollExtent;
    }
    if (position.pixels < position.maxScrollExtent && position.maxScrollExtent < value) {
      return value - position.maxScrollExtent;
    }
    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final tolerance = this.tolerance;
    
    if (position.outOfRange) {
      double? end;
      if (position.pixels > position.maxScrollExtent) {
        end = position.maxScrollExtent;
      }
      if (position.pixels < position.minScrollExtent) {
        end = position.minScrollExtent;
      }
      
      assert(end != null);
      
      return ScrollSpringSimulation(
        SpringDescription(
          mass: 1.0,
          stiffness: 100.0,
          damping: dampingRatio * 20.0,
        ),
        position.pixels,
        end!,
        math.min(0.0, velocity * bounceFactor),
        tolerance: tolerance,
      );
    }
    
    if (velocity.abs() < tolerance.velocity) {
      return null;
    }
    
    if (velocity > 0.0 && position.pixels >= position.maxScrollExtent) {
      return null;
    }
    
    if (velocity < 0.0 && position.pixels <= position.minScrollExtent) {
      return null;
    }
    
    return ClampingScrollSimulation(
      position: position.pixels,
      velocity: velocity,
      tolerance: tolerance,
    );
  }

  @override
  SpringDescription get spring => SpringDescription(
    mass: 1.0,
    stiffness: 100.0,
    damping: dampingRatio * 20.0,
  );
}

class CustomBouncingScrollView extends StatefulWidget {
  final Widget child;
  final double bounceFactor;
  final Duration bounceDuration;
  final Curve bounceCurve;

  const CustomBouncingScrollView({
    super.key,
    required this.child,
    this.bounceFactor = 0.3,
    this.bounceDuration = const Duration(milliseconds: 300),
    this.bounceCurve = Curves.elasticOut,
  });

  @override
  State<CustomBouncingScrollView> createState() => _CustomBouncingScrollViewState();
}

class _CustomBouncingScrollViewState extends State<CustomBouncingScrollView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  double _overscroll = 0.0;
  bool _isBouncing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.bounceDuration,
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.bounceCurve),
    );
    
    _animation.addListener(() {
      setState(() {
        _overscroll = _overscroll * _animation.value;
      });
    });
    
    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _overscroll = 0.0;
          _isBouncing = false;
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
    if (!_isBouncing) {
      setState(() {
        _overscroll += delta * widget.bounceFactor;
        _overscroll = _overscroll.clamp(-100.0, 100.0);
      });
    }
  }

  void _startBounceBack() {
    if (_overscroll.abs() > 1.0 && !_isBouncing) {
      setState(() {
        _isBouncing = true;
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
          _startBounceBack();
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

class ElasticScrollBehavior extends ScrollBehavior {
  final double elasticity;

  const ElasticScrollBehavior({this.elasticity = 0.3});

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return BouncingScrollPhysics(
      parent: super.getScrollPhysics(context),
      bounceFactor: elasticity,
    );
  }
}

class OverscrollGlowEffect extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double maxGlowSize;

  const OverscrollGlowEffect({
    super.key,
    required this.child,
    this.glowColor = Colors.blue,
    this.maxGlowSize = 50.0,
  });

  @override
  State<OverscrollGlowEffect> createState() => _OverscrollGlowEffectState();
}

class _OverscrollGlowEffectState extends State<OverscrollGlowEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  
  double _glowIntensity = 0.0;
  bool _isGlowing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _glowAnimation.addListener(() {
      setState(() {
        _glowIntensity = _glowIntensity * _glowAnimation.value;
      });
    });
    
    _glowAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _glowIntensity = 0.0;
          _isGlowing = false;
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
    if (!_isGlowing) {
      setState(() {
        _glowIntensity = (delta.abs() / 100.0).clamp(0.0, 1.0);
      });
    }
  }

  void _startGlowFade() {
    if (_glowIntensity > 0.1 && !_isGlowing) {
      setState(() {
        _isGlowing = true;
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
          _startGlowFade();
        }
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          boxShadow: _glowIntensity > 0
              ? [
                  BoxShadow(
                    color: widget.glowColor.withOpacity(_glowIntensity * 0.3),
                    blurRadius: widget.maxGlowSize * _glowIntensity,
                    spreadRadius: widget.maxGlowSize * _glowIntensity * 0.5,
                  ),
                ]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}