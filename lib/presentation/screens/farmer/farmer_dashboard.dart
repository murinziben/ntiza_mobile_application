import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/pricing.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';
import '../common/role_widgets.dart';
import 'booking_row.dart';

/// Farmer home: greeting, live booking statistics and shortcuts.
class FarmerDashboard extends ConsumerWidget {
  const FarmerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider).valueOrNull ?? const <Booking>[];
    final me = ref.watch(profileProvider).valueOrNull;

    // All numbers come from the farmer's real bookings (BookingStats is domain code).
    final pending = BookingStats.count(bookings, BookingStatus.pending);
    final confirmed = BookingStats.count(bookings, BookingStatus.confirmed);
    final completed = BookingStats.count(bookings, BookingStatus.completed);
    final spent = BookingStats.completedTotal(bookings, (b) => b.total);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                InitialsAvatar(initialsOf(me?.name ?? 'N'),
                    photoUrl: me?.photoUrl ?? '',
                    size: 54,
                    bg: AppColors.primary,
                    fg: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Muraho, ${me?.firstName ?? 'farmer'} 👋',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      Text('Farmer · ${me?.district ?? ''}',
                          style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                    ],
                  ),
                ),
                const BellButton(),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.primaryDark, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Harvest season is here',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                height: 1.2,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        const Text("Book a combine harvester before it's fully booked.",
                            style: TextStyle(color: Colors.white, fontSize: 13)),
                        const SizedBox(height: 10),
                        OutlineButtonX('Book Now',
                            expand: false,
                            compact: true,
                            onPressed: () => context.go('/farmer/book')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const AssetPhoto('harvester.jpg', width: 84, height: 104, radius: 14),
                ],
              ),
            ),
            const SizedBox(height: 16),
            StatGrid([
              StatSpec('${pending + confirmed}', 'Active Bookings', Icons.calendar_today_outlined,
                  AppColors.green100, AppColors.primaryDark),
              StatSpec(
                  '$pending', 'Pending', Icons.schedule, AppColors.amberBg, AppColors.amberText),
              StatSpec('$completed', 'Completed', Icons.check_circle_outline, AppColors.blueBg,
                  AppColors.blue),
              StatSpec(compactRwf(spent), 'Spent (RWF)', Icons.payments_outlined,
                  AppColors.purpleBg, AppColors.purple),
            ]),
            const SizedBox(height: 20),
            SectionHeader('Recent Bookings',
                action: 'View all', onAction: () => context.go('/farmer/bookings')),
            const SizedBox(height: 12),
            if (bookings.isEmpty)
              const EmptyState('No bookings yet',
                  message: 'Book your first machine to get started.',
                  icon: Icons.calendar_month_outlined,
                  padding: 16),
            for (final b in bookings.take(3)) ...[
              BookingRow(booking: b, subtitle: '${b.dateLabel} · ${b.detail} · ${b.place}'),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
