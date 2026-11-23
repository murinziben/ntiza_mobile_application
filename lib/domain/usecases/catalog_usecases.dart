import '../../core/errors/app_exception.dart';
import '../../core/utils/formatters.dart';
import '../entities/booking.dart';
import '../entities/equipment.dart';
import '../repositories/catalog_repository.dart';
import '../validators.dart';

/// Rules for listing, editing and removing equipment.
class CatalogUseCases {
  CatalogUseCases(this._catalog);

  final CatalogRepository _catalog;

  /// Validates and saves; creates when [Equipment.id] is empty, otherwise updates.
  Future<void> saveEquipment(Equipment equipment, {required String priceText}) async {
    final error = Validators.required(equipment.name, 'Equipment name') ??
        Validators.price(priceText) ??
        Validators.required(equipment.district, 'District');
    if (error != null) throw AppException(error);
    if (equipment.id.isEmpty) {
      await _catalog.addEquipment(equipment);
    } else {
      await _catalog.updateEquipment(equipment);
    }
  }

  /// Equipment with a pending or confirmed booking cannot be removed.
  Future<void> deleteEquipment(Equipment equipment, Iterable<Booking> bookings) async {
    final busy = bookings.any((b) =>
        b.itemId == equipment.id &&
        (b.status == BookingStatus.pending || b.status == BookingStatus.confirmed));
    if (busy) {
      throw const AppException('Finish or decline the open bookings on this machine first.');
    }
    await _catalog.deleteEquipment(equipment.id);
  }

  Future<void> setMaintenance(Equipment equipment, bool inMaintenance) =>
      _catalog.updateEquipment(equipment.copyWith(inMaintenance: inMaintenance));

  /// Owner switches off [days] for this machine. Days that already carry a
  /// pending or confirmed booking cannot be blocked.
  Future<void> setBlockedDays(Equipment equipment, Iterable<DateTime> days) async {
    final keys = {for (final d in days) dateKey(d)}.toList()..sort();
    final clash = keys.where(equipment.bookedDates.contains);
    if (clash.isNotEmpty) {
      throw const AppException('A booking already exists on one of those days.');
    }
    await _catalog.setBlockedDates(equipment.id, keys);
  }
}
