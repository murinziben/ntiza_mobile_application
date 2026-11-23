import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ntiza/domain/entities/entities.dart';
import 'package:ntiza/domain/locations.dart';
import 'package:ntiza/presentation/providers/data_providers.dart';
import 'package:ntiza/presentation/providers/dependencies.dart';
import 'package:ntiza/presentation/providers/locations_provider.dart';
import 'package:ntiza/presentation/screens/admin/admin_screens.dart';
import 'package:ntiza/presentation/screens/agent/agent_screens.dart';
import 'package:ntiza/presentation/screens/auth/account_status_screen.dart';
import 'package:ntiza/presentation/screens/auth/complete_profile_screen.dart';
import 'package:ntiza/presentation/screens/auth/forgot_password_screen.dart';
import 'package:ntiza/presentation/screens/auth/guest_account_screen.dart';
import 'package:ntiza/presentation/screens/auth/login_screen.dart';
import 'package:ntiza/presentation/screens/auth/register_screen.dart';
import 'package:ntiza/presentation/screens/auth/verify_email_screen.dart';
import 'package:ntiza/presentation/screens/common/edit_profile_screen.dart';
import 'package:ntiza/presentation/screens/common/notifications_screen.dart';
import 'package:ntiza/presentation/screens/common/settings_screen.dart';
import 'package:ntiza/presentation/screens/farmer/book_equipment_screen.dart';
import 'package:ntiza/presentation/screens/farmer/booking_detail_screen.dart';
import 'package:ntiza/presentation/screens/farmer/farmer_dashboard.dart';
import 'package:ntiza/presentation/screens/farmer/my_bookings_screen.dart';
import 'package:ntiza/presentation/screens/farmer/payment_screen.dart';
import 'package:ntiza/presentation/screens/owner/owner_screens.dart';
import 'package:ntiza/presentation/screens/public/equipment_detail_screen.dart';
import 'package:ntiza/presentation/screens/public/help_screen.dart';
import 'package:ntiza/presentation/screens/public/home_screen.dart';
import 'package:ntiza/presentation/screens/public/marketplace_screen.dart';
import 'package:ntiza/presentation/screens/public/welcome_screen.dart';

import '../helpers/fakes.dart';

/// Phone sizes the rubric checks: ≤5.5″, ≥6.7″ and landscape.
const _sizes = <String, Size>{
  'small 360x640': Size(360, 640),
  'large 430x932': Size(430, 932),
  'landscape 800x360': Size(800, 360),
};

final _locations = RwandaLocations.fromJson([
  {
    'name': 'Southern Province',
    'districts': [
      {
        'name': 'Huye',
        'sectors': ['Ngoma', 'Tumba']
      },
    ],
  },
  {
    'name': 'Kigali City',
    'districts': [
      {
        'name': 'Gasabo',
        'sectors': ['Remera']
      },
    ],
  },
]);

final _bookings = [
  for (final status in [
    BookingStatus.pending,
    BookingStatus.confirmed,
    BookingStatus.completed,
    BookingStatus.cancelled,
  ])
    sampleBooking(ref: 'NTZ-$status', status: status),
];

const _notifications = [
  AppNotification(
      id: 'n1',
      userId: 'farmer1',
      title: 'Booking confirmed',
      body: 'Tractor 50HP',
      kind: 'booking'),
  AppNotification(
      id: 'n2',
      userId: 'farmer1',
      title: 'Payment received',
      body: 'RWF 100,000',
      kind: 'payment',
      unread: false),
];

/// Signed-in fake repositories so screens render real data without Firebase.
List<Override> _overrides(AppUser user) {
  final bookings = FakeBookingRepository()
    ..farmerBookings = _bookings
    ..providerBookings = _bookings;
  return [
    authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
    catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()..added.add(sampleTractor)),
    bookingRepositoryProvider.overrideWithValue(bookings),
    notificationRepositoryProvider.overrideWithValue(FakeNotificationRepository()),
    adminRepositoryProvider.overrideWithValue(FakeAdminRepository()),
    agentRepositoryProvider.overrideWithValue(FakeAgentRepository()),
    settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
    locationsProvider.overrideWithValue(_locations),
    sessionProvider.overrideWith((ref) => Stream.value(
        AuthSession(uid: user.uid, email: 'a@b.rw', emailVerified: true, usesPassword: true))),
    profileProvider.overrideWith((ref) => Stream.value(user)),
    notificationsProvider.overrideWith((ref) => Stream.value(_notifications)),
  ];
}

void main() {
  final screens = <String, (AppUser, Widget Function())>{
    'LoginScreen': (sampleFarmer, () => const LoginScreen()),
    'RegisterScreen': (sampleFarmer, () => const RegisterScreen()),
    'CompleteProfileScreen': (sampleFarmer, () => const CompleteProfileScreen()),
    'ForgotPasswordScreen': (sampleFarmer, () => const ForgotPasswordScreen()),
    'VerifyEmailScreen': (sampleFarmer, () => const VerifyEmailScreen()),
    'AccountStatusScreen': (sampleFarmer, () => const AccountStatusScreen()),
    'GuestAccountScreen': (sampleFarmer, () => const GuestAccountScreen()),
    'WelcomeScreen': (sampleFarmer, () => const WelcomeScreen()),
    'HomeScreen': (sampleFarmer, () => const HomeScreen()),
    'HelpScreen': (sampleFarmer, () => const HelpScreen()),
    'MarketplaceScreen': (sampleFarmer, () => const MarketplaceScreen()),
    'EquipmentDetailScreen': (sampleFarmer, () => const EquipmentDetailScreen(id: 'eq1')),
    'EditProfileScreen': (sampleFarmer, () => const EditProfileScreen()),
    'SettingsScreen': (sampleFarmer, () => const SettingsScreen()),
    'NotificationsScreen': (sampleFarmer, () => const NotificationsScreen()),
    'FarmerDashboard': (sampleFarmer, () => const FarmerDashboard()),
    'MyBookingsScreen': (sampleFarmer, () => const MyBookingsScreen()),
    'BookEquipmentScreen': (sampleFarmer, () => const BookEquipmentScreen(equipmentId: 'eq1')),
    'BookingDetailScreen pending': (
      sampleFarmer,
      () => const BookingDetailScreen(bookingRef: 'NTZ-Pending')
    ),
    'BookingDetailScreen confirmed': (
      sampleFarmer,
      () => const BookingDetailScreen(bookingRef: 'NTZ-Confirmed')
    ),
    'BookingDetailScreen completed': (
      sampleFarmer,
      () => const BookingDetailScreen(bookingRef: 'NTZ-Completed')
    ),
    'PaymentScreen': (sampleFarmer, () => const PaymentScreen(bookingRef: 'NTZ-Pending')),
    'OwnerDashboard': (sampleOwner, () => const OwnerDashboard()),
    'OwnerEquipmentScreen': (sampleOwner, () => const OwnerEquipmentScreen()),
    'EquipmentFormScreen new': (sampleOwner, () => const EquipmentFormScreen()),
    'EquipmentFormScreen edit': (sampleOwner, () => const EquipmentFormScreen(equipmentId: 'eq1')),
    'OwnerBookingsScreen': (sampleOwner, () => const OwnerBookingsScreen()),
    'AgentDashboard': (sampleOwner, () => const AgentDashboard()),
    'AgentFarmersScreen': (sampleOwner, () => const AgentFarmersScreen()),
    'AgentClientFormScreen new': (sampleOwner, () => const AgentClientFormScreen()),
    'AgentNewBookingScreen': (sampleOwner, () => const AgentNewBookingScreen()),
    'AgentCommissionScreen': (sampleOwner, () => const AgentCommissionScreen()),
    'AdminOverview': (sampleOwner, () => const AdminOverview()),
    'AdminUsersScreen': (sampleOwner, () => const AdminUsersScreen()),
    'AdminBookingsScreen': (sampleOwner, () => const AdminBookingsScreen()),
  };

  group('screens render without errors or overflow', () {
    for (final entry in screens.entries) {
      for (final size in _sizes.entries) {
        testWidgets('${entry.key} @ ${size.key}', (tester) async {
          tester.view.physicalSize = size.value;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(ProviderScope(
            overrides: _overrides(entry.value.$1),
            child: MaterialApp(home: entry.value.$2()),
          ));
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
