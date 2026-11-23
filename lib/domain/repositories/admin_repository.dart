import '../entities/agent_client.dart';
import '../entities/app_user.dart';

/// Back-office operations: users, applications and demo data.
abstract class AdminRepository {
  Stream<List<AppUser>> watchUsers();

  /// Approve or reject a partner application.
  Future<void> decideApplication(AppUser user, {required bool approve});

  Future<void> setUserStatus(String uid, String status);

  /// Removes the profile document of another user.
  Future<void> deleteUser(String uid);

  /// Loads sample equipment and users.
  Future<void> seedDemoData();
}

/// The clients an agent books for.
abstract class AgentRepository {
  Stream<List<AgentClient>> watchClients(String agentId);
  Future<void> addClient(AgentClient client);
  Future<void> updateClient(AgentClient client);
  Future<void> deleteClient(String id);
}
