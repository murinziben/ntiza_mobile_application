import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';
import '../public/widgets.dart';
import 'booking_row.dart';

const _tabs = ['All', 'Upcoming', 'Past'];

final _tabProvider = StateProvider.autoDispose<String>((ref) => 'All');

/// The farmer's bookings screen.
class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  String _subtitle(Booking b) {
    final parts = [b.dateLabel, b.detail, rwf(b.total)];
    return parts.where((p) => p.isNotEmpty).join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_tabProvider);
    final bookingsAsync = ref.watch(bookingsProvider);

    return Scaffold(
      appBar: const TopBar('My Bookings', back: false),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        children: [
          ChipRow(
            labels: _tabs,
            selected: tab,
            onSelected: (v) => ref.read(_tabProvider.notifier).state = v,
          ),
          const SizedBox(height: 8),
          asyncSection(bookingsAsync, (all) {
            final items = switch (tab) {
              'Upcoming' => all.where((b) => !b.earlier).toList(),
              'Past' => all.where((b) => b.earlier).toList(),
              _ => all,
            };

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (items.isEmpty)
                    switch (tab) {
                      'Upcoming' => EmptyState(
                          'No upcoming bookings',
                          message: 'Book a machine to get started.',
                          icon: Icons.event_available_outlined,
                          actionLabel: 'Book equipment',
                          onAction: () => context.go('/farmer/book'),
                        ),
                      'Past' => const EmptyState(
                          'No past bookings yet',
                          message: 'Completed and cancelled bookings show up here.',
                          icon: Icons.history_rounded,
                        ),
                      _ => EmptyState(
                          'No bookings yet',
                          message: 'Explore equipment and make your first booking.',
                          icon: Icons.calendar_month_outlined,
                          actionLabel: 'Browse Equipment',
                          onAction: () => context.go('/farmer/book'),
                        ),
                    },
                  for (var i = 0; i < items.length; i++) ...[
                    FadeSlideIn(
                      index: i,
                      child: BookingRow(
                        booking: items[i],
                        subtitle: _subtitle(items[i]),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (items.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        'Showing ${items.length} ${items.length == 1 ? 'booking' : 'bookings'}',
                        style: const TextStyle(fontSize: 13.5, color: AppColors.muted),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
