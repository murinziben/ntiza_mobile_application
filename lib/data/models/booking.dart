/// App-side statuses. The web platform calls "approved" `confirmed`.
enum BookingStatus { pending, approved, completed, cancelled }

extension BookingStatusLabel on BookingStatus {
  String get label => switch (this) {
        BookingStatus.pending => 'Pending review',
        BookingStatus.approved => 'Approved',
        BookingStatus.completed => 'Completed',
        BookingStatus.cancelled => 'Cancelled',
      };
}

class Booking {
  const Booking({
    required this.id,
    required this.reference,
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentImageUrl,
    required this.location,
    required this.date,
    required this.farmSizeHectares,
    required this.estimatedTotal,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String reference;
  final String equipmentId;
  final String equipmentName;
  final String? equipmentImageUrl;
  final String location;
  final DateTime date;
  final double farmSizeHectares;
  final int estimatedTotal;
  final BookingStatus status;
  final DateTime createdAt;
}
