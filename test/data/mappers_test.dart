import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ntiza/data/mappers/firestore_mappers.dart';
import 'package:ntiza/domain/entities/entities.dart';

void main() {
  final stamp = Timestamp.fromDate(DateTime(2026, 11, 2, 9, 30));

  test('user round trip keeps the ERD fields', () {
    final user = userFromMap('u1', {
      'name': 'Uwase Esperance',
      'email': 'e@example.com',
      'phone': '0781234567',
      'district': 'Huye',
      'role': 'owner',
      'status': 'pending',
      'createdAt': stamp,
    });
    expect(user.role, Role.owner);
    expect(user.isActive, isFalse);
    expect(user.createdAt, DateTime(2026, 11, 2, 9, 30));
  });

  test('user defaults when fields are missing', () {
    final user = userFromMap('u2', {});
    expect(user.role, Role.farmer);
    expect(user.status, UserStatus.active);
    expect(user.name, isEmpty);
  });

  test('equipment mapping including specs', () {
    final e = equipmentFromMap('eq1', {
      'ownerId': 'o1',
      'ownerName': 'Agasaro',
      'name': 'Tractor',
      'type': 'Tractor',
      'district': 'Huye',
      'sector': 'Mbazi',
      'price': 25000,
      'unit': 'hour',
      'status': 'Booked',
      'about': 'Big',
      'jobs': 3,
      'specs': [
        {'k': 'Power', 'v': '50 HP'},
        'ignored',
      ],
    });
    // The retired 'Booked' status reads as not in maintenance; dates decide bookings now.
    expect(e.inMaintenance, isFalse);
    expect(equipmentFromMap('e2', {'status': 'Maintenance'}).inMaintenance, isTrue);
    expect(equipmentFromMap('e3', {'inMaintenance': true}).inMaintenance, isTrue);
    expect(e.specs.single.key, 'Power');
    expect(e.jobs, 3);
    final map = equipmentToMap(e);
    expect(map['specs'], [
      {'k': 'Power', 'v': '50 HP'}
    ]);
    expect(map.containsKey('jobs'), isFalse);
  });

  test('photo urls map and equipment falls back to the category image', () {
    final withPhoto = equipmentFromMap('e', {'type': 'Pump', 'photoUrl': 'https://x/e.jpg'});
    expect(withPhoto.image, 'https://x/e.jpg');
    expect(equipmentToMap(withPhoto)['photoUrl'], 'https://x/e.jpg');
    expect(equipmentFromMap('e', {'type': 'Pump'}).image, 'pump.jpg');
    expect(userFromMap('u', {'photoUrl': 'https://x/a.jpg'}).photoUrl, 'https://x/a.jpg');
    expect(userFromMap('u', {}).photoUrl, '');
  });

  test('booking mapping', () {
    final b = bookingFromMap('NTZ-2041', {
      'kind': 'equipment',
      'title': 'Maize',
      'status': 'Confirmed',
      'total': 15000,
      'farmerId': 'f1',
      'providerId': 'p1',
      'paidVia': 'MTN MoMo',
      'createdAt': stamp,
    });
    expect(b.kind, 'equipment');
    expect(b.isPaid, isTrue);
    expect(b.created, '02 Nov');
    expect(bookingFromMap('x', {}).createdAt, isNull);
  });

  test('notification and client mappers', () {
    final n =
        notificationFromMap('n1', {'userId': 'u', 'title': 'T', 'body': 'B', 'unread': false});
    expect(n.unread, isFalse);
    final c = clientFromMap('c1', {'agentId': 'a', 'name': 'N', 'phone': '07', 'district': 'Huye'});
    expect(clientToMap(c)['agentId'], 'a');
  });
}
