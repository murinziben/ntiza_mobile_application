/// Rwanda's administrative hierarchy: province → district → sector.
class RwandaLocations {
  const RwandaLocations(this._sectorsByDistrict, this._provinceOfDistrict);

  /// Builds the lookup from the decoded `rwanda_locations.json` asset.
  factory RwandaLocations.fromJson(List<dynamic> json) {
    final sectors = <String, List<String>>{};
    final provinces = <String, String>{};
    for (final p in json) {
      final province = p['name'] as String;
      for (final d in p['districts'] as List) {
        final name = d['name'] as String;
        sectors[name] = [for (final s in d['sectors'] as List) s as String];
        provinces[name] = province;
      }
    }
    return RwandaLocations(sectors, provinces);
  }

  final Map<String, List<String>> _sectorsByDistrict;
  final Map<String, String> _provinceOfDistrict;

  /// All provinces, alphabetical.
  List<String> get provinces => _provinceOfDistrict.values.toSet().toList()..sort();

  /// Districts inside [province], alphabetical.
  List<String> districtsOf(String? province) => [
        for (final e in _provinceOfDistrict.entries)
          if (e.value == province) e.key,
      ]..sort();

  /// All districts, alphabetical.
  List<String> get districts => _sectorsByDistrict.keys.toList()..sort();

  bool hasDistrict(String? district) => _sectorsByDistrict.containsKey(district);

  /// Sectors of [district]; empty for an unknown district.
  List<String> sectorsOf(String? district) => _sectorsByDistrict[district] ?? const [];

  bool hasSector(String? district, String? sector) => sectorsOf(district).contains(sector);

  String? provinceOf(String? district) => _provinceOfDistrict[district];
}
