import '../../core/utils/formatters.dart';

/// One line of an equipment specification sheet, e.g. `Power` → `50 HP`.
class Spec {
  const Spec(this.key, this.value);
  final String key;
  final String value;
}

/// What a farmer sees on a machine. Worked out from the maintenance flag and
/// the calendar — never stored.
enum Availability { maintenance, freeToday, freeLater, fullyBooked }

const equipmentTypes = ['Tractor', 'Harvester', 'Planter', 'Pump', 'Tiller', 'Sheller'];
const equipmentUnits = ['hour', 'day', 'hectare'];

/// Asset photo used for a machine of the given [type].
String imageForType(String type) => switch (type) {
      'Harvester' || 'Sheller' => 'harvester.jpg',
      'Planter' => 'planter.jpg',
      'Pump' => 'pump.jpg',
      'Tiller' => 'tiller.jpg',
      _ => 'tractor.jpg',
    };

/// A machine that can be hired — the `equipment/{id}` document.
class Equipment {
  const Equipment({
    required this.id,
    required this.name,
    required this.type,
    required this.district,
    required this.price,
    required this.unit,
    this.sector = '',
    this.ownerId = '',
    this.ownerName = '',
    this.inMaintenance = false,
    this.about = '',
    this.photoUrl = '',
    this.jobs = 0,
    this.specs = const [],
    this.bookedDates = const [],
    this.blockedDates = const [],
  });

  final String id;
  final String name;
  final String type;
  final String district;
  final String sector;
  final int price;

  /// `hour`, `day` or `hectare`.
  final String unit;
  final String ownerId;
  final String ownerName;

  /// The one thing the owner sets by hand: out of service, blocks every date.
  final bool inMaintenance;
  final String about;

  /// Owner-uploaded photo (R2 URL). Empty means use the category image.
  final String photoUrl;

  /// Completed jobs — a counter maintained when a booking is completed.
  final int jobs;
  final List<Spec> specs;

  /// Days (`yyyy-MM-dd`) already taken by a pending or confirmed booking.
  final List<String> bookedDates;

  /// Days (`yyyy-MM-dd`) the owner switched off, e.g. for a private job.
  final List<String> blockedDates;

  bool isBookedOn(DateTime day) => bookedDates.contains(dateKey(day));
  bool isBlockedOn(DateTime day) => blockedDates.contains(dateKey(day));

  /// True when a farmer cannot book [day] (taken or blocked by the owner).
  bool isUnavailableOn(DateTime day) => isBookedOn(day) || isBlockedOn(day);

  /// Owner-blocked days from today on, soonest first.
  List<DateTime> get upcomingBlockedDays => _upcoming(blockedDates);

  /// Taken days from today on, soonest first.
  List<DateTime> get upcomingBookedDays => _upcoming(bookedDates);

  static List<DateTime> _upcoming(List<String> keys) {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return <DateTime>[
      for (final k in keys)
        if (DateTime.tryParse(k) case final d? when !d.isBefore(today)) d
    ]..sort();
  }

  bool get hasUpcomingBookings => upcomingBookedDays.isNotEmpty;

  /// First day on or after [from] that is not taken.
  DateTime firstFreeDay(DateTime from) {
    var d = DateTime(from.year, from.month, from.day);
    while (isUnavailableOn(d)) {
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return d;
  }

  /// The uploaded photo when there is one, otherwise the category image.
  String get image => photoUrl.isNotEmpty ? photoUrl : imageForType(type);
  String get place => sector.isEmpty ? district : '$district · $sector';

  /// How many days ahead we look for a free day before calling it fully booked.
  static const horizonDays = 60;

  /// First free day from today within [horizonDays], or null when none.
  DateTime? get nextFreeDay {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    for (var i = 0; i < horizonDays; i++) {
      final d = DateTime(today.year, today.month, today.day + i);
      if (!isUnavailableOn(d)) return d;
    }
    return null;
  }

  Availability get availability {
    if (inMaintenance) return Availability.maintenance;
    final next = nextFreeDay;
    if (next == null) return Availability.fullyBooked;
    final n = DateTime.now();
    return next == DateTime(n.year, n.month, n.day)
        ? Availability.freeToday
        : Availability.freeLater;
  }

  /// Chip text: "In maintenance", "Free today", "Free from 26 Nov" or "Fully booked".
  String get availabilityLabel => switch (availability) {
        Availability.maintenance => 'In maintenance',
        Availability.freeToday => 'Free today',
        Availability.freeLater => 'Free from ${dayMonth(nextFreeDay!)}',
        Availability.fullyBooked => 'Fully booked',
      };

  /// A farmer can start a booking (some day is still free).
  bool get bookable =>
      availability == Availability.freeToday || availability == Availability.freeLater;

  /// `hr`, `day` or `ha` for compact price lines.
  String get unitShort => switch (unit) {
        'hour' => 'hr',
        'hectare' => 'ha',
        _ => 'day',
      };

  Equipment copyWith({
    String? name,
    String? type,
    String? district,
    String? sector,
    int? price,
    String? unit,
    bool? inMaintenance,
    String? about,
    String? photoUrl,
    String? ownerName,
    String? id,
    List<String>? blockedDates,
  }) =>
      Equipment(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        district: district ?? this.district,
        sector: sector ?? this.sector,
        price: price ?? this.price,
        unit: unit ?? this.unit,
        ownerId: ownerId,
        ownerName: ownerName ?? this.ownerName,
        inMaintenance: inMaintenance ?? this.inMaintenance,
        about: about ?? this.about,
        photoUrl: photoUrl ?? this.photoUrl,
        jobs: jobs,
        specs: specs,
        bookedDates: bookedDates,
        blockedDates: blockedDates ?? this.blockedDates,
      );
}
