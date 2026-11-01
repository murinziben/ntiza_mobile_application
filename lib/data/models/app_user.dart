enum UserRole { farmer, agent, owner }

class AppUser {
  const AppUser({required this.fullName, required this.phone, required this.role});

  final String fullName;
  final String phone;
  final UserRole role;

  String get firstName => fullName.split(' ').first;
}
