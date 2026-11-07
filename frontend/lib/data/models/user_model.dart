enum UserRole {
  requester,
  approver;

  String get displayName {
    switch (this) {
      case UserRole.requester:
        return 'Requester (Staff / Student)';
      case UserRole.approver:
        return 'Approver (Department Head)';
    }
  }

  String get shortLabel {
    switch (this) {
      case UserRole.requester:
        return 'Requester';
      case UserRole.approver:
        return 'Approver';
    }
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String department;
  final String designation;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.designation,
    this.avatarUrl,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? department,
    String? designation,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.name,
    'department': department,
    'designation': designation,
    'avatarUrl': avatarUrl,
  };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.byName(json['role'] as String),
      department: json['department'] as String,
      designation: json['designation'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
