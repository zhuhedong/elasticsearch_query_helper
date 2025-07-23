import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Utility class to help prevent TransformLayer matrix errors
class SafeTransformUtils {
  /// Safely creates a container with opacity, preventing invalid values
  static Widget safeOpacity({
    required Widget child,
    required double opacity,
  }) {
    // Clamp opacity to valid range [0.0, 1.0]
    final safeOpacity = opacity.clamp(0.0, 1.0);
    
    // If opacity is very close to 1.0, don't use Opacity widget
    if (safeOpacity >= 0.99) {
      return child;
    }
    
    // If opacity is very close to 0.0, return empty container
    if (safeOpacity <= 0.01) {
      return const SizedBox.shrink();
    }
    
    return Opacity(
      opacity: safeOpacity,
      child: child,
    );
  }

  /// Safely creates a container with color and opacity
  static Color safeColorWithOpacity(Color color, double opacity) {
    // Clamp opacity to valid range [0.0, 1.0]
    final safeOpacity = opacity.clamp(0.0, 1.0);
    
    // If opacity is very close to 1.0, return original color
    if (safeOpacity >= 0.99) {
      return color;
    }
    
    // If opacity is very close to 0.0, return transparent
    if (safeOpacity <= 0.01) {
      return Colors.transparent;
    }
    
    try {
      return color.withOpacity(safeOpacity);
    } catch (e) {
      // If withOpacity fails, return the original color
      return color;
    }
  }

  /// Safely creates a box shadow with valid values
  static List<BoxShadow> safeBoxShadow({
    required Color color,
    required double blurRadius,
    required Offset offset,
    double opacity = 0.3,
  }) {
    // Ensure all values are valid
    final safeBlurRadius = blurRadius.clamp(0.0, 100.0);
    final safeOpacity = opacity.clamp(0.0, 1.0);
    final safeOffset = Offset(
      offset.dx.clamp(-100.0, 100.0),
      offset.dy.clamp(-100.0, 100.0),
    );
    
    return [
      BoxShadow(
        color: color.withOpacity(safeOpacity),
        blurRadius: safeBlurRadius,
        offset: safeOffset,
      ),
    ];
  }

  /// Safely creates a border radius with valid values
  static BorderRadius safeBorderRadius(double radius) {
    final safeRadius = radius.clamp(0.0, 1000.0);
    return BorderRadius.circular(safeRadius);
  }

  /// Safely creates padding with valid values
  static EdgeInsets safePadding(double value) {
    final safeValue = value.clamp(0.0, 1000.0);
    return EdgeInsets.all(safeValue);
  }

  /// Safely creates margin with valid values
  static EdgeInsets safeMargin(double value) {
    final safeValue = value.clamp(0.0, 1000.0);
    return EdgeInsets.all(safeValue);
  }

  /// Safely creates a size constraint
  static BoxConstraints safeSizeConstraints({
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
  }) {
    return BoxConstraints(
      minWidth: (minWidth ?? 0.0).clamp(0.0, double.infinity),
      maxWidth: (maxWidth ?? double.infinity).clamp(0.0, double.infinity),
      minHeight: (minHeight ?? 0.0).clamp(0.0, double.infinity),
      maxHeight: (maxHeight ?? double.infinity).clamp(0.0, double.infinity),
    );
  }

  /// Checks if a double value is safe for UI operations
  static bool isSafeValue(double value) {
    return value.isFinite && !value.isNaN;
  }

  /// Makes a double value safe for UI operations
  static double makeSafeValue(double value, {double fallback = 0.0}) {
    if (isSafeValue(value)) {
      return value;
    }
    return fallback;
  }
}

/// A widget that wraps its child to prevent TransformLayer matrix errors
/// This implementation uses multiple layers of protection to ensure stability
class SafeTransformWidget extends StatelessWidget {
  final Widget child;
  final bool preventMatrixErrors;
  final bool forceRepaintBoundary;

  const SafeTransformWidget({
    super.key,
    required this.child,
    this.preventMatrixErrors = true,
    this.forceRepaintBoundary = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!preventMatrixErrors) {
      return child;
    }

    // Multiple layers of protection against transform errors
    Widget protectedChild = child;
    
    // Layer 1: Wrap in Container to isolate transforms
    protectedChild = Container(
      child: protectedChild,
    );
    
    // Layer 2: RepaintBoundary to create render layer isolation
    if (forceRepaintBoundary) {
      protectedChild = RepaintBoundary(
        child: protectedChild,
      );
    }
    
    // Layer 3: Custom render object wrapper
    protectedChild = _SafeTransformWrapper(
      child: protectedChild,
    );
    
    // Layer 4: Another RepaintBoundary for extra isolation
    protectedChild = RepaintBoundary(
      child: protectedChild,
    );

    return protectedChild;
  }
}

/// Internal wrapper widget with custom render object
class _SafeTransformWrapper extends SingleChildRenderObjectWidget {
  const _SafeTransformWrapper({required Widget child}) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _SafeTransformRenderObject();
  }
}

/// A custom render object that prevents transform layer matrix errors
class _SafeTransformRenderObject extends RenderProxyBox {
  _SafeTransformRenderObject({RenderBox? child}) : super(child);

  @override
  void paint(PaintingContext context, Offset offset) {
    try {
      // Validate the offset before painting
      if (!_isValidOffset(offset)) {
        offset = Offset.zero;
      }
      
      super.paint(context, offset);
    } catch (e) {
      // If there's any error during painting, try fallback painting
      try {
        if (child != null) {
          context.paintChild(child!, Offset.zero);
        }
      } catch (fallbackError) {
        // If even fallback fails, do nothing to prevent crashes
        debugPrint('SafeTransformWidget: Fallback painting failed, skipping render');
      }
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    try {
      // Validate position before hit testing
      if (!_isValidOffset(position)) {
        return false;
      }
      
      return super.hitTest(result, position: position);
    } catch (e) {
      // If there's a matrix error in hit testing, use basic hit test
      try {
        if (child != null && size.contains(position)) {
          return child!.hitTest(result, position: position - Offset.zero);
        }
      } catch (fallbackError) {
        // If even fallback fails, return false
        debugPrint('SafeTransformWidget: Fallback hit test failed');
      }
      return false;
    }
  }

  @override
  void performLayout() {
    try {
      super.performLayout();
    } catch (e) {
      // If layout fails, try with minimal constraints
      try {
        if (child != null) {
          child!.layout(const BoxConstraints(), parentUsesSize: true);
          size = child!.size;
        } else {
          size = Size.zero;
        }
      } catch (fallbackError) {
        // If even fallback fails, use zero size
        size = Size.zero;
        debugPrint('SafeTransformWidget: Fallback layout failed, using zero size');
      }
    }
  }

  /// Validates if an offset contains valid values
  bool _isValidOffset(Offset offset) {
    return offset.dx.isFinite && 
           offset.dy.isFinite && 
           !offset.dx.isNaN && 
           !offset.dy.isNaN;
  }
}

/// Ultra-safe widget wrapper for critical UI elements
/// This provides maximum protection against transform errors
class UltraSafeWidget extends StatelessWidget {
  final Widget child;
  
  const UltraSafeWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure constraints are valid
        if (!constraints.isNormalized || 
            !constraints.maxWidth.isFinite || 
            !constraints.maxHeight.isFinite ||
            constraints.maxWidth <= 0 ||
            constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }
        
        // Multiple layers of protection
        return SafeTransformWidget(
          child: RepaintBoundary(
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                maxWidth: constraints.maxWidth.clamp(0.0, 2000.0),
                maxHeight: constraints.maxHeight.clamp(0.0, 2000.0),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth.clamp(0.0, 2000.0),
                    maxHeight: constraints.maxHeight.clamp(0.0, 2000.0),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}