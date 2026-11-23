import '../entities/equipment.dart';

/// Equipment listings.
abstract class CatalogRepository {
  Stream<List<Equipment>> watchEquipment();
  Future<String> addEquipment(Equipment equipment);
  Future<void> updateEquipment(Equipment equipment);
  Future<void> deleteEquipment(String id);

  /// Replaces the owner-blocked days (`yyyy-MM-dd`) of a machine.
  Future<void> setBlockedDates(String id, List<String> dateKeys);
}
