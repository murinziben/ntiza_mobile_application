import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ntiza/domain/locations.dart';

void main() {
  final locations = RwandaLocations.fromJson(
    jsonDecode(File('assets/data/rwanda_locations.json').readAsStringSync()) as List,
  );

  test('bundled data has all 30 districts and 416 sectors', () {
    expect(locations.districts, hasLength(30));
    final total = locations.districts.fold<int>(0, (n, d) => n + locations.sectorsOf(d).length);
    expect(total, 416);
  });

  test('looks up sectors and province by district', () {
    expect(locations.hasDistrict('Huye'), isTrue);
    expect(locations.hasDistrict('Atlantis'), isFalse);
    expect(locations.provinceOf('Huye'), 'Southern Province');
    expect(locations.sectorsOf('Huye'), isNotEmpty);
    expect(locations.hasSector('Huye', locations.sectorsOf('Huye').first), isTrue);
    expect(locations.sectorsOf('Atlantis'), isEmpty);
  });

  test('groups districts by province', () {
    expect(locations.provinces, hasLength(5));
    expect(locations.districtsOf('Kigali City'), ['Gasabo', 'Kicukiro', 'Nyarugenge']);
    expect(locations.districtsOf('Atlantis'), isEmpty);
  });
}
