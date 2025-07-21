import 'package:flutter/material.dart';

class SuccessAnimation extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final VoidCallback? onComplete;

  const SuccessAnimation({
    Key? key,
    this.size = 100,
    this.color = Colors.green,
    this.duration = const Duration(milliseconds: 1000),
    this.onComplete,
  }) : super(key: key);

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  late AnimationController _checkController;
  late Animation<double> _circleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    
    _circleController = AnimationController(
      duration: Duration(milliseconds: (widget.duration.inMilliseconds * 0.6).round()),
      vsync: this,
    );
    
    _checkController = AnimationController(
      duration: Duration(milliseconds: (widget.duration.inMilliseconds * 0.4).round()),
      vsync: this,
    );

    _circleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _circleController,
      curve: Curves.elasticOut,
    ));

    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    ));

    _startAnimation();
  }

  @override
  void dispose() {
    _circleController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  void _startAnimation() async {
    await _circleController.forward();
    await _checkController.forward();
    
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // Circle animation
          AnimatedBuilder(
            animation: _circleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _circleAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.1),
                    border: Border.all(
                      color: widget.color,
                      width: 3,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Check mark animation
          AnimatedBuilder(
            animation: _checkAnimation,
            builder: (context, child) {
              return Center(
                child: CustomPaint(
                  size: Size(widget.size * 0.5, widget.size * 0.5),
                  painter: CheckMarkPainter(
                    progress: _checkAnimation.value,
                    color: widget.color,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class CheckMarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  CheckMarkPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Define check mark points
    final startPoint = Offset(size.width * 0.2, size.height * 0.5);
    final middlePoint = Offset(size.width * 0.45, size.height * 0.7);
    final endPoint = Offset(size.width * 0.8, size.height * 0.3);

    if (progress <= 0.5) {
      // First half: draw from start to middle
      final currentProgress = progress * 2;
      final currentPoint = Offset.lerp(startPoint, middlePoint, currentProgress)!;
      
      path.moveTo(startPoint.dx, startPoint.dy);
      path.lineTo(currentPoint.dx, currentPoint.dy);
    } else {
      // Second half: draw from middle to end
      final currentProgress = (progress - 0.5) * 2;
      final currentPoint = Offset.lerp(middlePoint, endPoint, currentProgress)!;
      
      path.moveTo(startPoint.dx, startPoint.dy);
      path.lineTo(middlePoint.dx, middlePoint.dy);
      path.lineTo(currentPoint.dx, currentPoint.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CheckMarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}