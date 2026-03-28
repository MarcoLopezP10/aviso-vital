import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class AppTransitions {
  const AppTransitions._();

  static PageRouteBuilder<dynamic> slide(
    RouteSettings settings,
    Widget page,
  ) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOutCubic)).animate(animation),
          child: child,
        );
      },
      transitionDuration: AppDurations.normal,
    );
  }
}
