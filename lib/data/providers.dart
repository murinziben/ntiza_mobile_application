import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/app_user.dart';
import 'models/booking.dart';
import 'models/equipment.dart';
import 'sample_data.dart';

// Every provider is async-shaped on purpose: screens already handle
// loading/error states, so swapping in Firestore later changes only this file.

final currentUserProvider = Provider<AppUser>((ref) => sampleUser);

final equipmentListProvider = FutureProvider<List<Equipment>>((ref) async {
  return sampleEquipment;
});

final bookingsProvider = FutureProvider<List<Booking>>((ref) async {
  return sampleBookings;
});

/// Most recently created booking, for the Home status strip.
final recentBookingProvider = Provider<AsyncValue<Booking?>>((ref) {
  return ref.watch(bookingsProvider).whenData((list) {
    if (list.isEmpty) return null;
    final sorted = [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.first;
  });
});

final unreadNotificationCountProvider = Provider<int>((ref) => 1);
