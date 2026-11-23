import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../providers/locations_provider.dart';
import '../../providers/providers.dart';
import '../../widgets/location_fields.dart';
import '../../widgets/ui.dart';
import 'widgets.dart';

/// Equipment categories shown on the marketplace and the home screen.
const marketplaceTypes = <(String, IconData)>[
  ('All', Icons.apps_rounded),
  ('Tractor', Icons.agriculture_outlined),
  ('Harvester', Icons.grass_rounded),
  ('Pump', Icons.water_drop_outlined),
  ('Planter', Icons.eco_outlined),
  ('Tiller', Icons.construction_rounded),
  ('Sheller', Icons.grain_rounded),
];
const _allDistricts = 'All locations';

// Ephemeral filter state lives in providers, not in widget State.
/// Not auto-disposed so the home screen can preset it before opening the marketplace.
final marketplaceTypeProvider = StateProvider<String>((ref) => 'All');
final _queryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Starts on the district saved in Settings, but can be changed here.
final _districtProvider = StateProvider.autoDispose<String>((ref) {
  final saved = ref.read(settingsControllerProvider).preferredDistrict;
  return ref.read(locationsProvider).hasDistrict(saved) ? saved : _allDistricts;
});

/// Sector inside the chosen district; empty means the whole district.
final _sectorProvider = StateProvider.autoDispose<String>((ref) => '');

/// Upper end of the price slider. Dragging the handle to it means "no maximum".
const _priceCap = 100000;
const _priceStep = 5000;
const _anyPrice = RangeValues(0, 100000);

/// Chosen price range in RWF (any unit); [_anyPrice] means no price filter.
final _priceProvider = StateProvider.autoDispose<RangeValues>((ref) => _anyPrice);

String _priceLabel(RangeValues r) {
  final lo = r.start.round(), hi = r.end.round();
  if (lo == 0 && hi >= _priceCap) return 'Any price';
  if (hi >= _priceCap) return 'From ${rwf(lo)}';
  return lo == 0 ? 'Up to ${rwf(hi)}' : '${rwf(lo)} – ${rwf(hi)}';
}

/// Browse and filter every machine on the platform.
class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  Future<void> _openFilters(BuildContext context, WidgetRef ref) async {
    final district = ref.read(_districtProvider);
    final sector = ref.read(_sectorProvider);
    final picked = await showModalBottomSheet<_Filters>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        place: (
          district: district == _allDistricts ? null : district,
          sector: sector.isEmpty ? null : sector,
        ),
        price: ref.read(_priceProvider),
      ),
    );
    if (picked == null) return;
    ref.read(_districtProvider.notifier).state = picked.place.district ?? _allDistricts;
    ref.read(_sectorProvider.notifier).state = picked.place.sector ?? '';
    ref.read(_priceProvider.notifier).state = picked.price;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(marketplaceTypeProvider);
    final district = ref.watch(_districtProvider);
    final sector = ref.watch(_sectorProvider);
    final q = ref.watch(_queryProvider).trim().toLowerCase();
    final locationFiltered = district != _allDistricts;
    final price = ref.watch(_priceProvider);
    final priceFiltered = price != _anyPrice;
    final filtered = type != 'All' || locationFiltered || priceFiltered || q.isNotEmpty;

    void clear() {
      ref.read(marketplaceTypeProvider.notifier).state = 'All';
      ref.read(_districtProvider.notifier).state = _allDistricts;
      ref.read(_sectorProvider.notifier).state = '';
      ref.read(_priceProvider.notifier).state = _anyPrice;
    }

    return Scaffold(
      appBar: const TopBar('Marketplace', back: false),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: SearchField(
              hint: 'Search equipment',
              onChanged: (v) => ref.read(_queryProvider.notifier).state = v,
              onFilter: () => _openFilters(context, ref),
            ),
          ),
          asyncSection(ref.watch(equipmentProvider), (all) {
            final items = all
                .where((e) =>
                    (type == 'All' || e.type == type) &&
                    (!locationFiltered || e.district == district) &&
                    (sector.isEmpty || e.sector == sector) &&
                    e.price >= price.start &&
                    (price.end >= _priceCap || e.price <= price.end) &&
                    (q.isEmpty ||
                        e.name.toLowerCase().contains(q) ||
                        e.district.toLowerCase().contains(q)))
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryTiles(
                  items: marketplaceTypes,
                  selected: type,
                  onSelected: (v) => ref.read(marketplaceTypeProvider.notifier).state = v,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                            items.length == 1
                                ? '1 machine found'
                                : '${items.length} machines found',
                            style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.muted)),
                      ),
                      if (priceFiltered) ...[
                        _FilterChip(
                            icon: Icons.payments_outlined,
                            label: _priceLabel(price),
                            active: true,
                            onTap: () => _openFilters(context, ref)),
                        const SizedBox(width: 8),
                      ],
                      _FilterChip(
                        icon: Icons.location_on_outlined,
                        label: !locationFiltered
                            ? 'All locations'
                            : sector.isEmpty
                                ? district
                                : '$district · $sector',
                        active: locationFiltered,
                        onTap: () => _openFilters(context, ref),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (items.isEmpty)
                        EmptyState('No machines found',
                            message: 'Try another equipment type or location.',
                            icon: Icons.search_off_rounded,
                            actionLabel: filtered ? 'Clear filters' : null,
                            onAction: clear),
                      for (var i = 0; i < items.length; i++) ...[
                        FadeSlideIn(index: i, child: EquipmentTile(item: items[i])),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Filter: $label',
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, maxWidth: 170),
            child: Center(
              child: AnimatedContainer(
                duration: motion(context, const Duration(milliseconds: 160)),
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: active ? AppColors.green100 : Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: active ? null : AppShadow.card,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 17, color: AppColors.primaryDark),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark)),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: AppColors.primaryDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

typedef _Filters = ({Place place, RangeValues price});

/// Bottom sheet with the location pickers and the price range.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.place, required this.price});
  final Place place;
  final RangeValues price;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Place _place = widget.place;
  late RangeValues _price = widget.price;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text('Price range',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                  Text(_priceLabel(_price),
                      style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark)),
                ],
              ),
              RangeSlider(
                values: _price,
                min: 0,
                max: _priceCap.toDouble(),
                divisions: _priceCap ~/ _priceStep,
                labels: RangeLabels(rwf(_price.start.round()), rwf(_price.end.round())),
                onChanged: (v) => setState(() => _price = v),
              ),
              const SizedBox(height: 8),
              LocationFields(value: _place, onChanged: (p) => setState(() => _place = p)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlineButtonX('Show all',
                        onPressed: () =>
                            Navigator.of(context).pop((place: emptyPlace, price: _anyPrice))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton('Apply',
                        onPressed: () => Navigator.of(context).pop((place: _place, price: _price))),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
