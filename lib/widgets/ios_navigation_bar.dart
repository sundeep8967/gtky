import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IOSNavigationBar extends StatefulWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final bool isLargeTitle;
  final Widget? bottom;

  const IOSNavigationBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.isLargeTitle = false,
    this.bottom,
  });

  @override
  State<IOSNavigationBar> createState() => _IOSNavigationBarState();

  @override
  Size get preferredSize => Size.fromHeight(
        (isLargeTitle ? 96 : 44) + (bottom != null ? 44 : 0),
      );
}

class _IOSNavigationBarState extends State<IOSNavigationBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: widget.backgroundColor ??
                  (isDark ? const Color(0xFF1C1C1E) : Colors.white),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Container(
                    height: widget.isLargeTitle ? 96 : 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: widget.isLargeTitle
                        ? _buildLargeTitleLayout(context)
                        : _buildCompactLayout(context),
                  ),
                  if (widget.bottom != null) widget.bottom!,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Row(
      children: [
        if (widget.leading != null)
          widget.leading!
        else if (widget.showBackButton && Navigator.canPop(context))
          _IOSBackButton(onPressed: widget.onBackPressed),
        Expanded(
          child: widget.title != null
              ? Text(
                  widget.title!,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                )
              : const SizedBox.shrink(),
        ),
        if (widget.actions != null) ...widget.actions! else const SizedBox(width: 44),
      ],
    );
  }

  Widget _buildLargeTitleLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 44,
          child: Row(
            children: [
              if (widget.leading != null)
                widget.leading!
              else if (widget.showBackButton && Navigator.canPop(context))
                _IOSBackButton(onPressed: widget.onBackPressed),
              const Spacer(),
              if (widget.actions != null) ...widget.actions!,
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.title!,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
      ],
    );
  }
}

class _IOSBackButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const _IOSBackButton({this.onPressed});

  @override
  State<_IOSBackButton> createState() => _IOSBackButtonState();
}

class _IOSBackButtonState extends State<_IOSBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
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
    HapticFeedback.lightImpact();
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: () {
        if (widget.onPressed != null) {
          widget.onPressed!();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.centerLeft,
              child: Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
          );
        },
      ),
    );
  }
}