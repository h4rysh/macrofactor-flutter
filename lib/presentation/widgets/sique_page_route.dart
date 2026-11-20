import 'package:flutter/material.dart';
import 'package:sique/presentation/theme/tokens/app_motion.dart';

/// Smooth slide-and-fade page route transition for Sique screens.
///
/// Features:
/// - Slide from right with subtle fade-in.
/// - Respects [MediaQuery.disableAnimationsOf(context)] for reduced motion.
/// - Consistent 250ms duration with [Curves.easeOutCubic].
class SiquePageRoute<T> extends PageRouteBuilder<T> {
  SiquePageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.transitionDuration = AppMotion.normal,
    super.reverseTransitionDuration = AppMotion.normal,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (MediaQuery.disableAnimationsOf(context)) {
              return child;
            }

            const begin = Offset(0.08, 0.0);
            const end = Offset.zero;
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            final slideAnimation =
                Tween<Offset>(begin: begin, end: end).animate(curve);
            final fadeAnimation =
                Tween<double>(begin: 0.0, end: 1.0).animate(curve);

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}
