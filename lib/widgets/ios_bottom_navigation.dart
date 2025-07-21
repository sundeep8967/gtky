import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IOSBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<IOSBottomNavigationItem> items;
  final Color? backgroundColor;
  final double height;

  const IOSBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.height = 83,
  });

  @override
  State<IOSBottomNavigation> createState() => _IOSBottomNavigationState();
}

class _IOSBottomNavigationState extends State<IOSBottomNavigation>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _bounceAnimations;

  @override
  void initState() {
    super.initState();
    _animationControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers
        .map((controller) => Tween<double>(
              begin: 1.0,
              end: 1.2,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: Curves.elasticOut,
            )))
        .toList();

    _bounceAnimations = _animationControllers
        .map((controller) => Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: Curves.elasticOut,
            )))
        .toList();

    // Animate the initially selected item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationControllers[widget.currentIndex].forward();
    });
  }

  @override
  void didUpdateWidget(IOSBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animationControllers[oldWidget.currentIndex].reverse();
      _animationControllers[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor ??
            (isDark ? const Color(0xFF1C1C1E) : Colors.white),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(widget.items.length, (index) {
            return Expanded(
              child: _IOSBottomNavigationButton(
                item: widget.items[index],
                isSelected: index == widget.currentIndex,
                scaleAnimation: _scaleAnimations[index],
                bounceAnimation: _bounceAnimations[index],
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onTap(index);
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _IOSBottomNavigationButton extends StatelessWidget {
  final IOSBottomNavigationItem item;
  final bool isSelected;
  final Animation<double> scaleAnimation;
  final Animation<double> bounceAnimation;
  final VoidCallback onTap;

  const _IOSBottomNavigationButton({
    required this.item,
    required this.isSelected,
    required this.scaleAnimation,
    required this.bounceAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final inactiveColor = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isSelected ? scaleAnimation.value : 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected ? primaryColor : inactiveColor,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? primaryColor : inactiveColor,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class IOSBottomNavigationItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const IOSBottomNavigationItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}