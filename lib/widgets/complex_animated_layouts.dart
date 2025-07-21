import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedDashboard extends StatefulWidget {
  final List<Widget> children;
  final Duration animationDuration;
  final int columns;

  const AnimatedDashboard({
    super.key,
    required this.children,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.columns = 2,
  });

  @override
  State<AnimatedDashboard> createState() => _AnimatedDashboardState();
}

class _AnimatedDashboardState extends State<AnimatedDashboard>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _rotationAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStaggeredAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      ),
    );

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));
    }).toList();

    _rotationAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: math.pi / 4,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ));
    }).toList();

    _slideAnimations = _controllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;
      final row = index ~/ widget.columns;
      final col = index % widget.columns;
      
      return Tween<Offset>(
        begin: Offset(
          (col - widget.columns / 2) * 0.5,
          (row + 1) * 0.3,
        ),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ));
    }).toList();
  }

  void _startStaggeredAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      final delay = Duration(milliseconds: i * 150);
      Future.delayed(delay, () {
        if (mounted) {
          _controllers[i].forward();
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimations[index].value,
              child: Transform.rotate(
                angle: _rotationAnimations[index].value,
                child: Transform.translate(
                  offset: _slideAnimations[index].value * 100,
                  child: widget.children[index],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class FlowingList extends StatefulWidget {
  final List<Widget> children;
  final Duration animationDuration;
  final Axis scrollDirection;

  const FlowingList({
    super.key,
    required this.children,
    this.animationDuration = const Duration(milliseconds: 800),
    this.scrollDirection = Axis.vertical,
  });

  @override
  State<FlowingList> createState() => _FlowingListState();
}

class _FlowingListState extends State<FlowingList>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _waveAnimations;
  late List<Animation<double>> _opacityAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startFlowingAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      ),
    );

    _waveAnimations = _controllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;
      
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(
          index * 0.1,
          1.0,
          curve: Curves.easeOutSine,
        ),
      ));
    }).toList();

    _opacityAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
      ));
    }).toList();
  }

  void _startFlowingAnimations() {
    for (var controller in _controllers) {
      controller.forward();
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
    return ListView.builder(
      scrollDirection: widget.scrollDirection,
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            final waveValue = _waveAnimations[index].value;
            final offset = math.sin(waveValue * math.pi) * 20;
            
            return Transform.translate(
              offset: widget.scrollDirection == Axis.vertical
                  ? Offset(offset, 0)
                  : Offset(0, offset),
              child: Opacity(
                opacity: _opacityAnimations[index].value,
                child: widget.children[index],
              ),
            );
          },
        );
      },
    );
  }
}

class MorphingContainer extends StatefulWidget {
  final Widget child;
  final List<BoxDecoration> decorations;
  final Duration morphDuration;
  final bool autoMorph;

  const MorphingContainer({
    super.key,
    required this.child,
    required this.decorations,
    this.morphDuration = const Duration(seconds: 2),
    this.autoMorph = true,
  });

  @override
  State<MorphingContainer> createState() => _MorphingContainerState();
}

class _MorphingContainerState extends State<MorphingContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentDecorationIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.morphDuration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.autoMorph && widget.decorations.length > 1) {
      _startMorphing();
    }
  }

  void _startMorphing() {
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentDecorationIndex = 
              (_currentDecorationIndex + 1) % widget.decorations.length;
        });
        _controller.reset();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _controller.forward();
          }
        });
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
        final currentDecoration = widget.decorations[_currentDecorationIndex];
        final nextDecoration = widget.decorations[
            (_currentDecorationIndex + 1) % widget.decorations.length];

        return Container(
          decoration: BoxDecoration.lerp(
            currentDecoration,
            nextDecoration,
            _animation.value,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class PulsingOrb extends StatefulWidget {
  final Widget child;
  final Color pulseColor;
  final Duration pulseDuration;
  final double minScale;
  final double maxScale;

  const PulsingOrb({
    super.key,
    required this.child,
    this.pulseColor = const Color(0xFF007AFF),
    this.pulseDuration = const Duration(seconds: 2),
    this.minScale = 0.8,
    this.maxScale = 1.2,
  });

  @override
  State<PulsingOrb> createState() => _PulsingOrbState();
}

class _PulsingOrbState extends State<PulsingOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.pulseDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing background orb
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.pulseColor.withValues(alpha: _opacityAnimation.value),
                  boxShadow: [
                    BoxShadow(
                      color: widget.pulseColor.withValues(alpha: 0.3),
                      blurRadius: 20 * _scaleAnimation.value,
                      spreadRadius: 5 * _scaleAnimation.value,
                    ),
                  ],
                ),
              ),
            ),
            // Content
            widget.child,
          ],
        );
      },
    );
  }
}

class BreathingWidget extends StatefulWidget {
  final Widget child;
  final Duration breathDuration;
  final double breathScale;

  const BreathingWidget({
    super.key,
    required this.child,
    this.breathDuration = const Duration(seconds: 3),
    this.breathScale = 0.05,
  });

  @override
  State<BreathingWidget> createState() => _BreathingWidgetState();
}

class _BreathingWidgetState extends State<BreathingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.breathDuration,
      vsync: this,
    );

    _breathAnimation = Tween<double>(
      begin: 1.0 - widget.breathScale,
      end: 1.0 + widget.breathScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breathAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _breathAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

class SpinningLoader extends StatefulWidget {
  final Widget child;
  final Duration spinDuration;
  final bool reverse;

  const SpinningLoader({
    super.key,
    required this.child,
    this.spinDuration = const Duration(seconds: 1),
    this.reverse = false,
  });

  @override
  State<SpinningLoader> createState() => _SpinningLoaderState();
}

class _SpinningLoaderState extends State<SpinningLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.spinDuration,
      vsync: this,
    );

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
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi * (widget.reverse ? -1 : 1),
          child: widget.child,
        );
      },
    );
  }
}