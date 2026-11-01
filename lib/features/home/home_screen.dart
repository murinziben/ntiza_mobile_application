import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/equipment_card.dart';
import '../../core/widgets/network_photo.dart';
import '../../data/models/booking.dart';
import '../../data/providers.dart';

const _heroPhoto =
    'https://images.unsplash.com/photo-1682773083912-ff5ee5fa557b?auto=format&fit=crop&w=900&q=82';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final unread = ref.watch(unreadNotificationCountProvider);
    final equipment = ref.watch(equipmentListProvider);
    final recent = ref.watch(recentBookingProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // White header: greeting + location.
            Container(
              color: AppColors.white,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 23, 22, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greetingFor(DateTime.now()),
                              style: const TextStyle(color: AppColors.muted, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.firstName,
                              style: const TextStyle(
                                fontSize: 25,
                                letterSpacing: -0.7,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        _BellButton(
                          showDot: unread > 0,
                          onTap: () => context.go(Routes.notifications),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {}, // location picker comes with the backend step
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(22, 10, 22, 17),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 18, color: AppColors.green),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your location',
                                  style: TextStyle(color: AppColors.muted, fontSize: 9),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Kayonza, Eastern Province',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 17, color: AppColors.green),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 17, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SearchBox(onTap: () => context.go(Routes.explore)),
                  const SizedBox(height: 17),
                  _HeroCard(onTap: () => context.go(Routes.explore)),
                  _SectionTitle(
                    title: 'Services',
                    action: 'See all',
                    onAction: () => context.go(Routes.explore),
                  ),
                  _Categories(onTap: () => context.go(Routes.explore)),
                  _SectionTitle(
                    title: 'Near your farm',
                    action: 'View all',
                    onAction: () => context.go(Routes.explore),
                  ),
                  equipment.when(
                    loading: () => const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => const _Message('Could not load equipment. Please try again.'),
                    data: (list) {
                      if (list.isEmpty) {
                        return const _Message('No equipment near you yet.');
                      }
                      return SizedBox(
                        height: 245,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: list.length > 2 ? 2 : list.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) => EquipmentCard(
                            item: list[i],
                            onTap: () => context.push(Routes.equipment(list[i].id)),
                          ),
                        ),
                      );
                    },
                  ),
                  recent.maybeWhen(
                    data: (b) => b == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 19),
                            child: _BookingStrip(
                              booking: b,
                              onTap: () => context.go(Routes.bookings),
                            ),
                          ),
                    orElse: () => const SizedBox.shrink(),
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

class _BellButton extends StatelessWidget {
  const _BellButton({required this.showDot, required this.onTap});

  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 43,
          height: 43,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications_none, size: 21, color: AppColors.ink),
              if (showDot)
                Positioned(
                  right: 7,
                  top: 6,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.badge,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: const SizedBox(
          height: 49,
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Icon(Icons.search, size: 21, color: Color(0xFF8A958E)),
                SizedBox(width: 10),
                Text(
                  'Search equipment or services',
                  style: TextStyle(color: Color(0xFF8A958E), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.hero),
      child: SizedBox(
        height: 175,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const NetworkPhoto(url: _heroPhoto),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xD9092F1E), Color(0x28092F1E)],
                  stops: [0.05, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(21),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FARM SMARTER',
                      style: TextStyle(
                        color: Color(0xFFBDE6C9),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Get the right machine for your next harvest.',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 19,
                        height: 1.25,
                        letterSpacing: -0.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Material(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: onTap,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Find equipment',
                                style: TextStyle(
                                  color: AppColors.greenDark,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '→',
                                style: TextStyle(
                                  color: AppColors.greenDark,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action, required this.onAction});

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(1, 21, 1, 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          GestureDetector(
            onTap: onAction,
            child: Text(
              action,
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({required this.onTap});

  final VoidCallback onTap;

  static const _items = [
    ('Tractors', 'T'),
    ('Ploughing', 'P'),
    ('Planting', 'S'),
    ('Harvesting', 'H'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(15),
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      _items[i].$2,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _items[i].$1,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BookingStrip extends StatelessWidget {
  const _BookingStrip({required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.stripDark,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: const Color(0x16FFFFFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today_outlined,
                    size: 20, color: AppColors.white),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RECENT BOOKING',
                      style: TextStyle(
                        color: Color(0xFF9DD1AE),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${booking.equipmentName} · ${booking.status.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Requested for ${formatDayMonth(booking.date)}',
                      style: const TextStyle(color: Color(0xFFCBD9D0), fontSize: 9),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      ),
    );
  }
}
