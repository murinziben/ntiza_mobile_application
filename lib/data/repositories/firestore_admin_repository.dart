import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/agent_client.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/admin_repository.dart';
import '../mappers/firestore_mappers.dart';
import '../sample_data.dart';
import 'firebase_errors.dart';

/// Admin tools stored in Cloud Firestore.
class FirestoreAdminRepository implements AdminRepository {
  FirestoreAdminRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  @override
  Stream<List<AppUser>> watchUsers() => _users.snapshots().map(
        (q) => [for (final d in q.docs) userFromMap(d.id, d.data())],
      );

  @override
  Future<void> decideApplication(AppUser user, {required bool approve}) => guardData(
        () => _users
            .doc(user.uid)
            .update({'status': approve ? UserStatus.active : UserStatus.rejected}),
      );

  @override
  Future<void> setUserStatus(String uid, String status) =>
      guardData(() => _users.doc(uid).update({'status': status}));

  @override
  Future<void> deleteUser(String uid) => guardData(() => _users.doc(uid).delete());

  @override
  Future<void> seedDemoData() => guardData(() async {
        final batch = _db.batch();
        for (final e in sampleEquipment) {
          batch.set(_db.collection('equipment').doc(e.id), equipmentCreateMap(e));
        }
        await batch.commit();
      });
}

/// Agent clients stored in Cloud Firestore.
class FirestoreAgentRepository implements AgentRepository {
  FirestoreAgentRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('agentClients');

  @override
  Stream<List<AgentClient>> watchClients(String agentId) =>
      _col.where('agentId', isEqualTo: agentId).snapshots().map((q) {
        final list = [for (final d in q.docs) clientFromMap(d.id, d.data())]
          ..sort((a, b) => a.name.compareTo(b.name));
        return list;
      });

  @override
  Future<void> addClient(AgentClient c) => guardData(
        () => _col.add({...clientToMap(c), 'createdAt': FieldValue.serverTimestamp()}),
      );

  @override
  Future<void> updateClient(AgentClient c) =>
      guardData(() => _col.doc(c.id).update(clientToMap(c)));

  @override
  Future<void> deleteClient(String id) => guardData(() => _col.doc(id).delete());
}
