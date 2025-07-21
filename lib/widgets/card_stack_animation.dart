import 'package:flutter/material.dart';
import 'dart:math' as math;

class CardStackAnimation extends StatefulWidget {
  final List<Widget> cards;
  final Duration animationDuration;
  final double stackOffset;
  final double rotationAngle;
  final VoidCallback? onCardSwiped;

  const CardStackAnimation({
    super.key,
    required this.cards,
    this.animationDuration = const Duration(milliseconds: 300),
    this.stackOffset = 10.0,
    this.rotationAngle = 0.1,
    this.onCardSwiped,
  });

  @override
  State<CardStackAnimation> createState() => _CardStackAnimationState();
}

class _CardStackAnimationState extends State<CardStackAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _rotationAnimations;
  
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.cards.length,
      (index) => AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      ),
    );

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(2.0, 0.0),
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 1.0,
        end: 0.8,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    _rotationAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: widget.rotationAngle,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _swipeCard() {
    if (_currentIndex < widget.cards.length) {
      _controllers[_currentIndex].forward().then((_) {
        setState(() {
          _currentIndex++;
        });
        widget.onCardSwiped?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _swipeCard,
      child: Stack(
        children: List.generate(
          math.min(3, widget.cards.length - _currentIndex),
          (index) {
            final cardIndex = _currentIndex + index;
            if (cardIndex >= widget.cards.length) return const SizedBox.shrink();

            return AnimatedBuilder(
              animation: _controllers[cardIndex],
              builder: (context, child) {
                return Transform.translate(
                  offset: _slideAnimations[cardIndex].value * 
                         MediaQuery.of(context).size.width,
                  child: Transform.scale(
                    scale: _scaleAnimations[cardIndex].value,
                    child: Transform.rotate(
                      angle: _rotationAnimations[cardIndex].value,
                      child: Transform.translate(
                        offset: Offset(
                          index * widget.stackOffset,
                          index * widget.stackOffset,
                        ),
                        child: widget.cards[cardIndex],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ).reversed.toList(),
      ),
    );
  }
}

class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final Duration duration;
  final bool isFlipped;
  final VoidCallback? onFlip;

  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 600),
    this.isFlipped = false,
    this.onFlip,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _isFlipped = widget.isFlipped;
    if (_isFlipped) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      _flip();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
    
    if (_isFlipped) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    
    widget.onFlip?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final isShowingFront = _animation.value < 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_animation.value * math.pi),
            child: isShowingFront
                ? widget.front
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: widget.back,
                  ),
          );
        },
      ),
    );
  }
}

class ExpandableCard extends StatefulWidget {
  final Widget collapsedChild;
  final Widget expandedChild;
  final Duration duration;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const ExpandableCard({
    super.key,
    required this.collapsedChild,
    required this.expandedChild,
    this.duration = const Duration(milliseconds: 300),
    this.isExpanded = false,
    this.onToggle,
  });

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _heightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    
    _isExpanded = widget.isExpanded;
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ExpandableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      _toggle();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    
    widget.onToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Column(
        children: [
          widget.collapsedChild,
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _heightAnimation.value,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: widget.expandedChild,
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