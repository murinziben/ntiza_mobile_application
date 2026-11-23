import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/locations.dart';

/// Rwanda's districts and sectors. Loaded from the bundled asset in `main()`
/// and overridden there; tests override it with a small fixture.
final locationsProvider = Provider<RwandaLocations>(
  (ref) => throw UnimplementedError('locationsProvider must be overridden'),
);
