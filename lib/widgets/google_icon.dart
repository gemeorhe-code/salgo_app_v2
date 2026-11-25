import 'package:flutter/material.dart';

class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.g_mobiledata, size: size * 1.5);
  }
}
