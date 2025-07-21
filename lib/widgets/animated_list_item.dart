import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final AnimationType animationType;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.animationType = AnimationType.slideUp,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

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

    _slideAnimation = _getSlideAnimation();
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _startAnimation();
  }

  Animation<Offset> _getSlideAnimation() {
    switch (widget.animationType) {
      case AnimationType.slideUp:
        return Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
      case AnimationType.slideDown:
        return Tween<Offset>(
          begin: const Offset(0, -0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
      case AnimationType.slideLeft:
        return Tween<Offset>(
          begin: const Offset(-0.3, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
      case AnimationType.slideRight:
        return Tween<Offset>(
          begin: const Offset(0.3, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
      case AnimationType.scale:
      case AnimationType.fade:
      case AnimationType.rotation:
        return Tween<Offset>(
          begin: Offset.zero,
          end: Offset.zero,
        ).animate(_controller);
    }
  }

  void _startAnimation() {
    Future.delayed(
      Duration(milliseconds: widget.index * widget.delay.inMilliseconds),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
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
        Widget animatedChild = widget.child;

        switch (widget.animationType) {
          case AnimationType.slideUp:
          case AnimationType.slideDown:
          case AnimationType.slideLeft:
          case AnimationType.slideRight:
            animatedChild = SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: animatedChild,
              ),
            );
            break;
          case AnimationType.scale:
            animatedChild = ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: animatedChild,
              ),
            );
            break;
          case AnimationType.fade:
            animatedChild = FadeTransition(
              opacity: _fadeAnimation,
              child: animatedChild,
            );
            break;
          case AnimationType.rotation:
            animatedChild = Transform.rotate(
              angle: _rotationAnimation.value,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: animatedChild,
              ),
            );
            break;
        }

        return animatedChild;
      },
    );
  }
}

enum AnimationType {
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
  scale,
  fade,
  rotation,
}

class StaggeredListView extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration itemDuration;
  final Curve curve;
  final AnimationType animationType;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  const StaggeredListView({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.itemDuration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.animationType = AnimationType.slideUp,
    this.physics,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: physics,
      padding: padding,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return AnimatedListItem(
          index: index,
          delay: staggerDelay,
          duration: itemDuration,
          curve: curve,
          animationType: animationType,
          child: children[index],
        );
      },
    );
  }
}

class WaveListAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration waveSpeed;
  final double amplitude;
  final double frequency;

  const WaveListAnimation({
    super.key,
    required this.children,
    this.waveSpeed = const Duration(seconds: 2),
    this.amplitude = 10.0,
    this.frequency = 1.0,
  });

  @override
  State<WaveListAnimation> createState() => _WaveListAnimationState();
}

class _WaveListAnimationState extends State<WaveListAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.waveSpeed,
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView.builder(
          itemCount: widget.children.length,
          itemBuilder: (context, index) {
            final offset = math.sin(_animation.value + index * widget.frequency) * widget.amplitude;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: widget.children[index],
            );
          },
        );
      },
    );
  }
}