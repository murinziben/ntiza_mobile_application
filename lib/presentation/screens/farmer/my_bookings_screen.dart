import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';
import '../public/widgets.dart';
import 'booking_row.dart';

const _tabs = ['Upcoming', 'Past'];

final _tabProvider = StateProvider.autoDispose<String>((ref) => 'Upcoming');

/// The farmer's bookings: open ones under Upcoming, finished ones under Past.
class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  String _subtitle(Booking b) => '${b.dateLabel} · ${b.detail} · ${rwf(b.total)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_tabProvider);

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
          asyncSection(ref.watch(bookingsProvider), (all) {
            final items = all.where((b) => b.earlier == (tab == 'Past')).toList();
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (items.isEmpty)
                    tab == 'Upcoming'
                        ? EmptyState('No upcoming bookings',
                            message: 'Book a machine to get started.',
                            icon: Icons.event_available_outlined,
                            actionLabel: 'Book equipment',
                            onAction: () => context.go('/farmer/book'))
                        : const EmptyState('No past bookings yet',
                            message: 'Completed and cancelled bookings show up here.',
                            icon: Icons.history_rounded),
                  for (var i = 0; i < items.length; i++) ...[
                    FadeSlideIn(
                        index: i,
                        child: BookingRow(booking: items[i], subtitle: _subtitle(items[i]))),
                    const SizedBox(height: 12),
                  ],
                  if (items.isNotEmpty)
                    Text('${items.length} ${items.length == 1 ? 'booking' : 'bookings'}',
                        style: const TextStyle(fontSize: 13.5, color: AppColors.muted)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
