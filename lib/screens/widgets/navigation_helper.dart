import 'package:flutter/material.dart';

class NavigationHelper {
  static void navigate(BuildContext context, String label) {
    switch (label) {
      case 'Home':
        Navigator.pushNamed(context, '/homepage');
        break;
      case 'Analysis':
        Navigator.pushNamed(context, '/analysis');
        break;
      case 'Goals':
        Navigator.pushNamed(context, '/achievement');
        break;
      case 'Settings':
        Navigator.pushNamed(context, '/profilescreen');
        break;
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label screen coming soon!')));
    }
  }
}
