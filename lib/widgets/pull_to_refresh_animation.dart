import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomPullToRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color color;
  final double displacement;

  const CustomPullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color = const Color(0xFF007AFF),
    this.displacement = 40.0,
  });

  @override
  State<CustomPullToRefresh> createState() => _CustomPullToRefreshState();
}

class _CustomPullToRefreshState extends State<CustomPullToRefresh>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _scaleController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isRefreshing = false;
  double _dragDistance = 0.0;
  static const double _triggerDistance = 100.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_controller);

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    _controller.repeat();
    _scaleController.forward();
    
    try {
      await widget.onRefresh();
    } finally {
      _controller.stop();
      _scaleController.reverse();
      setState(() {
        _isRefreshing = false;
        _dragDistance = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          if (notification.metrics.pixels < 0 && !_isRefreshing) {
            setState(() {
              _dragDistance = (-notification.metrics.pixels).clamp(0.0, _triggerDistance);
            });
            
            if (_dragDistance > 0) {
              _scaleController.value = (_dragDistance / _triggerDistance).clamp(0.0, 1.0);
            }
          }
        } else if (notification is ScrollEndNotification) {
          if (_dragDistance >= _triggerDistance && !_isRefreshing) {
            _handleRefresh();
          } else if (!_isRefreshing) {
            _scaleController.reverse();
            setState(() {
              _dragDistance = 0.0;
            });
          }
        }
        return false;
      },
      child: Stack(
        children: [
          widget.child,
          if (_dragDistance > 0 || _isRefreshing)
            Positioned(
              top: widget.displacement,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_scaleAnimation, _rotationAnimation]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Transform.rotate(
                        angle: _isRefreshing ? _rotationAnimation.value : 0,
                        child: CustomPaint(
                          size: const Size(40, 40),
                          painter: RefreshIndicatorPainter(
                            color: widget.color,
                            progress: _isRefreshing ? 1.0 : _dragDistance / _triggerDistance,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RefreshIndicatorPainter extends CustomPainter {
  final Color color;
  final double progress;

  RefreshIndicatorPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw background circle
    canvas.drawCircle(
      center,
      radius,
      paint..color = color.withOpacity(0.2),
    );

    // Draw progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        paint..color = color,
      );
    }

    // Draw arrow when fully pulled
    if (progress >= 1.0) {
      final arrowPaint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final arrowPath = Path();
      arrowPath.moveTo(center.dx - 6, center.dy - 3);
      arrowPath.lineTo(center.dx, center.dy + 3);
      arrowPath.lineTo(center.dx + 6, center.dy - 3);

      canvas.drawPath(arrowPath, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(RefreshIndicatorPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class BounceScrollPhysics extends ScrollPhysics {
  const BounceScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  BounceScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return BounceScrollPhysics(parent: buildParent(ancestor));
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
        spring,
        position.pixels,
        end!,
        math.min(0.0, velocity),
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
}