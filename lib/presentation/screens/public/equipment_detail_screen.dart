import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';

/// Full description of one machine with a sticky "Book Now" bar.
class EquipmentDetailScreen extends ConsumerWidget {
  const EquipmentDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(equipmentByIdProvider(id));
    if (e == null) {
      return const Scaffold(
        appBar: TopBar('Equipment'),
        body: EmptyState('Machine not found',
            message: 'This machine is no longer listed.', icon: Icons.agriculture_outlined),
      );
    }
    final signedIn = ref.watch(signedInProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: lightStatusBarStyle,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    SizedBox(
                      height: 280,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AssetPhoto(e.image),
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: CircleIconButton(
                                  icon: Icons.arrow_back_ios_new_rounded,
                                  label: 'Back',
                                  onTap: () =>
                                      context.canPop() ? context.pop() : context.go('/equipment'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -26),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(e.name,
                                      style: const TextStyle(
                                          fontSize: 24, fontWeight: FontWeight.w800)),
                                ),
                                const SizedBox(width: 8),
                                StatusChip(e.availabilityLabel),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(children: [
                              const Icon(Icons.location_on, size: 20, color: AppColors.muted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                    e.sector.isEmpty
                                        ? e.district
                                        : '${e.district} · ${e.sector} sector',
                                    style: const TextStyle(fontSize: 16, color: AppColors.muted)),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _OwnerCard(equipment: e),
                            if (e.specs.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [for (final s in e.specs) _SpecBox(spec: s)],
                              ),
                            ],
                            const SizedBox(height: 22),
                            const Text('About',
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            Text(e.about.isEmpty ? 'No description provided.' : e.about,
                                style: const TextStyle(
                                    fontSize: 16, height: 1.5, color: AppColors.body)),
                            if (e.hasUpcomingBookings) ...[
                              const SizedBox(height: 18),
                              _DaysNote(
                                  days: e.upcomingBookedDays,
                                  label: 'Already booked on',
                                  color: AppColors.danger,
                                  bg: AppColors.dangerBg),
                            ],
                            if (e.upcomingBlockedDays.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _DaysNote(
                                  days: e.upcomingBlockedDays,
                                  label: 'Owner unavailable on',
                                  color: AppColors.amberText,
                                  bg: AppColors.amberBg),
                            ],
                            if (!e.bookable) ...[
                              const SizedBox(height: 18),
                              _UnavailableNote(maintenance: e.inMaintenance),
                            ],
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: AppShadow.floating,
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rwf(e.price),
                                style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDark)),
                            Text('per ${e.unit}',
                                style: const TextStyle(fontSize: 13.5, color: AppColors.muted)),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: PrimaryButton(
                            e.bookable ? 'Book Now' : 'Not available',
                            height: 54,
                            onPressed: e.bookable
                                ? () => context.push(signedIn ? '/farmer/book/${e.id}' : '/login')
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}

/// Owner name, verified badge and completed-job count.
class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.equipment});
  final Equipment equipment;

  @override
  Widget build(BuildContext context) {
    final name = equipment.ownerName.isEmpty ? 'NTIZA partner' : equipment.ownerName;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          InitialsAvatar(initialsOf(name), size: 54, bg: AppColors.primary, fg: Colors.white),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)),
                Text('Verified owner · ${equipment.jobs} jobs completed',
                    style: const TextStyle(fontSize: 13, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecBox extends StatelessWidget {
  const _SpecBox({required this.spec});
  final Spec spec;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 96),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.green50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(spec.key, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 4),
            Text(spec.value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

/// Explains why the Book button is disabled.
class _UnavailableNote extends StatelessWidget {
  const _UnavailableNote({required this.maintenance});
  final bool maintenance;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration:
            BoxDecoration(color: AppColors.amberBg, borderRadius: BorderRadius.circular(14)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: AppColors.amberText),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                  maintenance
                      ? 'This machine is in maintenance and cannot be booked. '
                          'Please check back later or browse other equipment.'
                      : 'This machine is fully booked for the next ${Equipment.horizonDays} days. '
                          'Please check back later or browse other equipment.',
                  style: const TextStyle(color: AppColors.amberText, fontSize: 14, height: 1.4)),
            ),
          ],
        ),
      );
}

class _DaysNote extends StatelessWidget {
  const _DaysNote({required this.days, required this.label, required this.color, required this.bg});
  final List<DateTime> days;
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.input)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event_busy, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text('$label ${days.map(dayMonth).join(', ')}. Other days are free.',
                style: TextStyle(fontSize: 14.5, height: 1.4, color: color)),
          ),
        ],
      ),
    );
  }
}
