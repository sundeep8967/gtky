import 'package:flutter/material.dart';

class StaggeredAnimationList extends StatefulWidget {
  final List<Widget> children;
  final Duration animationDuration;
  final Duration staggerDelay;
  final Curve curve;
  final Axis direction;
  final double offset;

  const StaggeredAnimationList({
    super.key,
    required this.children,
    this.animationDuration = const Duration(milliseconds: 600),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.curve = Curves.easeOutCubic,
    this.direction = Axis.vertical,
    this.offset = 50.0,
  });

  @override
  State<StaggeredAnimationList> createState() => _StaggeredAnimationListState();
}

class _StaggeredAnimationListState extends State<StaggeredAnimationList>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

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

    _slideAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: widget.offset,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
    }).toList();

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(0.0, 0.8, curve: widget.curve),
      ));
    }).toList();
  }

  void _startStaggeredAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.staggerDelay * i, () {
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
    return Column(
      children: List.generate(widget.children.length, (index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            final slideValue = _slideAnimations[index].value;
            final fadeValue = _fadeAnimations[index].value;

            return Transform.translate(
              offset: widget.direction == Axis.vertical
                  ? Offset(0, slideValue)
                  : Offset(slideValue, 0),
              child: Opacity(
                opacity: fadeValue,
                child: widget.children[index],
              ),
            );
          },
        );
      }),
    );
  }
}

class StaggeredGrid extends StatefulWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final Duration animationDuration;
  final Duration staggerDelay;
  final Curve curve;

  const StaggeredGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.animationDuration = const Duration(milliseconds: 800),
    this.staggerDelay = const Duration(milliseconds: 150),
    this.curve = Curves.elasticOut,
  });

  @override
  State<StaggeredGrid> createState() => _StaggeredGridState();
}

class _StaggeredGridState extends State<StaggeredGrid>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _rotationAnimations;

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
        curve: widget.curve,
      ));
    }).toList();

    _rotationAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.1,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ));
    }).toList();
  }

  void _startStaggeredAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      // Calculate delay based on grid position for wave effect
      final row = i ~/ widget.crossAxisCount;
      final col = i % widget.crossAxisCount;
      final delay = Duration(
        milliseconds: (row + col) * widget.staggerDelay.inMilliseconds ~/ 2,
      );

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
        crossAxisCount: widget.crossAxisCount,
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
                child: widget.children[index],
              ),
            );
          },
        );
      },
    );
  }
}