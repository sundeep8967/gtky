import 'package:flutter/material.dart';
import 'dart:math' as math;

class ParticleSystem extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final Color particleColor;
  final double particleSize;
  final Duration duration;
  final bool isActive;

  const ParticleSystem({
    super.key,
    required this.child,
    this.particleCount = 20,
    this.particleColor = const Color(0xFF007AFF),
    this.particleSize = 4.0,
    this.duration = const Duration(seconds: 2),
    this.isActive = false,
  });

  @override
  State<ParticleSystem> createState() => _ParticleSystemState();
}

class _ParticleSystemState extends State<ParticleSystem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _initializeParticles();

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  void _initializeParticles() {
    _particles = List.generate(widget.particleCount, (index) {
      return Particle(
        position: Offset(
          math.Random().nextDouble() * 300,
          math.Random().nextDouble() * 300,
        ),
        velocity: Offset(
          (math.Random().nextDouble() - 0.5) * 100,
          (math.Random().nextDouble() - 0.5) * 100,
        ),
        life: math.Random().nextDouble(),
        size: widget.particleSize * (0.5 + math.Random().nextDouble() * 0.5),
      );
    });
  }

  @override
  void didUpdateWidget(ParticleSystem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isActive)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(
                    particles: _particles,
                    progress: _controller.value,
                    color: widget.particleColor,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class Particle {
  Offset position;
  Offset velocity;
  double life;
  double size;

  Particle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.size,
  });

  void update(double deltaTime) {
    position += velocity * deltaTime;
    life -= deltaTime;
    
    if (life <= 0) {
      // Reset particle
      position = Offset(
        math.Random().nextDouble() * 300,
        math.Random().nextDouble() * 300,
      );
      life = 1.0;
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      particle.update(0.016); // ~60fps
      
      paint.color = color.withValues(alpha: particle.life * 0.8);
      
      canvas.drawCircle(
        particle.position,
        particle.size * particle.life,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

class FloatingParticles extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final Color particleColor;
  final double minSize;
  final double maxSize;
  final Duration animationDuration;

  const FloatingParticles({
    super.key,
    required this.child,
    this.particleCount = 15,
    this.particleColor = const Color(0xFF007AFF),
    this.minSize = 2.0,
    this.maxSize = 6.0,
    this.animationDuration = const Duration(seconds: 4),
  });

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late List<FloatingParticle> _particles;

  @override
  void initState() {
    super.initState();
    _initializeParticles();
  }

  void _initializeParticles() {
    _controllers = List.generate(widget.particleCount, (index) {
      return AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.linear),
      );
    }).toList();

    _particles = List.generate(widget.particleCount, (index) {
      final random = math.Random();
      return FloatingParticle(
        startX: random.nextDouble(),
        startY: random.nextDouble(),
        endX: random.nextDouble(),
        endY: random.nextDouble(),
        size: widget.minSize + random.nextDouble() * (widget.maxSize - widget.minSize),
        opacity: 0.3 + random.nextDouble() * 0.7,
      );
    });

    // Start animations with random delays
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: CustomPaint(
            painter: FloatingParticlesPainter(
              particles: _particles,
              animations: _animations,
              color: widget.particleColor,
            ),
          ),
        ),
      ],
    );
  }
}

class FloatingParticle {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double size;
  final double opacity;

  FloatingParticle({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.size,
    required this.opacity,
  });
}

class FloatingParticlesPainter extends CustomPainter {
  final List<FloatingParticle> particles;
  final List<Animation<double>> animations;
  final Color color;

  FloatingParticlesPainter({
    required this.particles,
    required this.animations,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];
      final progress = animations[i].value;
      
      final x = particle.startX + (particle.endX - particle.startX) * progress;
      final y = particle.startY + (particle.endY - particle.startY) * progress;
      
      paint.color = color.withValues(alpha: particle.opacity * (1 - progress));
      
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(FloatingParticlesPainter oldDelegate) => true;
}

class ExplosionEffect extends StatefulWidget {
  final Widget child;
  final bool isExploding;
  final VoidCallback? onComplete;
  final Color particleColor;
  final int particleCount;

  const ExplosionEffect({
    super.key,
    required this.child,
    this.isExploding = false,
    this.onComplete,
    this.particleColor = const Color(0xFFFF3B30),
    this.particleCount = 30,
  });

  @override
  State<ExplosionEffect> createState() => _ExplosionEffectState();
}

class _ExplosionEffectState extends State<ExplosionEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _explosionAnimation;
  late List<ExplosionParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _explosionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _initializeExplosionParticles();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  void _initializeExplosionParticles() {
    _particles = List.generate(widget.particleCount, (index) {
      final angle = (index / widget.particleCount) * 2 * math.pi;
      final speed = 50 + math.Random().nextDouble() * 100;
      
      return ExplosionParticle(
        velocity: Offset(
          math.cos(angle) * speed,
          math.sin(angle) * speed,
        ),
        size: 2 + math.Random().nextDouble() * 4,
        life: 0.5 + math.Random().nextDouble() * 0.5,
      );
    });
  }

  @override
  void didUpdateWidget(ExplosionEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExploding && !oldWidget.isExploding) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isExploding)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _explosionAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ExplosionPainter(
                    particles: _particles,
                    progress: _explosionAnimation.value,
                    color: widget.particleColor,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class ExplosionParticle {
  final Offset velocity;
  final double size;
  final double life;

  ExplosionParticle({
    required this.velocity,
    required this.size,
    required this.life,
  });
}

class ExplosionPainter extends CustomPainter {
  final List<ExplosionParticle> particles;
  final double progress;
  final Color color;

  ExplosionPainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      final position = center + particle.velocity * progress;
      final life = (1 - progress / particle.life).clamp(0.0, 1.0);
      
      paint.color = color.withValues(alpha: life);
      
      canvas.drawCircle(
        position,
        particle.size * life,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ExplosionPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}