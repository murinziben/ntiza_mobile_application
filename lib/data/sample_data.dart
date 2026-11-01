import 'models/app_user.dart';
import 'models/booking.dart';
import 'models/equipment.dart';

// Placeholder data used until the backend is connected (Step 4/5).
// Photos are stand-ins and will be replaced by the real equipment photos.
const _tractorPhoto =
    'https://images.unsplash.com/photo-1592805144716-feeccccef5ac?auto=format&fit=crop&w=800&q=82';
const _fieldPhoto =
    'https://images.unsplash.com/photo-1682773083912-ff5ee5fa557b?auto=format&fit=crop&w=900&q=82';
const _harvestPhoto =
    'https://images.unsplash.com/photo-1692019007242-36158877ec96?auto=format&fit=crop&w=900&q=82';

const sampleUser = AppUser(
  fullName: 'Marie Uwimana',
  phone: '+250 788 123 456',
  role: UserRole.farmer,
);

const sampleEquipment = <Equipment>[
  Equipment(
    id: 'eq-tractor',
    name: 'John Deere Tractor',
    type: 'Tractor',
    district: 'Nyagatare',
    province: 'Eastern Province',
    pricePerDay: 45000,
    imageUrls: [_tractorPhoto, _fieldPhoto, _harvestPhoto, _tractorPhoto],
    description:
        'Reliable 75 HP tractor suited for ploughing and land preparation. An experienced operator is included.',
    specs: EquipmentSpecs(power: '75 HP', operatorIncluded: true, minDays: 1),
    providerName: 'Green Valley Services',
    available: true,
  ),
  Equipment(
    id: 'eq-sheller',
    name: 'Combined Maize Sheller',
    type: 'Maize sheller',
    district: 'Musanze',
    province: 'Northern Province',
    pricePerDay: 10000,
    imageUrls: [_harvestPhoto],
    description:
        'Fast, reliable maize sheller for harvest season. Handles large volumes with minimal grain damage.',
    specs: EquipmentSpecs(power: '12 HP', operatorIncluded: true, minDays: 1),
    providerName: 'Green Valley Services',
    available: true,
  ),
  Equipment(
    id: 'eq-plough',
    name: 'Field Plough Service',
    type: 'Ploughing',
    district: 'Huye',
    province: 'Southern Province',
    pricePerDay: 28000,
    imageUrls: [_fieldPhoto],
    description: 'Full field ploughing service with tractor and experienced operator.',
    specs: EquipmentSpecs(power: '60 HP', operatorIncluded: true, minDays: 1),
    providerName: 'Green Valley Services',
    available: true,
  ),
];

final sampleBookings = <Booking>[
  Booking(
    id: 'bk-1',
    reference: 'NTZ-261030-018',
    equipmentId: 'eq-tractor',
    equipmentName: 'John Deere Tractor',
    equipmentImageUrl: _tractorPhoto,
    location: 'Kayonza',
    date: DateTime(2026, 11, 24),
    farmSizeHectares: 2.5,
    estimatedTotal: 45000,
    status: BookingStatus.pending,
    createdAt: DateTime(2026, 10, 30),
  ),
  Booking(
    id: 'bk-2',
    reference: 'NTZ-261010-009',
    equipmentId: 'eq-sheller',
    equipmentName: 'Combined Maize Sheller',
    equipmentImageUrl: _harvestPhoto,
    location: 'Musanze',
    date: DateTime(2026, 11, 18),
    farmSizeHectares: 1.0,
    estimatedTotal: 10000,
    status: BookingStatus.approved,
    createdAt: DateTime(2026, 10, 10),
  ),
];
