import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/pricing.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';
import '../common/role_widgets.dart';

/// Helpers shared by the owner screens.

/// Changes a booking's status through the controller and tells the user.
Future<void> changeBookingStatus(
  BuildContext context,
  WidgetRef ref,
  Booking booking,
  String status,
  String successMessage,
) async {
  final result = await ref.read(bookingControllerProvider.notifier).updateStatus(booking, status);
  if (!context.mounted) return;
  showToast(context, result.ok ? successMessage : result.error!);
}

/// Net earnings and the six-month chart series for a list of bookings.
/// All arithmetic lives in the domain layer ([BookingStats], [BookingPricing]).
class EarningsView {
  const EarningsView({required this.net, required this.series});

  factory EarningsView.from(List<Booking> bookings, {DateTime? now}) {
    int net(Booking b) => BookingPricing.providerNet(b.total);
    return EarningsView(
      net: BookingStats.completedTotal(bookings, net, counts: (b) => b.isEarned),
      series: BookingStats.monthly(bookings, net,
          now: now ?? DateTime.now(), counts: (b) => b.isEarned),
    );
  }

  final int net;
  final List<MonthTotal> series;

  List<String> get labels => [for (final m in series) m.label];
  List<double> get values => BookingStats.chartValues(series);
  int get sixMonthTotal => series.fold(0, (sum, m) => sum + m.amount);
}

/// Transaction rows (newest first) for completed bookings.
List<RowSpec> payoutRows(List<Booking> bookings, IconData icon, {int limit = 10}) => [
      for (final b in bookings.where((b) => b.isEarned).take(limit))
        RowSpec(
          icon,
          b.customerName.isEmpty ? b.title : '${b.title} · ${b.customerName}',
          '${b.dateLabel} · ${b.paidVia ?? 'Not paid yet'}',
          '+${rwf(BookingPricing.providerNet(b.total))}',
        ),
    ];
