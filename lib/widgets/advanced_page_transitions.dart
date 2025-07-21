import 'package:flutter/material.dart';
import 'dart:math' as math;

class CubeTransition extends PageRouteBuilder {
  final Widget child;
  final AxisDirection direction;

  CubeTransition({
    required this.child,
    this.direction = AxisDirection.right,
  }) : super(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) => child,
        );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final rotationY = animation.value * math.pi / 2;
        
        if (animation.value <= 0.5) {
          return Transform(
            alignment: Alignment.centerRight,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(-rotationY),
            child: child,
          );
        } else {
          return Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(math.pi / 2 - rotationY),
            child: child,
          );
        }
      },
      child: child,
    );
  }
}

class FlipTransition extends PageRouteBuilder {
  final Widget child;
  final Axis flipAxis;

  FlipTransition({
    required this.child,
    this.flipAxis = Axis.horizontal,
  }) : super(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, animation, secondaryAnimation) => child,
        );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final isShowingFrontSide = animation.value < 0.5;
        
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(flipAxis == Axis.horizontal ? animation.value * math.pi : 0)
            ..rotateX(flipAxis == Axis.vertical ? animation.value * math.pi : 0),
          child: isShowingFrontSide
              ? Container() // Previous page
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..rotateY(flipAxis == Axis.horizontal ? math.pi : 0)
                    ..rotateX(flipAxis == Axis.vertical ? math.pi : 0),
                  child: child,
                ),
        );
      },
      child: child,
    );
  }
}

class MorphTransition extends PageRouteBuilder {
  final Widget child;
  final Widget morphingWidget;
  final Offset startPosition;
  final Offset endPosition;

  MorphTransition({
    required this.child,
    required this.morphingWidget,
    required this.startPosition,
    required this.endPosition,
  }) : super(
          transitionDuration: const Duration(milliseconds: 1000),
          pageBuilder: (context, animation, secondaryAnimation) => child,
        );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return Stack(
      children: [
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
          )),
          child: child,
        ),
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final morphProgress = Curves.easeInOutCubic.transform(animation.value);
            final position = Offset.lerp(startPosition, endPosition, morphProgress)!;
            final scale = Tween<double>(begin: 1.0, end: 0.0).transform(morphProgress);
            
            return Positioned(
              left: position.dx,
              top: position.dy,
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: 1 - morphProgress,
                  child: morphingWidget,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class LiquidSwipeTransition extends PageRouteBuilder {
  final Widget child;
  final Color liquidColor;

  LiquidSwipeTransition({
    required this.child,
    this.liquidColor = const Color(0xFF007AFF),
  }) : super(
          transitionDuration: const Duration(milliseconds: 1200),
          pageBuilder: (context, animation, secondaryAnimation) => child,
        );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return Stack(
      children: [
        child,
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            return CustomPaint(
              painter: LiquidSwipePainter(
                progress: animation.value,
                color: liquidColor,
              ),
              size: MediaQuery.of(context).size,
            );
          },
        ),
      ],
    );
  }
}

class LiquidSwipePainter extends CustomPainter {
  final double progress;
  final Color color;

  LiquidSwipePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 50.0;
    final waveLength = size.width / 3;
    final baseY = size.height * (1 - progress);

    path.moveTo(0, size.height);
    path.lineTo(0, baseY);

    // Create liquid wave
    for (double x = 0; x <= size.width; x += 5) {
      final waveY = baseY + waveHeight * math.sin((x / waveLength) * 2 * math.pi + progress * 4 * math.pi);
      path.lineTo(x, waveY);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LiquidSwipePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class ParticleTransition extends PageRouteBuilder {
  final Widget child;
  final int particleCount;
  final Color particleColor;

  ParticleTransition({
    required this.child,
    this.particleCount = 50,
    this.particleColor = const Color(0xFF007AFF),
  }) : super(
          transitionDuration: const Duration(milliseconds: 1500),
          pageBuilder: (context, animation, secondaryAnimation) => child,
        );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return Stack(
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
            ),
          ),
          child: child,
        ),
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            return CustomPaint(
              painter: ParticleTransitionPainter(
                progress: animation.value,
                particleCount: particleCount,
                color: particleColor,
              ),
              size: MediaQuery.of(context).size,
            );
          },
        ),
      ],
    );
  }
}

class ParticleTransitionPainter extends CustomPainter {
  final double progress;
  final int particleCount;
  final Color color;

  ParticleTransitionPainter({
    required this.progress,
    required this.particleCount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Fixed seed for consistent animation

    for (int i = 0; i < particleCount; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = size.height + 50;
      final endX = startX + (random.nextDouble() - 0.5) * 200;
      final endY = random.nextDouble() * size.height;

      final particleProgress = (progress - (i / particleCount * 0.5)).clamp(0.0, 1.0);
      
      if (particleProgress > 0) {
        final x = startX + (endX - startX) * particleProgress;
        final y = startY + (endY - startY) * particleProgress;
        final opacity = (1 - particleProgress) * 0.8;
        final size = 2 + random.nextDouble() * 4;

        paint.color = color.withOpacity(opacity);
        canvas.drawCircle(Offset(x, y), size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(ParticleTransitionPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class ElasticTransition extends PageRouteBuilder {
  final Widget child;
  final ElasticDirection direction;

  ElasticTransition({
    required this.child,
    this.direction = ElasticDirection.fromBottom,
  }) : super(
          transitionDuration: const Duration(milliseconds: 1000),
          pageBuilder: (context, animation, secondaryAnimation) => child,
        );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final elasticAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.elasticOut,
    );

    Offset getOffset() {
      switch (direction) {
        case ElasticDirection.fromBottom:
          return Offset(0, 1 - elasticAnimation.value);
        case ElasticDirection.fromTop:
          return Offset(0, elasticAnimation.value - 1);
        case ElasticDirection.fromLeft:
          return Offset(elasticAnimation.value - 1, 0);
        case ElasticDirection.fromRight:
          return Offset(1 - elasticAnimation.value, 0);
      }
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: getOffset(),
        end: Offset.zero,
      ).animate(elasticAnimation),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(elasticAnimation),
        child: child,
      ),
    );
  }
}

enum ElasticDirection {
  fromBottom,
  fromTop,
  fromLeft,
  fromRight,
}

class GlitchTransition extends PageRouteBuilder {
  final Widget child;
  final Duration glitchDuration;

  GlitchTransition({
    required this.child,
    this.glitchDuration = const Duration(milliseconds: 800),
  }) : super(
          transitionDuration: glitchDuration,
          pageBuilder: (context, animation, secondaryAnimation) => child,
        );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final glitchIntensity = math.sin(animation.value * 20) * 0.1;
        final random = math.Random((animation.value * 1000).toInt());
        
        return Stack(
          children: [
            // Red channel
            Transform.translate(
              offset: Offset(glitchIntensity * 5, 0),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  1, 0, 0, 0, 0,
                  0, 0, 0, 0, 0,
                  0, 0, 0, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: Opacity(
                  opacity: 0.8,
                  child: child,
                ),
              ),
            ),
            // Green channel
            Transform.translate(
              offset: Offset(-glitchIntensity * 3, glitchIntensity * 2),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  0, 0, 0, 0, 0,
                  0, 1, 0, 0, 0,
                  0, 0, 0, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: Opacity(
                  opacity: 0.8,
                  child: child,
                ),
              ),
            ),
            // Blue channel
            Transform.translate(
              offset: Offset(glitchIntensity * 2, -glitchIntensity * 4),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  0, 0, 0, 0, 0,
                  0, 0, 0, 0, 0,
                  0, 0, 1, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: Opacity(
                  opacity: 0.8,
                  child: child,
                ),
              ),
            ),
            // Normal layer
            Opacity(
              opacity: 1 - animation.value * 0.3,
              child: child,
            ),
          ],
        );
      },
    );
  }
}