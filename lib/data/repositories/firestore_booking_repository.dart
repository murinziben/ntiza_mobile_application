import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../mappers/firestore_mappers.dart';
import 'firebase_errors.dart';

/// Bookings stored in Cloud Firestore.
///
/// Each query filters on one participant and sorts by `createdAt`, which needs
/// the composite indexes declared in `firestore.indexes.json`.
class FirestoreBookingRepository implements BookingRepository {
  FirestoreBookingRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _bookings => _db.collection('bookings');

  Stream<List<Booking>> _watch(Query<Map<String, dynamic>> q) => q.snapshots().map(
        (s) => [for (final d in s.docs) bookingFromMap(d.id, d.data())],
      );

  @override
  Stream<List<Booking>> watchForFarmer(String uid) =>
      _watch(_bookings.where('farmerId', isEqualTo: uid).orderBy('createdAt', descending: true));

  @override
  Stream<List<Booking>> watchForProvider(String uid) =>
      _watch(_bookings.where('providerId', isEqualTo: uid).orderBy('createdAt', descending: true));

  @override
  Stream<List<Booking>> watchForAgent(String uid) =>
      _watch(_bookings.where('agentId', isEqualTo: uid).orderBy('createdAt', descending: true));

  @override
  Stream<List<Booking>> watchAll() => _watch(_bookings.orderBy('createdAt', descending: true));

  @override
  Future<String> create(NewBooking booking) => guardData(() {
        final counter = _db.collection('meta').doc('counters');
        final reserve = booking.kind == BookingKind.equipment &&
            booking.itemId.isNotEmpty &&
            booking.dateKey.isNotEmpty;
        final machine = reserve ? _db.collection('equipment').doc(booking.itemId) : null;
        return _db.runTransaction<String>((tx) async {
          // All reads first: the day must still be free when we commit.
          final snap = await tx.get(counter);
          if (machine != null) {
            final data = (await tx.get(machine)).data();
            final blocked = data?['blockedDates'];
            if (blocked is List && blocked.contains(booking.dateKey)) {
              throw const AppException(
                  'The owner is not available on that date. Pick another day.');
            }
            final taken = data?['bookedDates'];
            if (taken is List && taken.contains(booking.dateKey)) {
              throw const AppException(
                  'This machine is already booked on that date. Pick another day.');
            }
            tx.update(machine, {'bookedDates': FieldValue.arrayUnion([booking.dateKey])});
          }
          final current = snap.data()?['booking'];
          final n = (current is num ? current.toInt() : 2040) + 1;
          tx.set(counter, {'booking': n}, SetOptions(merge: true));
          final ref = 'NTZ-$n';
          tx.set(_bookings.doc(ref), newBookingToMap(booking));
          return ref;
        });
      });

  @override
  Future<void> markPaid(String ref, String via) =>
      guardData(() => _bookings.doc(ref).update({'paidVia': via}));

  @override
  Future<void> setStatus(Booking booking, String status) => guardData(() async {
        await _bookings.doc(booking.ref).update({'status': status});
        if (status == BookingStatus.cancelled) await _freeDay(booking);
        if (status == BookingStatus.completed &&
            booking.kind == BookingKind.equipment &&
            booking.itemId.isNotEmpty) {
          await _db
              .collection('equipment')
              .doc(booking.itemId)
              .update({'jobs': FieldValue.increment(1)});
        }
      });

  @override
  Future<void> delete(String ref) => guardData(() async {
        final snap = await _bookings.doc(ref).get();
        if (snap.exists) {
          final booking = bookingFromMap(snap.id, snap.data()!);
          if (booking.status == BookingStatus.pending ||
              booking.status == BookingStatus.confirmed) {
            await _freeDay(booking);
          }
        }
        await _bookings.doc(ref).delete();
      });

  /// Makes the machine's day bookable again.
  Future<void> _freeDay(Booking booking) async {
    if (booking.kind != BookingKind.equipment ||
        booking.itemId.isEmpty ||
        booking.dateKey.isEmpty) {
      return;
    }
    await _db.collection('equipment').doc(booking.itemId).update({
      'bookedDates': FieldValue.arrayRemove([booking.dateKey]),
    });
  }
}
