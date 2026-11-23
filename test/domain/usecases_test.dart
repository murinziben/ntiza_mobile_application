import 'package:flutter_test/flutter_test.dart';
import 'package:ntiza/core/errors/app_exception.dart';
import 'package:ntiza/core/utils/formatters.dart';
import 'package:ntiza/domain/entities/entities.dart';
import 'package:ntiza/domain/usecases/agent_usecases.dart';
import 'package:ntiza/domain/usecases/auth_usecases.dart';
import 'package:ntiza/domain/usecases/booking_usecases.dart';
import 'package:ntiza/domain/usecases/catalog_usecases.dart';

import '../helpers/fakes.dart';

void main() {
  group('AuthUseCases', () {
    late FakeAuthRepository auth;
    late AuthUseCases useCases;
    setUp(() {
      auth = FakeAuthRepository();
      useCases = AuthUseCases(auth);
    });

    test('signIn rejects blank input before calling the backend', () async {
      expect(() => useCases.signIn('', 'x'), throwsA(isA<AppException>()));
      expect(() => useCases.signIn('a@b.rw', ''), throwsA(isA<AppException>()));
      expect(auth.calls, isEmpty);
    });

    test('signIn forwards a trimmed e-mail', () async {
      await useCases.signIn(' esperance@example.com ', 'secret123');
      expect(auth.calls, ['signIn:esperance@example.com']);
    });

    test('register creates a farmer profile, active at once, and verifies e-mail', () async {
      final profile = await useCases.register(
        role: Role.farmer,
        name: 'Uwase Esperance',
        email: 'Esperance@Example.com',
        phone: '+250 781 234 567',
        district: 'Huye',
        password: 'abc12345',
        confirmPassword: 'abc12345',
      );
      expect(profile.status, UserStatus.active);
      expect(profile.email, 'esperance@example.com');
      expect(profile.phone, '0781234567');
      expect(auth.saved.single.uid, 'u1');
      expect(auth.calls, ['register:Esperance@Example.com', 'verify']);
    });

    test('partner roles start pending', () async {
      final profile = await useCases.register(
        role: Role.owner,
        name: 'Agasaro Farm',
        email: 'farm@example.com',
        phone: '0788000111',
        district: 'Huye',
        password: 'abc12345',
        confirmPassword: 'abc12345',
      );
      expect(profile.status, UserStatus.pending);
      expect(AuthUseCases.statusFor(Role.admin), UserStatus.active);
    });

    test('register validates every field and creates nothing on failure', () async {
      expect(
        () => useCases.register(
          role: Role.farmer,
          name: 'Uwase',
          email: 'bad',
          phone: '0781234567',
          district: 'Huye',
          password: 'abc12345',
          confirmPassword: 'abc12345',
        ),
        throwsA(isA<AppException>()),
      );
      expect(
        () => useCases.register(
          role: Role.farmer,
          name: 'Uwase',
          email: 'a@b.rw',
          phone: '0781234567',
          district: 'Huye',
          password: 'abc12345',
          confirmPassword: 'different1',
        ),
        throwsA(isA<AppException>()),
      );
      expect(auth.calls, isEmpty);
      expect(auth.saved, isEmpty);
    });

    test('completeProfile stores the Google user profile', () async {
      const session =
          AuthSession(uid: 'g1', email: 'G@Mail.com', emailVerified: true, usesPassword: false);
      final profile = await useCases.completeProfile(
        session: session,
        role: Role.farmer,
        name: 'Grace Mutoni',
        phone: '0722000000',
        district: 'Kigali',
      );
      expect(profile.email, 'g@mail.com');
      expect(auth.saved.single.name, 'Grace Mutoni');
    });

    test('password reset and profile update validate input', () async {
      await useCases.sendPasswordReset('a@b.rw');
      expect(auth.calls.last, 'reset:a@b.rw');
      expect(() => useCases.sendPasswordReset('nope'), throwsA(isA<AppException>()));
      await useCases.updateProfile('u1', name: 'New Name', phone: '0781234567', district: 'Huye');
      expect(auth.calls.last, startsWith('update:u1:New Name:0781234567'));
      expect(
        () => useCases.updateProfile('u1', name: '', phone: '0781234567', district: 'Huye'),
        throwsA(isA<AppException>()),
      );
    });

    test('session flags: password accounts need verification, Google accounts do not', () {
      const pw = AuthSession(uid: 'a', email: 'a@b.rw', emailVerified: false, usesPassword: true);
      const google =
          AuthSession(uid: 'b', email: 'b@b.rw', emailVerified: false, usesPassword: false);
      expect(pw.needsVerification, isTrue);
      expect(google.needsVerification, isFalse);
    });
  });

  group('BookingUseCases', () {
    late FakeBookingRepository bookings;
    late FakeNotificationRepository notifications;
    late BookingUseCases useCases;
    setUp(() {
      bookings = FakeBookingRepository();
      notifications = FakeNotificationRepository();
      useCases = BookingUseCases(bookings, notifications);
    });

    test('scheduledLabel formats weekday, date and time', () {
      expect(BookingUseCases.scheduledLabel(DateTime(2026, 11, 14), '08:00'),
          'Sat, 14 Nov 2026 · 08:00');
    });

    test('bookEquipment prices the job, creates it and notifies the owner', () async {
      final ref = await useCases.bookEquipment(
        equipment: sampleTractor,
        date: DateTime(2026, 11, 14),
        startTime: '08:00',
        durationOption: '4 hours',
        location: ' Rwamagana ',
        farmer: sampleFarmer,
      );
      expect(ref, 'NTZ-2041');
      final b = bookings.created.single;
      expect(b.total, 102000); // 4 × 25,000 + 2% fee
      expect(b.farmerId, 'farmer1');
      expect(b.providerId, 'owner1');
      expect(b.location, 'Rwamagana');
      expect(b.dateLabel, '14 Nov');
      expect(notifications.added.single.$1, 'owner1');
    });

    test('bookEquipment rejects machines under maintenance and blank locations', () {
      final broken = sampleTractor.copyWith(inMaintenance: true);
      expect(
        () => useCases.bookEquipment(
            equipment: broken,
            date: DateTime(2026, 11, 14),
            startTime: '08:00',
            durationOption: '2 hours',
            location: 'Huye',
            farmer: sampleFarmer),
        throwsA(isA<AppException>()),
      );
      expect(
        () => useCases.bookEquipment(
            equipment: sampleTractor,
            date: DateTime(2026, 11, 14),
            startTime: '08:00',
            durationOption: '2 hours',
            location: '  ',
            farmer: sampleFarmer),
        throwsA(isA<AppException>()),
      );
      expect(
        () => useCases.bookEquipment(
            equipment: sampleTractor,
            date: DateTime(2026, 11, 14),
            startTime: '08:00',
            durationOption: '2 hours',
            location: 'Huye'),
        throwsA(isA<AppException>()),
      );
      expect(bookings.created, isEmpty);
    });

    test('bookEquipment stores the day key and refuses a day that is already taken', () async {
      await useCases.bookEquipment(
          equipment: sampleTractor,
          date: DateTime(2026, 11, 14),
          startTime: '08:00',
          durationOption: '2 hours',
          location: 'Huye',
          farmer: sampleFarmer);
      expect(bookings.created.single.dateKey, '2026-11-14');

      final taken = Equipment(
        id: sampleTractor.id,
        name: sampleTractor.name,
        type: sampleTractor.type,
        district: sampleTractor.district,
        price: sampleTractor.price,
        unit: sampleTractor.unit,
        ownerId: sampleTractor.ownerId,
        bookedDates: const ['2026-11-15'],
      );
      expect(
        () => useCases.bookEquipment(
            equipment: taken,
            date: DateTime(2026, 11, 15),
            startTime: '08:00',
            durationOption: '2 hours',
            location: 'Huye',
            farmer: sampleFarmer),
        throwsA(isA<AppException>()),
      );
      expect(bookings.created, hasLength(1));
      // The next day is still free.
      await useCases.bookEquipment(
          equipment: taken,
          date: DateTime(2026, 11, 16),
          startTime: '08:00',
          durationOption: '2 hours',
          location: 'Huye',
          farmer: sampleFarmer);
      expect(bookings.created, hasLength(2));

      // A day the owner blocked is refused too.
      final blocked = taken.copyWith(blockedDates: const ['2026-11-20']);
      expect(
        () => useCases.bookEquipment(
            equipment: blocked,
            date: DateTime(2026, 11, 20),
            startTime: '08:00',
            durationOption: '2 hours',
            location: 'Huye',
            farmer: sampleFarmer),
        throwsA(isA<AppException>()),
      );
    });

    test('an agent books for a client and the farmer id stays empty', () async {
      const agent =
          AppUser(uid: 'agent1', name: 'Agent A', role: Role.agent, status: UserStatus.active);
      const client = AgentClient(
          id: 'c1',
          agentId: 'agent1',
          name: 'Mukamana Aline',
          phone: '0781234567',
          district: 'Huye');
      await useCases.bookEquipment(
        equipment: sampleTractor,
        date: DateTime(2026, 11, 20),
        startTime: '10:00',
        durationOption: '2 hours',
        location: 'Huye',
        agent: agent,
        client: client,
      );
      final b = bookings.created.single;
      expect(b.farmerId, isEmpty);
      expect(b.agentId, 'agent1');
      expect(b.clientName, 'Mukamana Aline');
      expect(notifications.added.single.$3, contains('Mukamana Aline'));
    });

    test('pay records the provider and notifies both sides', () async {
      await useCases.pay(sampleBooking(), 'MTN MoMo');
      expect(bookings.paid, ['NTZ-2041:MTN MoMo']);
      expect(notifications.added.map((n) => n.$1), ['farmer1', 'owner1']);
    });

    test('updateStatus tells the farmer and the agent', () async {
      await useCases.updateStatus(sampleBooking(agentId: 'agent1'), BookingStatus.confirmed);
      expect(bookings.statusChanges, ['NTZ-2041:Confirmed']);
      expect(notifications.added.map((n) => n.$1).toSet(), {'farmer1', 'agent1'});
      expect(notifications.added.first.$2, 'Booking confirmed');
    });

    test('only finished bookings can be deleted', () async {
      expect(() => useCases.deleteBooking(sampleBooking()), throwsA(isA<AppException>()));
      await useCases.deleteBooking(sampleBooking(status: BookingStatus.completed));
      expect(bookings.deleted, ['NTZ-2041']);
    });
  });

  group('CatalogUseCases', () {
    late FakeCatalogRepository catalog;
    late CatalogUseCases useCases;
    setUp(() {
      catalog = FakeCatalogRepository();
      useCases = CatalogUseCases(catalog);
    });

    test('creates when id is empty and updates otherwise', () async {
      const draft = Equipment(
          id: '', name: 'Pump', type: 'Pump', district: 'Huye', price: 8000, unit: 'hour');
      await useCases.saveEquipment(draft, priceText: '8,000');
      expect(catalog.added.single.name, 'Pump');
      await useCases.saveEquipment(draft.copyWith(id: 'eq9', price: 9000), priceText: '9000');
      expect(catalog.updated.single.id, 'eq9');
    });

    test('validates name, price and district', () {
      const noName =
          Equipment(id: '', name: ' ', type: 'Pump', district: 'Huye', price: 8000, unit: 'hour');
      expect(() => useCases.saveEquipment(noName, priceText: '8000'), throwsA(isA<AppException>()));
      expect(() => useCases.saveEquipment(noName.copyWith(name: 'Pump'), priceText: '0'),
          throwsA(isA<AppException>()));
      expect(
          () => useCases.saveEquipment(noName.copyWith(name: 'Pump', district: ''), priceText: '5'),
          throwsA(isA<AppException>()));
    });

    test('cannot delete equipment with an open booking', () async {
      final open = sampleBooking(status: BookingStatus.confirmed);
      expect(() => useCases.deleteEquipment(sampleTractor, [open]), throwsA(isA<AppException>()));
      await useCases
          .deleteEquipment(sampleTractor, [sampleBooking(status: BookingStatus.completed)]);
      expect(catalog.deleted, ['eq1']);
    });

    test('setBlockedDays stores sorted keys and refuses booked days', () async {
      await useCases.setBlockedDays(sampleTractor, [DateTime(2026, 12, 3), DateTime(2026, 12, 1)]);
      expect(catalog.blocked['eq1'], ['2026-12-01', '2026-12-03']);
      final booked = sampleTractor.copyWith(blockedDates: const []);
      const withBooking = Equipment(
          id: 'eq1',
          name: 'T',
          type: 'Tractor',
          district: 'Huye',
          price: 1,
          unit: 'day',
          bookedDates: ['2026-12-05']);
      expect(booked.blockedDates, isEmpty);
      expect(() => useCases.setBlockedDays(withBooking, [DateTime(2026, 12, 5)]),
          throwsA(isA<AppException>()));
    });

    test('setMaintenance', () async {
      await useCases.setMaintenance(sampleTractor, true);
      expect(catalog.updated.single.inMaintenance, isTrue);
    });
  });

  group('AgentUseCases', () {
    test('adds, updates and deletes clients with validation', () async {
      final repo = FakeAgentRepository();
      final useCases = AgentUseCases(repo);
      const client = AgentClient(
          id: '',
          agentId: 'agent1',
          name: ' Mukamana Aline ',
          phone: '+250781234567',
          district: 'Huye');
      await useCases.saveClient(client);
      expect(repo.added.single.name, 'Mukamana Aline');
      expect(repo.added.single.phone, '0781234567');
      await useCases.saveClient(const AgentClient(
          id: 'c1', agentId: 'agent1', name: 'Aline M', phone: '0781234567', district: 'Huye'));
      expect(repo.updated.single.id, 'c1');
      await useCases.deleteClient('c1');
      expect(repo.deleted, ['c1']);
      expect(
          () => useCases.saveClient(client.copyWith(phone: '123')), throwsA(isA<AppException>()));
    });
  });

  group('entities', () {
    test('role helpers', () {
      expect(Role.owner.home, '/owner');
      expect(Role.owner.needsApproval, isTrue);
      expect(Role.farmer.needsApproval, isFalse);
      expect(Role.admin.label, 'Admin');
      expect(roleFromName('expert'), Role.farmer);
      expect(roleFromName('unknown'), Role.farmer);
    });

    test('AppUser.firstName skips honorifics', () {
      const u = AppUser(uid: '1', name: 'Dr. Uwera Solange', role: Role.agent, status: 'active');
      expect(u.firstName, 'Uwera');
      expect(u.copyWith(status: UserStatus.suspended).isActive, isFalse);
    });

    test('Equipment derived fields', () {
      expect(sampleTractor.image, 'tractor.jpg');
      expect(imageForType('Pump'), 'pump.jpg');
      expect(imageForType('Sheller'), 'harvester.jpg');
      expect(sampleTractor.place, 'Huye · Mbazi');
      expect(sampleTractor.unitShort, 'hr');
      expect(sampleTractor.copyWith(unit: 'hectare').unitShort, 'ha');
      expect(sampleTractor.copyWith(unit: 'day').unitShort, 'day');
      expect(sampleTractor.bookable, isTrue);
      expect(sampleTractor.availability, Availability.freeToday);
      expect(sampleTractor.availabilityLabel, 'Free today');
      expect(sampleTractor.copyWith(inMaintenance: true).availabilityLabel, 'In maintenance');
      final n = DateTime.now();
      String key(int i) => dateKey(DateTime(n.year, n.month, n.day + i));
      final busy = Equipment(
          id: 'x',
          name: 'x',
          type: 'Tractor',
          district: 'Huye',
          price: 1,
          unit: 'day',
          bookedDates: [key(0), key(1)],
          blockedDates: [key(2)]);
      expect(busy.availability, Availability.freeLater);
      expect(busy.availabilityLabel, startsWith('Free from'));
      final full = busy.copyWith(blockedDates: [for (var i = 0; i < 60; i++) key(i)]);
      expect(full.availabilityLabel, 'Fully booked');
      expect(full.bookable, isFalse);
    });

    test('Booking helpers', () {
      final b = sampleBooking(status: BookingStatus.cancelled);
      expect(b.earlier, isTrue);
      expect(b.isPaid, isFalse);
      expect(b.customerName, 'Uwase Esperance');
    });
  });
}
