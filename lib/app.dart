import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/providers.dart';

class NtizaApp extends ConsumerWidget {
  const NtizaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The saved text-size preference scales every piece of text in the app.
    final textScale = ref.watch(settingsControllerProvider.select((s) => s.textScale));
    return MaterialApp.router(
      title: 'NTIZA',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      scrollBehavior: const _DragScrollBehavior(),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: appOverlayStyle,
          child: MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(media.textScaler.scale(1) * textScale),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// Lets a mouse or stylus drag-scroll lists too (Waydroid and desktop report
/// the pointer as a mouse), so horizontal chip rows can always be swiped.
class _DragScrollBehavior extends MaterialScrollBehavior {
  const _DragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}
