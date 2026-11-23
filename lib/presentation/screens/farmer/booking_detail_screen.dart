import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';

enum _S { done, current, todo }

/// One booking: progress timeline, details, payment and follow-up actions.
class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({super.key, required this.bookingRef});
  final String bookingRef;

  /// Timeline steps derived purely from the booking's status and payment.
  List<(_S, String, String)> _steps(Booking b) {
    final paid = b.isPaid;
    final confirmed = b.status == BookingStatus.confirmed || b.status == BookingStatus.completed;
    final completed = b.status == BookingStatus.completed;
    final cancelled = b.status == BookingStatus.cancelled;
    return [
      (_S.done, 'Request sent', b.created),
      if (cancelled)
        (_S.done, 'Booking cancelled', 'No further action needed')
      else ...[
        (
          paid ? _S.done : _S.current,
          'Payment received',
          paid ? 'Paid via ${b.paidVia}' : 'Awaiting payment'
        ),
        (
          confirmed ? _S.done : (paid ? _S.current : _S.todo),
          'Owner confirmed',
          confirmed ? 'Confirmed by ${b.providerName}' : 'Pending'
        ),
        (
          completed ? _S.done : (confirmed ? _S.current : _S.todo),
          'Equipment on the way',
          confirmed ? b.dateLabel : 'Pending'
        ),
        (completed ? _S.done : _S.todo, 'Service completed', completed ? b.dateLabel : 'Pending'),
      ],
    ];
  }

  Future<bool> _confirm(BuildContext context,
      {required String title, required String body, required String action}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Keep it')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, Booking b) async {
    final ok = await _confirm(context,
        title: 'Cancel this booking?',
        body: 'The owner will be told you cancelled.',
        action: 'Cancel booking');
    if (!ok || !context.mounted) return;
    final r =
        await ref.read(bookingControllerProvider.notifier).updateStatus(b, BookingStatus.cancelled);
    if (!context.mounted) return;
    showToast(context, r.ok ? 'Booking cancelled.' : r.error!);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Booking b) async {
    final ok = await _confirm(context,
        title: 'Delete from history?',
        body: 'Booking ${b.ref} will be removed permanently.',
        action: 'Delete');
    if (!ok || !context.mounted) return;
    final r = await ref.read(bookingControllerProvider.notifier).delete(b);
    if (!context.mounted) return;
    if (r.ok) {
      showToast(context, 'Booking deleted.');
      context.pop();
    } else {
      showToast(context, r.error!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(bookingByRefProvider(bookingRef));
    if (b == null) {
      return const Scaffold(
          appBar: TopBar('Booking'), body: Center(child: CircularProgressIndicator()));
    }
    final busy = ref.watch(bookingControllerProvider).busy;
    final cancelled = b.status == BookingStatus.cancelled;
    final steps = _steps(b);

    return Scaffold(
      appBar: TopBar('Booking #${b.ref}'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AssetPhoto(b.image, height: 190),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(b.title,
                                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 8),
                          StatusChip(b.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Owner: ${b.providerName}',
                          style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('Booking progress',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Column(
              children: [
                for (var i = 0; i < steps.length; i++)
                  _TimelineRow(
                    state: steps[i].$1,
                    title: steps[i].$2,
                    sub: steps[i].$3,
                    last: i == steps.length - 1,
                    nextDone: i + 1 < steps.length && steps[i + 1].$1 == _S.done,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _kv('Date', b.scheduled.isEmpty ? b.dateLabel : b.scheduled),
                _kv('Duration', b.detail),
                _kv('Location', b.location),
                _kv('Total', rwf(b.total)),
                _kv('Payment', b.isPaid ? 'Paid via ${b.paidVia}' : 'Not paid yet'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!b.isPaid && !cancelled) ...[
            PrimaryButton('Pay ${rwf(b.total)}',
                height: 54, onPressed: () => context.push('/farmer/pay/${b.ref}')),
            const SizedBox(height: 12),
          ],
          if (b.status == BookingStatus.pending) ...[
            const SizedBox(height: 12),
            OutlineButtonX(busy ? 'Please wait…' : 'Cancel booking',
                height: 52,
                color: AppColors.danger,
                onPressed: busy ? null : () => _cancel(context, ref, b)),
          ],
          if (b.earlier) ...[
            const SizedBox(height: 12),
            OutlineButtonX(busy ? 'Please wait…' : 'Delete from history',
                height: 52,
                color: AppColors.danger,
                onPressed: busy ? null : () => _delete(context, ref, b)),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k, style: const TextStyle(fontSize: 15, color: AppColors.muted)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(v,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow(
      {required this.state,
      required this.title,
      required this.sub,
      required this.last,
      required this.nextDone});
  final _S state;
  final String title, sub;
  final bool last, nextDone;

  @override
  Widget build(BuildContext context) {
    final dim = state == _S.todo;
    Widget dot;
    switch (state) {
      case _S.done:
        dot = Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 18, color: Colors.white),
        );
      case _S.current:
        dot = Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              color: AppColors.amberBg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.amber, width: 1.6)),
        );
      case _S.todo:
        dot = Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(color: AppColors.neutral, shape: BoxShape.circle),
        );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                dot,
                if (!last)
                  Expanded(
                    child: Container(
                      width: 3,
                      color: state == _S.done && nextDone ? AppColors.primary : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 10 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
                          color: dim ? AppColors.faint : AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: TextStyle(
                          fontSize: 13.5, color: dim ? AppColors.faint : AppColors.muted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
