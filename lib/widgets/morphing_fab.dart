import 'package:flutter/material.dart';
import 'dart:math' as math;

class MorphingFAB extends StatefulWidget {
  final List<FABAction> actions;
  final Color primaryColor;
  final Color backgroundColor;
  final IconData mainIcon;
  final Duration animationDuration;
  final double spacing;

  const MorphingFAB({
    super.key,
    required this.actions,
    this.primaryColor = const Color(0xFF007AFF),
    this.backgroundColor = Colors.white,
    this.mainIcon = Icons.add,
    this.animationDuration = const Duration(milliseconds: 300),
    this.spacing = 60.0,
  });

  @override
  State<MorphingFAB> createState() => _MorphingFABState();
}

class _MorphingFABState extends State<MorphingFAB>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _rotationController;
  late List<Animation<Offset>> _offsetAnimations;
  late List<Animation<double>> _scaleAnimations;
  late Animation<double> _rotationAnimation;
  late Animation<double> _backgroundAnimation;
  
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: math.pi / 4, // 45 degrees
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _initializeAnimations();
  }

  void _initializeAnimations() {
    _offsetAnimations = List.generate(widget.actions.length, (index) {
      return Tween<Offset>(
        begin: Offset.zero,
        end: Offset(0, -(index + 1) * widget.spacing),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(
          index * 0.1,
          1.0,
          curve: Curves.elasticOut,
        ),
      ));
    });

    _scaleAnimations = List.generate(widget.actions.length, (index) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(
          index * 0.1,
          1.0,
          curve: Curves.elasticOut,
        ),
      ));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _controller.forward();
      _rotationController.forward();
    } else {
      _controller.reverse();
      _rotationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Background overlay
        AnimatedBuilder(
          animation: _backgroundAnimation,
          builder: (context, child) {
            return _backgroundAnimation.value > 0
                ? GestureDetector(
                    onTap: _toggle,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black.withOpacity(_backgroundAnimation.value * 0.3),
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),
        
        // Action buttons
        ...List.generate(widget.actions.length, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: _offsetAnimations[index].value,
                child: Transform.scale(
                  scale: _scaleAnimations[index].value,
                  child: FloatingActionButton(
                    heroTag: "fab_${widget.actions[index].label}",
                    onPressed: () {
                      widget.actions[index].onPressed();
                      _toggle();
                    },
                    backgroundColor: widget.backgroundColor,
                    child: Icon(
                      widget.actions[index].icon,
                      color: widget.primaryColor,
                    ),
                  ),
                ),
              );
            },
          );
        }),
        
        // Main FAB
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value,
              child: FloatingActionButton(
                heroTag: "main_fab",
                onPressed: _toggle,
                backgroundColor: widget.primaryColor,
                child: Icon(
                  widget.mainIcon,
                  color: widget.backgroundColor,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class FABAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const FABAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}