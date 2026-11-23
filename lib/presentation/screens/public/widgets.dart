import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/entities.dart';
import '../../widgets/ui.dart';

/// Shows a spinner while loading and a friendly message on error, otherwise
/// builds [data]. Used by every list screen so loading/error states are uniform.
Widget asyncSection<T>(AsyncValue<T> value, Widget Function(T data) data) => value.when(
      data: data,
      loading: () => const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: SkeletonList(),
      ),
      error: (_, __) => const EmptyState('Could not load data',
          message: 'Check your connection and try again.', icon: Icons.wifi_off_rounded),
    );

/// Marketplace card for one machine.
class EquipmentTile extends StatelessWidget {
  const EquipmentTile({super.key, required this.item, this.compact = false});
  final Equipment item;
  final bool compact;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: EdgeInsets.zero,
        onTap: () => context.push('/equipment/${item.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AssetPhoto(item.image, height: compact ? 110 : 150),
                Positioned(left: 12, top: 12, child: StatusChip(item.availabilityLabel)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 17, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(item.place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                    ),
                  ]),
                  if (item.hasUpcomingBookings) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.event_busy, size: 17, color: AppColors.danger),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(bookedDaysLabel(item),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.danger)),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text.rich(TextSpan(children: [
                          TextSpan(
                              text: rwf(item.price),
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark)),
                          TextSpan(
                              text: ' / ${item.unit}',
                              style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                        ])),
                      ),
                      if (!compact) ...[
                        const SizedBox(width: 8),
                        // Greyed out while the machine is in maintenance or fully booked.
                        PrimaryButton(item.bookable ? 'Book' : 'Unavailable',
                            expand: false,
                            compact: true,
                            onPressed:
                                item.bookable ? () => context.push('/equipment/${item.id}') : null),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Compact horizontal card for one machine (photo left, details right).
class EquipmentRow extends StatelessWidget {
  const EquipmentRow({super.key, required this.item});
  final Equipment item;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(10),
        onTap: () => context.push('/equipment/${item.id}'),
        child: Row(
          children: [
            AssetPhoto(item.image, width: 88, height: 88, radius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: AppColors.muted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(item.place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text.rich(TextSpan(children: [
                    TextSpan(
                        text: rwf(item.price),
                        style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark)),
                    TextSpan(
                        text: ' / ${item.unit}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                  ])),
                ],
              ),
            ),
            const SizedBox(width: 6),
            StatusChip(item.availabilityLabel),
          ],
        ),
      );
}

/// "Booked: 23 Nov, 25 Nov +2 more" — taken days for the machine card.
String bookedDaysLabel(Equipment e) {
  final days = e.upcomingBookedDays;
  final shown = days.take(2).map(dayMonth).join(', ');
  final more = days.length > 2 ? ' +${days.length - 2} more' : '';
  return 'Booked: $shown$more';
}
