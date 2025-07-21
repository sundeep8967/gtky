import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum IOSButtonStyle {
  filled,
  tinted,
  gray,
  plain,
}

enum IOSButtonSize {
  small,
  medium,
  large,
}

class IOSButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IOSButtonStyle style;
  final IOSButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isDestructive;
  final Color? customColor;
  final double? width;

  const IOSButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style = IOSButtonStyle.filled,
    this.size = IOSButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isDestructive = false,
    this.customColor,
    this.width,
  });

  @override
  State<IOSButton> createState() => _IOSButtonState();
}

class _IOSButtonState extends State<IOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      HapticFeedback.lightImpact();
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  Color _getBackgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (widget.customColor != null) {
      return widget.customColor!;
    }

    if (widget.isDestructive) {
      return const Color(0xFFFF3B30);
    }

    switch (widget.style) {
      case IOSButtonStyle.filled:
        return theme.primaryColor;
      case IOSButtonStyle.tinted:
        return theme.primaryColor.withOpacity(0.15);
      case IOSButtonStyle.gray:
        return isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
      case IOSButtonStyle.plain:
        return Colors.transparent;
    }
  }

  Color _getTextColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.isDestructive && widget.style != IOSButtonStyle.filled) {
      return const Color(0xFFFF3B30);
    }

    switch (widget.style) {
      case IOSButtonStyle.filled:
        return Colors.white;
      case IOSButtonStyle.tinted:
      case IOSButtonStyle.plain:
        return widget.customColor ?? theme.primaryColor;
      case IOSButtonStyle.gray:
        return isDark ? Colors.white : Colors.black;
    }
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case IOSButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case IOSButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case IOSButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case IOSButtonSize.small:
        return 15;
      case IOSButtonSize.medium:
        return 17;
      case IOSButtonSize.large:
        return 19;
    }
  }

  double _getBorderRadius() {
    switch (widget.size) {
      case IOSButtonSize.small:
        return 8;
      case IOSButtonSize.medium:
        return 10;
      case IOSButtonSize.large:
        return 12;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                width: widget.width,
                padding: _getPadding(),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(context),
                  borderRadius: BorderRadius.circular(_getBorderRadius()),
                  border: widget.style == IOSButtonStyle.gray
                      ? Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 0.5,
                        )
                      : null,
                ),
                child: widget.isLoading
                    ? SizedBox(
                        height: _getFontSize() + 2,
                        width: _getFontSize() + 2,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getTextColor(context),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: _getTextColor(context),
                              size: _getFontSize(),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: TextStyle(
                              color: _getTextColor(context),
                              fontSize: _getFontSize(),
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}