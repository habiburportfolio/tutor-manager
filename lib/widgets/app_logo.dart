import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    if (settings.customLogoBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(settings.customLogoBase64);
        return Image.memory(bytes, width: size, height: size, fit: BoxFit.contain);
      } catch (_) {
        // Fallback if decoding fails
      }
    }
    return Image.asset('assets/logo.png', width: size, height: size, fit: BoxFit.contain);
  }
}
