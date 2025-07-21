import 'package:flutter/material.dart';

class HeroAnimationWrapper extends StatelessWidget {
  final String tag;
  final Widget child;
  final Widget Function(BuildContext, Widget) builder;

  const HeroAnimationWrapper({
    super.key,
    required this.tag,
    required this.child,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: Material(
        color: Colors.transparent,
        child: builder(context, child),
      ),
    );
  }
}

class ScaleHeroAnimation extends StatefulWidget {
  final String heroTag;
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;

  const ScaleHeroAnimation({
    super.key,
    required this.heroTag,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<ScaleHeroAnimation> createState() => _ScaleHeroAnimationState();
}

class _ScaleHeroAnimationState extends State<ScaleHeroAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
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
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Hero(
        tag: widget.heroTag,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: widget.child,
            );
          },
        ),
      ),
    );
  }
}

class MorphingContainer extends StatefulWidget {
  final Widget child;
  final Color startColor;
  final Color endColor;
  final BorderRadius startRadius;
  final BorderRadius endRadius;
  final Duration duration;
  final bool isExpanded;

  const MorphingContainer({
    super.key,
    required this.child,
    required this.startColor,
    required this.endColor,
    required this.startRadius,
    required this.endRadius,
    this.duration = const Duration(milliseconds: 500),
    this.isExpanded = false,
  });

  @override
  State<MorphingContainer> createState() => _MorphingContainerState();
}

class _MorphingContainerState extends State<MorphingContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late Animation<BorderRadius?> _radiusAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: widget.startColor,
      end: widget.endColor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _radiusAnimation = BorderRadiusTween(
      begin: widget.startRadius,
      end: widget.endRadius,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isExpanded) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(MorphingContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: _radiusAnimation.value,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class ParallaxEffect extends StatefulWidget {
  final Widget child;
  final double parallaxFactor;
  final Axis direction;

  const ParallaxEffect({
    super.key,
    required this.child,
    this.parallaxFactor = 0.5,
    this.direction = Axis.vertical,
  });

  @override
  State<ParallaxEffect> createState() => _ParallaxEffectState();
}

class _ParallaxEffectState extends State<ParallaxEffect> {
  final GlobalKey _key = GlobalKey();
  double _offset = 0.0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          final RenderBox? renderBox =
              _key.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final position = renderBox.localToGlobal(Offset.zero);
            setState(() {
              _offset = position.dy * widget.parallaxFactor;
            });
          }
        }
        return false;
      },
      child: Transform.translate(
        key: _key,
        offset: widget.direction == Axis.vertical
            ? Offset(0, _offset)
            : Offset(_offset, 0),
        child: widget.child,
      ),
    );
  }
}