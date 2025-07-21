import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IOSSearchBar extends StatefulWidget {
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final bool autofocus;
  final bool showCancelButton;
  final VoidCallback? onCancel;

  const IOSSearchBar({
    super.key,
    this.placeholder,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.controller,
    this.autofocus = false,
    this.showCancelButton = false,
    this.onCancel,
  });

  @override
  State<IOSSearchBar> createState() => _IOSSearchBarState();
}

class _IOSSearchBarState extends State<IOSSearchBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _cancelButtonAnimation;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _cancelButtonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _focusNode.addListener(() {
      setState(() {
        _isActive = _focusNode.hasFocus;
      });
      if (_isActive) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleCancel() {
    _controller.clear();
    _focusNode.unfocus();
    if (widget.onCancel != null) {
      widget.onCancel!();
    }
    if (widget.onChanged != null) {
      widget.onChanged!('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              onTap: widget.onTap,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: widget.placeholder ?? 'Search',
                hintStyle: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.6)
                      : Colors.black.withOpacity(0.6),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark
                      ? Colors.white.withOpacity(0.6)
                      : Colors.black.withOpacity(0.6),
                  size: 20,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _controller.clear();
                          if (widget.onChanged != null) {
                            widget.onChanged!('');
                          }
                        },
                        child: Icon(
                          Icons.cancel,
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : Colors.black.withOpacity(0.6),
                          size: 20,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ),
        if (widget.showCancelButton || _isActive)
          AnimatedBuilder(
            animation: _cancelButtonAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _cancelButtonAnimation,
                axis: Axis.horizontal,
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: _handleCancel,
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}