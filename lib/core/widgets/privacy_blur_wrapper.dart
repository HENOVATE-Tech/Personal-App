import 'dart:ui';
import 'package:flutter/material.dart';
import '../database/local_database.dart';

class PrivacyBlurWrapper extends StatelessWidget {
  final Widget child;
  final bool forceBlur;

  const PrivacyBlurWrapper({
    super.key,
    required this.child,
    this.forceBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPrivacyActive = forceBlur || LocalDatabase.instance.userProfile.privacyModeEnabled;

    if (!isPrivacyActive) {
      return child;
    }

    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: child,
    );
  }
}
