import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/pricing.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';
import '../common/role_widgets.dart';
import '../public/public_shell.dart';

const adminNav = [
  NavItem('Overview', Icons.grid_view_outlined),
  NavItem('Users', Icons.groups_2_outlined),
  NavItem('Bookings', Icons.calendar_today_outlined),
  NavItem('Profile', Icons.person_outline),
];

// ---- shared helpers ----------------------------------------------------------

/// Asks the user to confirm an action before it runs.
Future<bool> _confirm(BuildContext context, String title, String message, String action,
    {bool destructive = true}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: destructive ? AppColors.danger : AppColors.primaryDark,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Compact text button with an icon, at least 48dp tall.
Widget _miniAction(String label, IconData icon, VoidCallback? onTap,
        {Color color = AppColors.primaryDark}) =>
    TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: color),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );

/// Centered grey message for empty lists.
// ---- overview ------------------------------------------------------------------

/// Platform summary: users, applications, bookings, equipment and revenue.
class AdminOverview extends ConsumerWidget {
  const AdminOverview({super.key});

  /// Opens the Users tab already filtered to accounts awaiting approval.
  void _reviewApplications(BuildContext context, WidgetRef ref) {
    ref.read(_userRoleFilterProvider.notifier).state = 'Pending';
    context.go('/admin/users');
  }

  Future<void> _seed(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(context, 'Load demo data?',
        'Adds sample equipment. Existing demo items are overwritten.', 'Load',
        destructive: false);
    if (!ok || !context.mounted) return;
    final result = await ref.read(adminControllerProvider.notifier).seedDemoData();
    if (!context.mounted) return;
    showToast(context, result.ok ? 'Demo data loaded.' : result.error!);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(allUsersProvider).valueOrNull ?? const <AppUser>[];
    final bookings = ref.watch(allBookingsProvider).valueOrNull ?? const <Booking>[];
    final equipment = ref.watch(equipmentProvider).valueOrNull ?? const <Equipment>[];
    final pendingApps = users.where((u) => u.status == UserStatus.pending).toList();

    // Platform revenue = the commission kept on every completed booking.
    int commission(Booking b) => (b.total * BookingPricing.platformCommission).round();
    final series = BookingStats.monthly(bookings, commission, now: DateTime.now());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            RoleHeader(
                initials: 'AD',
                icon: Icons.shield_outlined,
                title: 'Admin Console',
                subtitle: 'NTIZA platform · Today, ${dayMonth(DateTime.now())}'),
            const SizedBox(height: 16),
            StatGrid([
              StatSpec('${users.length}', 'Total Users', Icons.groups_2_outlined,
                  AppColors.green100, AppColors.primaryDark),
              StatSpec('${pendingApps.length}', 'Pending Applications', Icons.description_outlined,
                  AppColors.amberBg, AppColors.amberText),
              StatSpec('${bookings.length}', 'Total Bookings', Icons.calendar_today_outlined,
                  AppColors.blueBg, AppColors.blue),
              StatSpec('${equipment.length}', 'Equipment Listed', Icons.agriculture_outlined,
                  AppColors.purpleBg, AppColors.purple),
            ]),
            const SizedBox(height: 16),
            BarCard(
              caption: 'Commission revenue · 6 months',
              total: rwf(series.fold<int>(0, (s, m) => s + m.amount)),
              labels: [for (final m in series) m.label],
              values: BookingStats.chartValues(series),
            ),
            const SizedBox(height: 24),
            sectionTitle('Pending Applications',
                action: 'Review', onAction: () => _reviewApplications(context, ref)),
            const SizedBox(height: 12),
            if (pendingApps.isEmpty)
              const EmptyState('No pending applications',
                  icon: Icons.how_to_reg_outlined, padding: 16),
            for (final a in pendingApps.take(2)) ...[
              PersonCard(
                initials: initialsOf(a.name),
                name: a.name,
                accent: '${a.role.label} · ${a.district}',
                meta: a.createdAt == null ? 'Applied recently' : 'Applied ${timeAgo(a.createdAt!)}',
                action: 'Review',
                onAction: () => _reviewApplications(context, ref),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            sectionTitle('Recent Bookings'),
            const SizedBox(height: 12),
            if (bookings.isEmpty)
              const EmptyState('No bookings yet', icon: Icons.event_note_outlined, padding: 16),
            for (final b in bookings.take(3)) ...[
              _BookingTile(booking: b),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            OutlineButtonX('Load demo data',
                height: 52,
                onPressed:
                    ref.watch(adminControllerProvider).busy ? null : () => _seed(context, ref)),
          ],
        ),
      ),
    );
  }
}

/// One booking in the admin's recent list.
class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            AssetPhoto(booking.image, width: 60, height: 60, radius: 12),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${booking.title} · ${booking.customerName}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${booking.ref} · ${rwf(booking.total)}',
                      style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusChip(booking.status),
          ],
        ),
      );
}

// ---- users ---------------------------------------------------------------------

final _userQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Not auto-disposed so the Overview can preset it to 'Pending' before switching tabs.
final _userRoleFilterProvider = StateProvider<String>((ref) => 'All');

/// All accounts: approve or reject applicants, suspend / reactivate / delete others.
class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  bool _matches(AppUser u, String filter) => switch (filter) {
        'Pending' => u.status == UserStatus.pending,
        'Farmers' => u.role == Role.farmer,
        'Owners' => u.role == Role.owner,
        'Agents' => u.role == Role.agent,
        _ => true,
      };

  Future<void> _decide(BuildContext context, WidgetRef ref, AppUser u,
      {required bool approve}) async {
    final result =
        await ref.read(adminControllerProvider.notifier).decideApplication(u, approve: approve);
    if (!context.mounted) return;
    showToast(context,
        result.ok ? (approve ? '${u.name} approved.' : '${u.name} rejected.') : result.error!);
  }

  Future<void> _toggleSuspend(BuildContext context, WidgetRef ref, AppUser u) async {
    final suspended = u.status == UserStatus.suspended;
    final result = await ref
        .read(adminControllerProvider.notifier)
        .setUserStatus(u, suspended ? UserStatus.active : UserStatus.suspended);
    if (!context.mounted) return;
    showToast(
        context,
        result.ok
            ? (suspended ? '${u.name} reactivated.' : '${u.name} suspended.')
            : result.error!);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, AppUser u) async {
    final ok = await _confirm(context, 'Delete user?',
        '${u.name}\'s profile will be removed. This cannot be undone.', 'Delete');
    if (!ok || !context.mounted) return;
    final result = await ref.read(adminControllerProvider.notifier).deleteUser(u);
    if (!context.mounted) return;
    showToast(context, result.ok ? 'User deleted.' : result.error!);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allUsersProvider).valueOrNull ?? const <AppUser>[];
    final me = ref.watch(currentUidProvider);
    final filter = ref.watch(_userRoleFilterProvider);
    final q = ref.watch(_userQueryProvider).trim().toLowerCase();
    final pendingCount = all.where((u) => u.status == UserStatus.pending).length;
    final items = all
        .where((u) => _matches(u, filter) && (q.isEmpty || u.name.toLowerCase().contains(q)))
        .toList();

    return Scaffold(
      appBar: const TopBar('Users', back: false),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchField(
                hint: 'Search users',
                onChanged: (v) => ref.read(_userQueryProvider.notifier).state = v),
          ),
          const SizedBox(height: 14),
          ChipRow(
            labels: ['All', 'Pending ($pendingCount)', 'Farmers', 'Owners', 'Agents'],
            selected: filter == 'Pending' ? 'Pending ($pendingCount)' : filter,
            onSelected: (v) => ref.read(_userRoleFilterProvider.notifier).state =
                v.startsWith('Pending') ? 'Pending' : v,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                if (items.isEmpty)
                  EmptyState(filter == 'Pending' ? 'No pending applications' : 'No users found',
                      message: filter == 'Pending'
                          ? 'New owner and agent sign-ups waiting for approval appear here.'
                          : 'Try a different search or filter.',
                      icon: Icons.person_search_outlined),
                for (final u in items) ...[
                  // Admins (including yourself) cannot be managed from here.
                  PersonCard(
                    initials: initialsOf(u.name),
                    name: u.name,
                    accent: u.role.label,
                    meta: u.district.isEmpty ? u.email : '${u.district} · ${u.email}',
                    star: false,
                    tags: [
                      StatusChip(u.status),
                      if (u.status == UserStatus.pending && u.role != Role.admin) ...[
                        _miniAction('Approve', Icons.check_circle_outline,
                            () => _decide(context, ref, u, approve: true)),
                        _miniAction(
                            'Reject', Icons.close, () => _decide(context, ref, u, approve: false),
                            color: AppColors.danger),
                      ] else if (u.role != Role.admin && u.uid != me) ...[
                        _miniAction(
                          u.status == UserStatus.suspended ? 'Reactivate' : 'Suspend',
                          u.status == UserStatus.suspended
                              ? Icons.check_circle_outline
                              : Icons.block,
                          () => _toggleSuspend(context, ref, u),
                          color: u.status == UserStatus.suspended
                              ? AppColors.primaryDark
                              : AppColors.danger,
                        ),
                        _miniAction('Delete', Icons.delete_outline, () => _delete(context, ref, u),
                            color: AppColors.danger),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- bookings ------------------------------------------------------------------

final _bookingFilterProvider = StateProvider.autoDispose<String>((ref) => 'All');

/// Every booking on the platform, filtered by status.
class AdminBookingsScreen extends ConsumerWidget {
  const AdminBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_bookingFilterProvider);
    final all = ref.watch(allBookingsProvider).valueOrNull ?? const <Booking>[];
    final items = [
      for (final b in all)
        if (filter == 'All' || b.status == filter) b
    ];
    return Scaffold(
      appBar: const TopBar('Bookings', back: false),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        children: [
          ChipRow(
            labels: const [
              'All',
              BookingStatus.pending,
              BookingStatus.confirmed,
              BookingStatus.completed,
              BookingStatus.cancelled
            ],
            selected: filter,
            onSelected: (v) => ref.read(_bookingFilterProvider.notifier).state = v,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                if (items.isEmpty)
                  const EmptyState('No bookings found',
                      message: 'Bookings made on the platform appear here.',
                      icon: Icons.event_note_outlined),
                for (final b in items) ...[
                  _BookingTile(booking: b),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
