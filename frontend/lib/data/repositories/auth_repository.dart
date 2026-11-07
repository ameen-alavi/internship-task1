import '../mock/mock_users.dart';
import '../models/user_model.dart';

abstract class IAuthRepository {
  Future<User?> getCurrentUser();
  Future<User> login(String email, String password);
  Future<User> register({
    required String name,
    required String email,
    required String password,
  });
  Future<void> logout();
}

class MockAuthRepository implements IAuthRepository {
  User? _currentUser;

  @override
  Future<User?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _currentUser;
  }

  @override
  Future<User> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final normalized = email.trim().toLowerCase();
    final match = [
      ...MockUsers.allUsers,
      ..._registeredUsers.values,
    ].where((u) => u.email.toLowerCase() == normalized).firstOrNull;
    if (match == null ||
        (MockUsers.allUsers.contains(match) &&
            password != MockUsers.demoPassword) ||
        (_registeredPasswords[normalized] != null &&
            _registeredPasswords[normalized] != password))
      throw Exception('Email or password is incorrect.');
    _currentUser = match;
    return _currentUser!;
  }

  final Map<String, User> _registeredUsers = {};
  final Map<String, String> _registeredPasswords = {};

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final normalized = email.trim().toLowerCase();
    if (MockUsers.allUsers.any((u) => u.email.toLowerCase() == normalized) ||
        _registeredUsers.containsKey(normalized))
      throw Exception('An account with this email already exists.');
    final user = User(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: normalized,
      role: UserRole.requester,
      department: 'Not specified',
      designation: 'Requester',
    );
    _registeredUsers[normalized] = user;
    _registeredPasswords[normalized] = password;
    _currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _currentUser = null;
  }
}
