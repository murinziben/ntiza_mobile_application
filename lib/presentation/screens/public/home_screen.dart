import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';
import 'featured_slider.dart';
import 'marketplace_screen.dart';
import 'widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipment = ref.watch(equipmentProvider).valueOrNull ?? const <Equipment>[];
    final signedIn = ref.watch(signedInProvider);
    final available = [
      for (final e in equipment)
        if (e.bookable && e.availability == Availability.freeToday) e
    ].take(4).toList();

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Hero(signedIn: signedIn),
          CategoryTiles(
            items: [
              for (final t in marketplaceTypes)
                if (t.$1 != 'All') t
            ],
            selected: '',
            onSelected: (type) {
              ref.read(marketplaceTypeProvider.notifier).state = type;
              context.go('/equipment');
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: SectionHeader('Featured Equipment',
                action: 'See all', onAction: () => context.go('/equipment')),
          ),
          if (equipment.isNotEmpty) FeaturedSlider(items: featuredEquipment(equipment)),
          if (equipment.isEmpty)
            const EmptyState('No equipment listed yet',
                message: 'New machines will appear here.',
                icon: Icons.agriculture_outlined,
                padding: 16),
          if (available.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: SectionHeader('Available now',
                  action: 'See all', onAction: () => context.go('/equipment')),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final e in available) ...[
                    EquipmentRow(item: e),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
          if (!signedIn)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ready to grow with NTIZA?',
                        style: TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('Join thousands of farmers and equipment owners across Rwanda.',
                        style: TextStyle(color: Colors.white, fontSize: 14.5, height: 1.4)),
                    const SizedBox(height: 14),
                    OutlineButtonX('Create Free Account',
                        expand: false, compact: true, onPressed: () => context.push('/register')),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Photo header with the headline, a search bar and a bell/settings button.
class _Hero extends StatelessWidget {
  const _Hero({required this.signedIn});
  final bool signedIn;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightStatusBarStyle,
      child: Column(
        children: [
          SizedBox(
            height: 270,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const AssetPhoto('hero_villagers.jpg'),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x99000000), Color(0x33000000), Color(0xB3000000)],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const LogoLockup(light: true, size: 40),
                            // Signed-in users see notifications; guests get settings.
                            Material(
                              color: const Color(0x55FFFFFF),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () =>
                                    context.push(signedIn ? '/notifications' : '/settings'),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Center(
                                    child: signedIn
                                        ? const BellIcon(light: true)
                                        : const Icon(Icons.settings_outlined,
                                            color: Colors.white, semanticLabel: 'Settings'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text('Hire farm equipment, near you',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                height: 1.2,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        const Text('Tractors, harvesters, pumps and more from trusted owners.',
                            style: TextStyle(color: Colors.white, fontSize: 14.5, height: 1.4)),
                        const SizedBox(height: 44),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1A000000), blurRadius: 14, offset: Offset(0, 4))
                  ],
                ),
                child: Builder(
                  builder: (context) => SearchField(
                      hint: 'Search tractors, harvesters, pumps…',
                      onTap: () => context.go('/equipment')),
                ),
              ),
            ),
          ),
        ],
      ));
}
