import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sample_data.dart';
import '../../domain/entities/agent_client.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/equipment.dart';
import '../controllers/settings_controller.dart';
import 'dependencies.dart';

/// Live data exposed to the UI as Riverpod providers. Widgets `watch` these
/// and rebuild automatically when Firestore changes.

// ---- session ---------------------------------------------------------------

final sessionProvider = StreamProvider<AuthSession?>(
  (ref) => ref.watch(authRepositoryProvider).watchSession(),
);

final currentUidProvider = Provider<String?>((ref) => ref.watch(sessionProvider).valueOrNull?.uid);

final signedInProvider = Provider<bool>((ref) => ref.watch(currentUidProvider) != null);

/// The signed-in user's profile document.
final profileProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchProfile(uid);
});

// ---- catalogue -------------------------------------------------------------

final equipmentProvider = StreamProvider<List<Equipment>>(
  (ref) => ref.watch(catalogRepositoryProvider).watchEquipment(),
);

/// Equipment owned by the signed-in owner.
final myEquipmentProvider = Provider<List<Equipment>>((ref) {
  final uid = ref.watch(currentUidProvider);
  final all = ref.watch(equipmentProvider).valueOrNull ?? const <Equipment>[];
  return [
    for (final e in all)
      if (e.ownerId == uid) e
  ];
});

final equipmentByIdProvider = Provider.family<Equipment?, String>((ref, id) {
  final all = ref.watch(equipmentProvider).valueOrNull ?? const <Equipment>[];
  for (final e in all) {
    if (e.id == id) return e;
  }
  for (final e in sampleEquipment) {
    if (e.id == id) return e;
  }
  return null;
});

// ---- bookings --------------------------------------------------------------

/// Bookings made by the signed-in farmer.
final bookingsProvider = StreamProvider<List<Booking>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const <Booking>[]);
  return ref.watch(bookingRepositoryProvider).watchForFarmer(uid);
});

/// Bookings assigned to the signed-in owner.
final providerBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const <Booking>[]);
  return ref.watch(bookingRepositoryProvider).watchForProvider(uid);
});

/// Bookings the signed-in agent made for clients.
final agentBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const <Booking>[]);
  return ref.watch(bookingRepositoryProvider).watchForAgent(uid);
});

/// Admin: every booking.
final allBookingsProvider = StreamProvider<List<Booking>>(
  (ref) => ref.watch(bookingRepositoryProvider).watchAll(),
);

/// Finds a booking by reference in whichever list the user can read.
final bookingByRefProvider = Provider.family<Booking?, String>((ref, bookingRef) {
  for (final source in [
    bookingsProvider,
    providerBookingsProvider,
    agentBookingsProvider,
    allBookingsProvider,
  ]) {
    for (final b in ref.watch(source).valueOrNull ?? const <Booking>[]) {
      if (b.ref == bookingRef) return b;
    }
  }
  return null;
});

// ---- notifications, admin, agent -------------------------------------------

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const <AppNotification>[]);
  return ref.watch(notificationRepositoryProvider).watch(uid);
});

/// Unread count for the bell badge; zero when notifications are switched off.
final unreadCountProvider = Provider<int>((ref) {
  if (!ref.watch(settingsControllerProvider).notificationsEnabled) return 0;
  final list = ref.watch(notificationsProvider).valueOrNull ?? const <AppNotification>[];
  return list.where((n) => n.unread).length;
});

/// Admin: all user profiles.
final allUsersProvider = StreamProvider<List<AppUser>>(
  (ref) => ref.watch(adminRepositoryProvider).watchUsers(),
);

/// The signed-in agent's clients.
final agentClientsProvider = StreamProvider<List<AgentClient>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const <AgentClient>[]);
  return ref.watch(agentRepositoryProvider).watchClients(uid);
});
