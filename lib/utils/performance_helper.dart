import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PerformanceHelper {
  // Optimized image loading with caching
  static Widget optimizedNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit? fit,
    Widget? placeholder,
    Widget? errorWidget,
    Duration? fadeInDuration,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 300),
      placeholder: (context, url) => placeholder ?? 
        Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      errorWidget: (context, url, error) => errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        ),
      memCacheWidth: width?.round(),
      memCacheHeight: height?.round(),
    );
  }

  // Optimized list view with lazy loading
  static Widget optimizedListView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      cacheExtent: 500, // Cache 500 pixels ahead
      addAutomaticKeepAlives: false, // Don't keep alive off-screen items
      addRepaintBoundaries: true, // Add repaint boundaries for performance
    );
  }

  // Optimized grid view
  static Widget optimizedGridView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    required SliverGridDelegate gridDelegate,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: gridDelegate,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      cacheExtent: 500,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
    );
  }

  // Debounced text field for search
  static Widget debouncedTextField({
    required TextEditingController controller,
    required Function(String) onChanged,
    Duration debounceDuration = const Duration(milliseconds: 500),
    String? hintText,
    IconData? prefixIcon,
  }) {
    return _DebouncedTextField(
      controller: controller,
      onChanged: onChanged,
      debounceDuration: debounceDuration,
      hintText: hintText,
      prefixIcon: prefixIcon,
    );
  }

  // Optimized animated list
  static Widget optimizedAnimatedList({
    required GlobalKey<AnimatedListState> listKey,
    required Widget Function(BuildContext, int, Animation<double>) itemBuilder,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
  }) {
    return AnimatedList(
      key: listKey,
      itemBuilder: itemBuilder,
      scrollDirection: scrollDirection,
      reverse: reverse,
      controller: controller,
      primary: primary,
      physics: physics,
      shrinkWrap: shrinkWrap,
      padding: padding,
    );
  }

  // Memory-efficient image carousel
  static Widget optimizedPageView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    PageController? controller,
    ValueChanged<int>? onPageChanged,
    bool allowImplicitScrolling = false,
  }) {
    return PageView.builder(
      controller: controller,
      onPageChanged: onPageChanged,
      allowImplicitScrolling: allowImplicitScrolling,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }

  // Optimized tab view
  static Widget optimizedTabBarView({
    required List<Widget> children,
    TabController? controller,
    ScrollPhysics? physics,
  }) {
    return TabBarView(
      controller: controller,
      physics: physics,
      children: children.map((child) => 
        AutomaticKeepAliveClientMixin.wantKeepAlive 
          ? child 
          : _KeepAliveWrapper(child: child)
      ).toList(),
    );
  }

  // Efficient hero animations
  static Widget optimizedHero({
    required String tag,
    required Widget child,
    Duration? transitionDuration,
  }) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: true,
      child: child,
    );
  }

  // Optimized sliver app bar
  static Widget optimizedSliverAppBar({
    required String title,
    List<Widget>? actions,
    Widget? flexibleSpace,
    double? expandedHeight,
    bool pinned = true,
    bool floating = false,
    bool snap = false,
  }) {
    return SliverAppBar(
      title: Text(title),
      actions: actions,
      flexibleSpace: flexibleSpace,
      expandedHeight: expandedHeight,
      pinned: pinned,
      floating: floating,
      snap: snap,
      forceElevated: false, // Better performance
    );
  }
}

// Debounced text field implementation
class _DebouncedTextField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final Duration debounceDuration;
  final String? hintText;
  final IconData? prefixIcon;

  const _DebouncedTextField({
    required this.controller,
    required this.onChanged,
    required this.debounceDuration,
    this.hintText,
    this.prefixIcon,
  });

  @override
  State<_DebouncedTextField> createState() => _DebouncedTextFieldState();
}

class _DebouncedTextFieldState extends State<_DebouncedTextField> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: _onTextChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

// Keep alive wrapper for tab views
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}