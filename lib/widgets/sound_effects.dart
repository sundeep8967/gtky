import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Sound effects manager for animations
class SoundEffects {
  static bool _soundEnabled = true;
  
  /// Enable or disable sound effects
  static void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }
  
  /// Check if sound is enabled
  static bool get isSoundEnabled => _soundEnabled;

  /// Play a tap sound effect
  static void playTap() {
    if (_soundEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Play a success sound effect
  static void playSuccess() {
    if (_soundEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Play an error sound effect
  static void playError() {
    if (_soundEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Play a selection sound effect
  static void playSelection() {
    if (_soundEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Play a vibration pattern
  static void playVibration() {
    if (_soundEnabled) {
      HapticFeedback.vibrate();
    }
  }
}

/// Widget that adds sound effects to animations
class SoundAnimatedWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final SoundType soundType;
  final bool enableHaptic;

  const SoundAnimatedWidget({
    super.key,
    required this.child,
    this.onTap,
    this.soundType = SoundType.tap,
    this.enableHaptic = true,
  });

  @override
  State<SoundAnimatedWidget> createState() => _SoundAnimatedWidgetState();
}

class _SoundAnimatedWidgetState extends State<SoundAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
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
    if (widget.enableHaptic) {
      _playSound();
    }
    
    _controller.forward().then((_) {
      _controller.reverse();
    });
    
    widget.onTap?.call();
  }

  void _playSound() {
    switch (widget.soundType) {
      case SoundType.tap:
        SoundEffects.playTap();
        break;
      case SoundType.success:
        SoundEffects.playSuccess();
        break;
      case SoundType.error:
        SoundEffects.playError();
        break;
      case SoundType.selection:
        SoundEffects.playSelection();
        break;
      case SoundType.vibration:
        SoundEffects.playVibration();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

enum SoundType {
  tap,
  success,
  error,
  selection,
  vibration,
}

/// Enhanced button with sound effects
class SoundButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final SoundType soundType;

  const SoundButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.padding,
    this.borderRadius,
    this.soundType = SoundType.tap,
  });

  @override
  Widget build(BuildContext context) {
    return SoundAnimatedWidget(
      onTap: onPressed,
      soundType: soundType,
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).primaryColor,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: child,
      ),
    );
  }
}

/// Card with sound effects and micro-interactions
class SoundCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Color? color;

  const SoundCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding,
    this.elevation,
    this.borderRadius,
    this.color,
  });

  @override
  State<SoundCard> createState() => _SoundCardState();
}

class _SoundCardState extends State<SoundCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? 2.0,
      end: (widget.elevation ?? 2.0) + 4.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
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

  void _handleTapDown(TapDownDetails details) {
    SoundEffects.playTap();
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
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              margin: widget.margin,
              elevation: _elevationAnimation.value,
              shape: RoundedRectangleBorder(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              ),
              color: widget.color,
              child: Padding(
                padding: widget.padding ?? const EdgeInsets.all(16),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}