import 'dart:async';

import 'package:flutter/material.dart';

/// A lightweight, branded splash used while auth/bootstrap resolves.
/// This works immediately on Web and mobile without native generators.
class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({super.key, this.minDisplayMs = 6000});

  /// Ensure the splash is visible briefly even if auth resolves instantly.
  final int minDisplayMs;

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  Timer? _timer;
  bool _readyToLeave = false;

  /// Call this when the caller is ready to continue beyond the splash.
  void markReadyToLeave() {
    if (mounted) setState(() => _readyToLeave = true);
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(milliseconds: widget.minDisplayMs), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surfaceContainerLowest,
            scheme.surface,
          ],
        ),
      ),
      child: FadeTransition(
        opacity: _fade,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Subtle pattern/blur circle
            Align(
              alignment: const Alignment(-1.2, -1.1),
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.07),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(1.1, 1.2),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.secondary.withValues(alpha: 0.06),
                ),
              ),
            ),

            // Center logo + app name
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand mark
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180, maxHeight: 180),
                    child: Image.asset(
                      'assets/images/Two_M_App_-_All_Your_Needs_One_App_3x.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Two M Vendors',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
