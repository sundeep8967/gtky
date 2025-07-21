import 'package:flutter/material.dart';
import 'dart:math' as math;

class FloatingActionMenu extends StatefulWidget {
  final List<FloatingActionMenuItem> items;
  final Widget mainButton;
  final Color backgroundColor;
  final double spacing;
  final Duration animationDuration;
  final Curve animationCurve;
  final FloatingActionMenuDirection direction;

  const FloatingActionMenu({
    super.key,
    required this.items,
    required this.mainButton,
    this.backgroundColor = Colors.black54,
    this.spacing = 60.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
    this.direction = FloatingActionMenuDirection.up,
  });

  @override
  State<FloatingActionMenu> createState() => _FloatingActionMenuState();
}

class _FloatingActionMenuState extends State<FloatingActionMenu>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _backgroundController;
  late List<Animation<Offset>> _itemAnimations;
  late List<Animation<double>> _itemScaleAnimations;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _mainButtonRotation;
  
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _backgroundController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: widget.animationCurve),
    );

    _mainButtonRotation = Tween<double>(begin: 0.0, end: math.pi / 4).animate(
      CurvedAnimation(parent: _controller, curve: widget.animationCurve),
    );

    _initializeItemAnimations();
  }

  void _initializeItemAnimations() {
    _itemAnimations = List.generate(widget.items.length, (index) {
      final offset = _getOffsetForDirection(index + 1);
      return Tween<Offset>(begin: Offset.zero, end: offset).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.1,
            1.0,
            curve: widget.animationCurve,
          ),
        ),
      );
    });

    _itemScaleAnimations = List.generate(widget.items.length, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.1,
            1.0,
            curve: Curves.elasticOut,
          ),
        ),
      );
    });
  }

  Offset _getOffsetForDirection(int index) {
    final distance = widget.spacing * index;
    switch (widget.direction) {
      case FloatingActionMenuDirection.up:
        return Offset(0, -distance);
      case FloatingActionMenuDirection.down:
        return Offset(0, distance);
      case FloatingActionMenuDirection.left:
        return Offset(-distance, 0);
      case FloatingActionMenuDirection.right:
        return Offset(distance, 0);
      case FloatingActionMenuDirection.circular:
        final angle = (index - 1) * (math.pi / (widget.items.length - 1)) - math.pi / 2;
        return Offset(
          distance * 0.7 * math.cos(angle),
          distance * 0.7 * math.sin(angle),
        );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
    });

    if (_isOpen) {
      _controller.forward();
      _backgroundController.forward();
    } else {
      _controller.reverse();
      _backgroundController.reverse();
    }
  }

  void _closeMenu() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
      });
      _controller.reverse();
      _backgroundController.reverse();
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
                    onTap: _closeMenu,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: widget.backgroundColor.withOpacity(_backgroundAnimation.value),
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),
        
        // Menu items
        ...List.generate(widget.items.length, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: _itemAnimations[index].value,
                child: Transform.scale(
                  scale: _itemScaleAnimations[index].value,
                  child: FloatingActionButton(
                    heroTag: "fab_menu_${widget.items[index].label}",
                    onPressed: () {
                      widget.items[index].onPressed();
                      _closeMenu();
                    },
                    backgroundColor: widget.items[index].backgroundColor,
                    child: Icon(
                      widget.items[index].icon,
                      color: widget.items[index].iconColor,
                    ),
                  ),
                ),
              );
            },
          );
        }),
        
        // Main button
        AnimatedBuilder(
          animation: _mainButtonRotation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _mainButtonRotation.value,
              child: GestureDetector(
                onTap: _toggle,
                child: widget.mainButton,
              ),
            );
          },
        ),
      ],
    );
  }
}

class FloatingActionMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color iconColor;

  const FloatingActionMenuItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor = Colors.blue,
    this.iconColor = Colors.white,
  });
}

enum FloatingActionMenuDirection {
  up,
  down,
  left,
  right,
  circular,
}

class AnimatedFloatingActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color backgroundColor;
  final double size;
  final Duration animationDuration;

  const AnimatedFloatingActionButton({
    super.key,
    this.onPressed,
    required this.child,
    this.backgroundColor = Colors.blue,
    this.size = 56.0,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<AnimatedFloatingActionButton> createState() => _AnimatedFloatingActionButtonState();
}

class _AnimatedFloatingActionButtonState extends State<AnimatedFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _elevationAnimation = Tween<double>(begin: 6.0, end: 12.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 2),
                  ),
                ],
              ),
              child: Center(child: widget.child),
            ),
          );
        },
      ),
    );
  }
}