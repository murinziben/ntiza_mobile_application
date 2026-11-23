import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';

/// Branded start screen. It stays for a short minimum time and until the saved
/// session (and profile) have loaded, then hands over to the router: first-time
/// users see the welcome screen, everyone else lands on `/home`, which the
/// router redirects to the signed-in user's own area.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, this.minimum = const Duration(milliseconds: 1700)});
  final Duration minimum;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  Timer? _timer;
  bool _minimumDone = false;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.minimum, () {
      if (mounted) setState(() => _minimumDone = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _intro.value = 1;
      } else {
        _intro.forward();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    super.dispose();
  }

  void _leave() {
    if (_left) return;
    _left = true;
    final seen = ref.read(settingsControllerProvider).onboardingSeen;
    context.go(seen ? '/home' : '/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final profile = ref.watch(profileProvider);
    final identity = session.valueOrNull;
    final ready = !session.isLoading &&
        (identity == null || identity.needsVerification || !profile.isLoading);
    if (_minimumDone && ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _leave();
      });
    }

    final logo =
        CurvedAnimation(parent: _intro, curve: const Interval(0, 0.6, curve: Curves.easeOutCubic));
    final text =
        CurvedAnimation(parent: _intro, curve: const Interval(0.4, 1, curve: Curves.easeOut));

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, AppColors.green50, AppColors.green100],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: logo,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.8, end: 1.0).animate(logo),
                    child: const LogoMark(size: 112),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: text,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(text),
                    child: const Column(
                      children: [
                        Text('NTIZA',
                            style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3,
                                color: AppColors.primaryDark)),
                        SizedBox(height: 6),
                        Text('Digital Agriculture Platform',
                            style: TextStyle(fontSize: 14, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
