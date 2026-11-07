import '../models/user_model.dart';

class MockUsers {
  static const String demoPassword = 'EduSphere123!';
  static const User requesterUser = User(
    id: 'USR-REQ-101',
    name: 'User',
    email: 'user@edusphere.com',
    role: UserRole.requester,
    department: 'Computer Science & Engineering',
    designation: 'Research Scholar & Teaching Assistant',
    avatarUrl:
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
  );

  static const User approverUser = User(
    id: 'USR-APP-202',
    name: 'Dr. K. R. Sharma',
    email: 'kr.sharma@edusphere.com',
    role: UserRole.approver,
    department: 'Computer Science & Engineering',
    designation: 'Head of Department (HOD) & Professor',
    avatarUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
  );

  static List<User> get allUsers => [requesterUser, approverUser];
}
