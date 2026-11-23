import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ntiza/domain/entities/entities.dart';
import 'package:ntiza/presentation/providers/dependencies.dart';
import 'package:ntiza/presentation/screens/public/featured_slider.dart';
import 'package:ntiza/presentation/screens/public/public_shell.dart';
import 'package:ntiza/presentation/screens/public/splash_screen.dart';
import 'package:ntiza/presentation/widgets/ui.dart';

import '../helpers/fakes.dart';

double? _page(WidgetTester t) => t.widget<PageView>(find.byType(PageView)).controller?.page;

Equipment _machine(String id, {bool maintenance = false}) =>
    sampleTractor.copyWith(id: id, name: 'Machine $id', inMaintenance: maintenance);

void main() {
  group('EmptyState', () {
    testWidgets('shows icon, title, hint and runs the action', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmptyState('No machines found',
              message: 'Try another type.',
              icon: Icons.search_off_rounded,
              actionLabel: 'Clear filters',
              onAction: () => tapped = true),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
      expect(find.text('No machines found'), findsOneWidget);
      expect(find.text('Try another type.'), findsOneWidget);
      await tester.tap(find.text('Clear filters'));
      expect(tapped, isTrue);
    });
  });

  group('SearchField', () {
    testWidgets('draws a single pill: the inner text field has no border', (tester) async {
      await tester.pumpWidget(MaterialApp(
        // The app theme gives inputs an outline; it must not show through.
        theme: ThemeData(
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(),
          ),
        ),
        home: const Scaffold(body: SearchField(hint: 'Search')),
      ));

      final field = tester.widget<TextField>(find.byType(TextField));
      final decoration = field.decoration!;
      expect(decoration.border, InputBorder.none);
      expect(decoration.enabledBorder, InputBorder.none);
      expect(decoration.focusedBorder, InputBorder.none);
      expect(decoration.filled, isFalse);
    });

    testWidgets('shows the filter button only when onFilter is given', (tester) async {
      var filtered = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SearchField(hint: 'Search', onFilter: () => filtered = true)),
      ));
      await tester.tap(find.byIcon(Icons.tune_rounded));
      expect(filtered, isTrue);

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SearchField(hint: 'x'))));
      expect(find.byIcon(Icons.tune_rounded), findsNothing);
    });
  });

  group('ChipRow', () {
    testWidgets('chips are compact (36dp) but keep a 44dp touch target', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChipRow(labels: const ['All', 'Crops'], selected: 'All', onSelected: (_) {}),
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(AnimatedContainer).first).height, 36);
      expect(tester.getSize(find.byType(ChipRow)).height, 44);
    });
  });

  group('featuredEquipment', () {
    test('skips machines that cannot be booked and caps the list', () {
      final all = [
        _machine('a', maintenance: true),
        for (var i = 0; i < 7; i++) _machine('m$i'),
      ];
      final featured = featuredEquipment(all, limit: 5);
      expect(featured.length, 5);
      expect(featured.every((e) => e.bookable), isTrue);
    });
  });

  group('FeaturedSlider', () {
    Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('auto-advances to the next machine', (tester) async {
      await tester.pumpWidget(app(FeaturedSlider(
        items: [_machine('1'), _machine('2'), _machine('3')],
        interval: const Duration(seconds: 2),
      )));
      expect(find.text('Machine 1'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      // The second slide is now centered (the first may still peek in).
      final page = _page(tester);
      expect(page, closeTo(1, 0.01));
    });

    testWidgets('does not advance while a finger is down', (tester) async {
      await tester.pumpWidget(app(FeaturedSlider(
        items: [_machine('1'), _machine('2')],
        interval: const Duration(seconds: 2),
      )));

      final gesture = await tester.startGesture(tester.getCenter(find.byType(PageView)));
      await tester.pump(const Duration(seconds: 3));
      final page = _page(tester);
      expect(page, closeTo(0, 0.01));
      await gesture.cancel();
    });

    testWidgets('stays still when system animations are disabled', (tester) async {
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: app(FeaturedSlider(
          items: [_machine('1'), _machine('2')],
          interval: const Duration(seconds: 2),
        )),
      ));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(_page(tester), closeTo(0, 0.01));
    });
  });

  group('NtizaBottomNav', () {
    testWidgets('reports taps and marks the selected item', (tester) async {
      int? tapped;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          bottomNavigationBar: NtizaBottomNav(
            items: publicNav,
            index: 1,
            onTap: (i) => tapped = i,
          ),
        ),
      ));

      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Equipment'), findsOneWidget);
      handle.dispose();
      await tester.tap(find.text('Account'));
      expect(tapped, 3);
    });
  });

  group('SplashScreen', () {
    Future<GoRouter> boot(WidgetTester tester, FakeAuthRepository auth) async {
      final router = GoRouter(initialLocation: '/splash', routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/welcome', builder: (_, __) => const Text('WELCOME')),
        GoRoute(path: '/home', builder: (_, __) => const Text('HOME')),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      return router;
    }

    testWidgets('waits for the saved session, then opens the welcome screen once', (tester) async {
      final auth = FakeAuthRepository();
      await boot(tester, auth);
      expect(find.text('NTIZA'), findsOneWidget);

      // Minimum time passed, but the session is still loading.
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('NTIZA'), findsOneWidget);
      expect(find.text('WELCOME'), findsNothing);

      auth.sessions.add(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('WELCOME'), findsOneWidget);
    });
  });
}
