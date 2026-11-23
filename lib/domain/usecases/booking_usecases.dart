import '../../core/errors/app_exception.dart';
import '../../core/utils/formatters.dart';
import '../entities/agent_client.dart';
import '../entities/app_user.dart';
import '../entities/booking.dart';
import '../entities/equipment.dart';
import '../repositories/booking_repository.dart';
import '../repositories/notification_repository.dart';
import '../validators.dart';
import 'pricing.dart';

/// Booking and payment rules. Every state change also tells the
/// other party through a notification.
class BookingUseCases {
  BookingUseCases(this._bookings, this._notifications);

  final BookingRepository _bookings;
  final NotificationRepository _notifications;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// `Sat, 14 Nov 2026 · 08:00` — the long label stored on a booking.
  static String scheduledLabel(DateTime date, String time) =>
      '${_weekdays[date.weekday - 1]}, ${dayMonth(date)} ${date.year} · $time';

  /// A farmer (or an agent for a client) hires a machine.
  Future<String> bookEquipment({
    required Equipment equipment,
    required DateTime date,
    required String startTime,
    required String durationOption,
    required String location,
    AppUser? farmer,
    AppUser? agent,
    AgentClient? client,
  }) async {
    if (equipment.inMaintenance) {
      throw const AppException('This machine is under maintenance right now.');
    }
    if (equipment.isBlockedOn(date)) {
      throw const AppException('The owner is not available on that date. Pick another day.');
    }
    if (equipment.isBookedOn(date)) {
      throw const AppException('This machine is already booked on that date. Pick another day.');
    }
    final error = Validators.required(location, 'Farm location');
    if (error != null) throw AppException(error);
    if (farmer == null && (agent == null || client == null)) {
      throw const AppException('Please log in to book.');
    }

    final quote = BookingPricing.quote(
      price: equipment.price,
      quantity: BookingPricing.quantityOf(durationOption),
    );
    final byAgent = agent != null && client != null;
    final ref = await _bookings.create(NewBooking(
      kind: BookingKind.equipment,
      title: equipment.name,
      image: equipment.image,
      itemId: equipment.id,
      dateLabel: dayMonth(date),
      dateKey: dateKey(date),
      scheduled: scheduledLabel(date, startTime),
      detail: durationOption,
      place: equipment.district,
      location: location.trim(),
      total: quote.total,
      farmerId: byAgent ? '' : farmer!.uid,
      farmerName: byAgent ? '' : farmer!.name,
      providerId: equipment.ownerId,
      providerName: equipment.ownerName,
      agentId: byAgent ? agent.uid : '',
      clientName: byAgent ? client.name : '',
    ));
    if (equipment.ownerId.isNotEmpty) {
      final who = byAgent ? client.name : farmer!.name;
      await _notifications.add(equipment.ownerId, 'New booking request',
          '$who requested ${equipment.name} for ${dayMonth(date)}.', 'booking');
    }
    return ref;
  }

  /// Records a Mobile Money payment (simulated until a payments backend exists).
  Future<void> pay(Booking booking, String via) async {
    await _bookings.markPaid(booking.ref, via);
    if (booking.farmerId.isNotEmpty) {
      await _notifications.add(booking.farmerId, 'Payment received',
          '${rwf(booking.total)} received via $via. Ref ${booking.ref}.', 'payment');
    }
    if (booking.providerId.isNotEmpty) {
      await _notifications.add(
          booking.providerId, 'Booking paid', '${booking.ref} was paid via $via.', 'payment');
    }
  }

  /// Accept, decline, complete or cancel a booking and notify the customer.
  Future<void> updateStatus(Booking booking, String status) async {
    await _bookings.setStatus(booking, status);
    final text = switch (status) {
      BookingStatus.confirmed =>
        '${booking.providerName} confirmed your booking for ${booking.dateLabel}.',
      BookingStatus.cancelled =>
        '${booking.providerName} could not take your booking for ${booking.dateLabel}.',
      BookingStatus.completed => 'Your booking ${booking.ref} is complete.',
      _ => 'Booking ${booking.ref} is now $status.',
    };
    for (final uid in {booking.farmerId, booking.agentId}) {
      if (uid.isNotEmpty) {
        await _notifications.add(uid, 'Booking ${status.toLowerCase()}', text, 'booking');
      }
    }
  }

  Future<void> deleteBooking(Booking booking) async {
    if (!booking.earlier) {
      throw const AppException('Only completed or cancelled bookings can be deleted.');
    }
    await _bookings.delete(booking.ref);
  }
}
