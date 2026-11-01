class EquipmentSpecs {
  const EquipmentSpecs({
    required this.power,
    required this.operatorIncluded,
    required this.minDays,
  });

  final String power;
  final bool operatorIncluded;
  final int minDays;
}

class Equipment {
  const Equipment({
    required this.id,
    required this.name,
    required this.type,
    required this.district,
    required this.province,
    required this.pricePerDay,
    required this.imageUrls,
    required this.description,
    required this.specs,
    required this.providerName,
    required this.available,
  });

  final String id;
  final String name;
  final String type;
  final String district;
  final String province;
  final int pricePerDay;
  final List<String> imageUrls;
  final String description;
  final EquipmentSpecs specs;
  final String providerName;
  final bool available;

  String get fullLocation => '$district, $province';
  String? get coverImage => imageUrls.isEmpty ? null : imageUrls.first;
}
