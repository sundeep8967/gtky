import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class AccessibilityHelper {
  // Semantic labels for common UI elements
  static const String buttonLabel = 'Button';
  static const String textFieldLabel = 'Text input field';
  static const String imageLabel = 'Image';
  static const String cardLabel = 'Card';
  static const String listItemLabel = 'List item';

  // Create accessible button
  static Widget accessibleButton({
    required Widget child,
    required VoidCallback? onPressed,
    String? semanticLabel,
    String? tooltip,
    bool excludeSemantics = false,
  }) {
    Widget button = ElevatedButton(
      onPressed: onPressed,
      child: child,
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip,
        child: button,
      );
    }

    if (semanticLabel != null && !excludeSemantics) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        enabled: onPressed != null,
        child: button,
      );
    }

    return button;
  }

  // Create accessible text field
  static Widget accessibleTextField({
    required TextEditingController? controller,
    String? labelText,
    String? hintText,
    String? semanticLabel,
    bool required = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Semantics(
      label: semanticLabel ?? labelText ?? hintText,
      textField: true,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  // Create accessible image
  static Widget accessibleImage({
    required ImageProvider image,
    String? semanticLabel,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Semantics(
      label: semanticLabel ?? 'Image',
      image: true,
      child: Image(
        image: image,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: semanticLabel,
      ),
    );
  }

  // Create accessible list item
  static Widget accessibleListItem({
    required Widget child,
    VoidCallback? onTap,
    String? semanticLabel,
    bool selected = false,
  }) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      selected: selected,
      child: ListTile(
        onTap: onTap,
        child: child,
      ),
    );
  }

  // Announce message to screen reader
  static void announceMessage(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  // Check if accessibility features are enabled
  static bool isAccessibilityEnabled(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.accessibleNavigation ||
           mediaQuery.boldText ||
           mediaQuery.highContrast;
  }

  // Get accessible text scale
  static double getAccessibleTextScale(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor.clamp(1.0, 2.0);
  }

  // Create focus traversal order
  static Widget createFocusTraversalGroup({
    required Widget child,
    FocusTraversalPolicy? policy,
  }) {
    return FocusTraversalGroup(
      policy: policy ?? OrderedTraversalPolicy(),
      child: child,
    );
  }

  // Create accessible card with proper semantics
  static Widget accessibleCard({
    required Widget child,
    VoidCallback? onTap,
    String? semanticLabel,
    String? semanticHint,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: onTap != null,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }

  // Create accessible navigation
  static Widget accessibleNavigation({
    required List<Widget> children,
    String? semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel ?? 'Navigation',
      container: true,
      child: Row(
        children: children,
      ),
    );
  }

  // High contrast color helper
  static Color getHighContrastColor(BuildContext context, Color defaultColor) {
    final mediaQuery = MediaQuery.of(context);
    if (mediaQuery.highContrast) {
      // Return high contrast version
      return defaultColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    }
    return defaultColor;
  }

  // Accessible loading indicator
  static Widget accessibleLoadingIndicator({
    String? semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel ?? 'Loading',
      liveRegion: true,
      child: const CircularProgressIndicator(),
    );
  }

  // Create accessible form
  static Widget accessibleForm({
    required GlobalKey<FormState> formKey,
    required List<Widget> children,
    String? semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel ?? 'Form',
      container: true,
      child: Form(
        key: formKey,
        child: Column(
          children: children,
        ),
      ),
    );
  }
}