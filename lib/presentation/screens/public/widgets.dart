import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';
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

/// Opens the expert booking flow, or the login screen for guests.
void goBookExpert(BuildContext context, WidgetRef ref, String expertId) {
  context.push(ref.read(signedInProvider) ? '/farmer/book-expert/$expertId' : '/login');
}

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
                AssetPhoto(item.image, height: compact ? 118 : 168),
                Positioned(left: 12, top: 12, child: StatusChip(item.availabilityLabel)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
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
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text.rich(TextSpan(children: [
                          TextSpan(
                              text: rwf(item.price),
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark)),
                          TextSpan(
                              text: ' / ${item.unit}',
                              style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                        ])),
                      ),
                      if (!compact) ...[
                        const SizedBox(width: 8),
                        PrimaryButton('Book Now',
                            expand: false,
                            height: 48,
                            onPressed: () => context.push('/equipment/${item.id}')),
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

/// Card for one agricultural expert. Pass [onBook] to show the Book button.
class ExpertCard extends StatelessWidget {
  const ExpertCard({super.key, required this.expert, this.onBook});
  final Expert expert;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            InitialsAvatar(initialsOf(expert.name), size: 62),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expert.name,
                      style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(expert.field,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                  const SizedBox(height: 3),
                  RatingLine(expert.rating, '${expert.years} years experience'),
                  const SizedBox(height: 3),
                  Text(
                    expert.accepting
                        ? '${rwf(expert.fee)} / ${expert.sessionMinutes} min'
                        : 'Not taking new consultations',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: expert.accepting ? AppColors.body : AppColors.danger),
                  ),
                ],
              ),
            ),
            if (onBook != null) ...[
              const SizedBox(width: 8),
              SoftButton('Book', onPressed: expert.accepting ? onBook : null),
            ],
          ],
        ),
      );
}

/// Card for one training course.
class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course, this.onTap});
  final Course course;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final intermediate = course.level == 'Intermediate';
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AssetPhoto(course.image, height: 160),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(spacing: 8, runSpacing: 8, children: [
                  Pill(course.level,
                      big: true,
                      bg: intermediate ? AppColors.blueBg : AppColors.green100,
                      fg: intermediate ? AppColors.blue : AppColors.primaryDark),
                  Pill(course.topic, big: true, bg: AppColors.neutral, fg: AppColors.body),
                ]),
                const SizedBox(height: 12),
                Text(course.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.play_arrow, size: 20, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Text('${course.lessons} lessons · Free',
                      style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Booked: 23 Nov, 25 Nov +2 more" — taken days for the machine card.
String bookedDaysLabel(Equipment e) {
  final days = e.upcomingBookedDays;
  final shown = days.take(2).map(dayMonth).join(', ');
  final more = days.length > 2 ? ' +${days.length - 2} more' : '';
  return 'Booked: $shown$more';
}
