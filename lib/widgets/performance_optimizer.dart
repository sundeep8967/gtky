import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:io';

/// Performance optimization utilities for animations
class PerformanceOptimizer {
  static bool _isLowEndDevice = false;
  static bool _reduceMotion = false;
  static bool _initialized = false;

  /// Initialize performance settings
  static void initialize() {
    if (_initialized) return;
    
    _isLowEndDevice = _detectLowEndDevice();
    _reduceMotion = _shouldReduceMotion();
    _initialized = true;
  }

  /// Check if device is low-end
  static bool get isLowEndDevice {
    if (!_initialized) initialize();
    return _isLowEndDevice;
  }

  /// Check if motion should be reduced
  static bool get shouldReduceMotion {
    if (!_initialized) initialize();
    return _reduceMotion;
  }

  /// Get optimized animation duration
  static Duration getOptimizedDuration(Duration original) {
    if (shouldReduceMotion) return Duration.zero;
    if (isLowEndDevice) return Duration(milliseconds: (original.inMilliseconds * 0.7).round());
    return original;
  }

  /// Get optimized frame rate
  static int getOptimizedFrameRate() {
    if (isLowEndDevice) return 30;
    return 60;
  }

  /// Create performance-aware animation controller
  static AnimationController createOptimizedController({
    required Duration duration,
    required TickerProvider vsync,
    String? debugLabel,
  }) {
    return AnimationController(
      duration: getOptimizedDuration(duration),
      vsync: vsync,
      debugLabel: debugLabel,
    );
  }

  /// Wrap widget with performance optimizations
  static Widget optimizeWidget(Widget child, {bool enableRepaintBoundary = true}) {
    Widget optimized = child;
    
    if (enableRepaintBoundary) {
      optimized = RepaintBoundary(child: optimized);
    }
    
    return optimized;
  }

  /// Check if complex animations should be enabled
  static bool shouldEnableComplexAnimations() {
    return !isLowEndDevice && !shouldReduceMotion;
  }

  /// Get optimized particle count
  static int getOptimizedParticleCount(int original) {
    if (isLowEndDevice) return (original * 0.3).round();
    if (shouldReduceMotion) return 0;
    return original;
  }

  static bool _detectLowEndDevice() {
    // Simple heuristic - in a real app, you might use device_info_plus
    // to get more detailed device information
    try {
      if (Platform.isAndroid) {
        // Assume older Android devices are low-end
        return false; // Would need device_info_plus for real detection
      } else if (Platform.isIOS) {
        // Assume older iOS devices are low-end
        return false; // Would need device_info_plus for real detection
      }
    } catch (e) {
      // Fallback for web or other platforms
    }
    return false;
  }

  static bool _shouldReduceMotion() {
    // Check system accessibility settings
    // This would typically use platform channels or packages like accessibility_tools
    return false;
  }
}

/// Performance-aware animation widget
class OptimizedAnimatedWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final AnimationBuilder builder;
  final bool enableOnLowEnd;

  const OptimizedAnimatedWidget({
    super.key,
    required this.child,
    required this.duration,
    required this.builder,
    this.curve = Curves.easeInOut,
    this.enableOnLowEnd = false,
  });

  @override
  State<OptimizedAnimatedWidget> createState() => _OptimizedAnimatedWidgetState();
}

class _OptimizedAnimatedWidgetState extends State<OptimizedAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    if (!widget.enableOnLowEnd && PerformanceOptimizer.isLowEndDevice) {
      // Skip animation on low-end devices
      _controller = AnimationController(vsync: this);
      _animation = AlwaysStoppedAnimation(1.0);
      return;
    }

    _controller = PerformanceOptimizer.createOptimizedController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableOnLowEnd && PerformanceOptimizer.isLowEndDevice) {
      return widget.child;
    }

    return PerformanceOptimizer.optimizeWidget(
      AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => widget.builder(context, _animation.value, widget.child),
      ),
    );
  }
}

typedef AnimationBuilder = Widget Function(BuildContext context, double value, Widget child);

/// Memory-efficient list animation
class OptimizedListAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration itemDuration;
  final int maxVisibleItems;

  const OptimizedListAnimation({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.itemDuration = const Duration(milliseconds: 600),
    this.maxVisibleItems = 10,
  });

  @override
  State<OptimizedListAnimation> createState() => _OptimizedListAnimationState();
}

class _OptimizedListAnimationState extends State<OptimizedListAnimation> {
  final Set<int> _animatedIndices = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Animate initial visible items
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateVisibleItems();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _animateVisibleItems();
  }

  void _animateVisibleItems() {
    if (!mounted) return;
    
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final viewportHeight = renderBox.size.height;
    final scrollOffset = _scrollController.offset;
    
    for (int i = 0; i < widget.children.length; i++) {
      if (_animatedIndices.contains(i)) continue;
      
      final itemOffset = i * 100.0; // Approximate item height
      if (itemOffset >= scrollOffset - 100 && 
          itemOffset <= scrollOffset + viewportHeight + 100) {
        setState(() {
          _animatedIndices.add(i);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        if (!_animatedIndices.contains(index)) {
          return const SizedBox(height: 100); // Placeholder
        }
        
        return OptimizedAnimatedWidget(
          duration: widget.itemDuration,
          enableOnLowEnd: false,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: widget.children[index],
        );
      },
    );
  }
}

/// Frame rate monitor for debugging
class FrameRateMonitor extends StatefulWidget {
  final Widget child;
  final bool showOverlay;

  const FrameRateMonitor({
    super.key,
    required this.child,
    this.showOverlay = false,
  });

  @override
  State<FrameRateMonitor> createState() => _FrameRateMonitorState();
}

class _FrameRateMonitorState extends State<FrameRateMonitor> {
  double _fps = 0.0;
  int _frameCount = 0;
  DateTime _lastTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.showOverlay) {
      SchedulerBinding.instance.addPostFrameCallback(_onFrame);
    }
  }

  void _onFrame(Duration timestamp) {
    if (!mounted) return;
    
    _frameCount++;
    final now = DateTime.now();
    final elapsed = now.difference(_lastTime);
    
    if (elapsed.inMilliseconds >= 1000) {
      setState(() {
        _fps = _frameCount / elapsed.inSeconds;
        _frameCount = 0;
        _lastTime = now;
      });
    }
    
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showOverlay)
          Positioned(
            top: 50,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'FPS: ${_fps.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}