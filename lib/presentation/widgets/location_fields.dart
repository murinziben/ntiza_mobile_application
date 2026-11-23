import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/locations.dart';
import '../../domain/validators.dart';
import '../providers/locations_provider.dart';

/// A district and, optionally, a sector inside it.
typedef Place = ({String? district, String? sector});

const emptyPlace = (district: null, sector: null);

/// Builds a [Place] from stored strings, dropping values that are not in the
/// Rwanda hierarchy (e.g. free text saved by an older version of the app).
Place placeFrom(RwandaLocations locations, String? district, String? sector) {
  final d = locations.hasDistrict(district) ? district : null;
  final s = locations.hasSector(d, sector) ? sector : null;
  return (district: d, sector: s);
}

/// Text saved on a booking: "landmark, sector, district" (empty parts skipped).
String formatPlace(Place place, [String landmark = '']) => [
      landmark.trim(),
      place.sector ?? '',
      place.district ?? '',
    ].where((p) => p.isNotEmpty).join(', ');

const _labelStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.body);

/// Province dropdown, then a district dropdown listing only that province's
/// districts, then a sector dropdown listing only that district's sectors.
/// Changing a level clears the levels below it. Only district and sector are
/// stored; the province is derived from the district.
class LocationFields extends ConsumerStatefulWidget {
  const LocationFields({
    super.key,
    required this.value,
    required this.onChanged,
    this.showSector = true,
  });

  final Place value;
  final ValueChanged<Place> onChanged;
  final bool showSector;

  @override
  ConsumerState<LocationFields> createState() => _LocationFieldsState();
}

class _LocationFieldsState extends ConsumerState<LocationFields> {
  /// Chosen province; kept here because it can be set before any district.
  String? _province;

  @override
  void initState() {
    super.initState();
    _province = ref.read(locationsProvider).provinceOf(widget.value.district);
  }

  @override
  void didUpdateWidget(LocationFields old) {
    super.didUpdateWidget(old);
    // A district set from outside (e.g. the profile loaded) decides the province.
    final fromDistrict = ref.read(locationsProvider).provinceOf(widget.value.district);
    if (fromDistrict != null) _province = fromDistrict;
  }

  @override
  Widget build(BuildContext context) {
    final locations = ref.watch(locationsProvider);
    final value = widget.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Province', style: _labelStyle),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey('province-$_province'),
          value: _province,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          decoration: const InputDecoration(
            hintText: 'Select province',
            hintStyle: TextStyle(color: AppColors.faint),
            prefixIcon: Icon(Icons.map_outlined, color: AppColors.muted),
          ),
          items: [for (final p in locations.provinces) DropdownMenuItem(value: p, child: Text(p))],
          onChanged: (p) {
            setState(() => _province = p);
            widget.onChanged(emptyPlace);
          },
        ),
        const SizedBox(height: 16),
        const Text('District', style: _labelStyle),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey('district-$_province-${value.district}'),
          value: value.district,
          isExpanded: true,
          menuMaxHeight: 360,
          icon: const Icon(Icons.keyboard_arrow_down),
          validator: Validators.district,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: _province == null ? 'Select a province first' : 'Select district',
            hintStyle: const TextStyle(color: AppColors.faint),
            prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.muted),
          ),
          items: [
            for (final d in locations.districtsOf(_province))
              DropdownMenuItem(value: d, child: Text(d)),
          ],
          onChanged:
              _province == null ? null : (d) => widget.onChanged((district: d, sector: null)),
        ),
        if (widget.showSector) ...[
          const SizedBox(height: 16),
          const Text('Sector', style: _labelStyle),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey('sector-${value.district}-${value.sector}'),
            value: value.sector,
            isExpanded: true,
            menuMaxHeight: 360,
            icon: const Icon(Icons.keyboard_arrow_down),
            decoration: InputDecoration(
              hintText: value.district == null ? 'Select a district first' : 'Select sector',
              hintStyle: const TextStyle(color: AppColors.faint),
              prefixIcon: const Icon(Icons.place_outlined, color: AppColors.muted),
            ),
            items: [
              for (final s in locations.sectorsOf(value.district))
                DropdownMenuItem(value: s, child: Text(s)),
            ],
            onChanged: value.district == null
                ? null
                : (s) => widget.onChanged((district: value.district, sector: s)),
          ),
        ],
      ],
    );
  }
}
