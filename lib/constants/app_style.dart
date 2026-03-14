import 'package:flutter/material.dart';

class AppStyle {
  static var boxShadowVariation1 = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.17),
      blurRadius: 4,
      offset: Offset(0, 5),
    ),
  ];

  static var boxShadowVariation2 = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: Offset(0, 3),
    ),
  ];

  static var boxShadowVariation3 = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
}
