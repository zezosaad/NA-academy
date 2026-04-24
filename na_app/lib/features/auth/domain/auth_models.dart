import 'dart:convert';

enum UserRole { student, teacher, admin }

enum UserStatus { active, suspended }

class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final UserRole role;
  final UserStatus status;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.role,
    required this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? json['_id'] as String?;
    final name = json['name'] as String?;
    final email = json['email'] as String?;

    if (id == null || id.isEmpty) {
      throw FormatException('User.fromJson: missing or empty "id" field in $json');
    }
    if (name == null || name.isEmpty) {
      throw FormatException('User.fromJson: missing or empty "name" field in $json');
    }
    if (email == null || email.isEmpty) {
      throw FormatException('User.fromJson: missing or empty "email" field in $json');
    }

    return User(
      id: id,
      name: name,
      email: email,
      avatarUrl: json['avatarUrl'] as String?,
      role: _parseRole(json['role'] as String?),
      status: _parseStatus(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'role': role.name,
        'status': status.name,
      };

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    UserRole? role,
    UserStatus? status,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      status: status ?? this.status,
    );
  }

  static UserRole _parseRole(String? value) {
    switch (value) {
      case 'teacher':
        return UserRole.teacher;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.student;
    }
  }

  static UserStatus _parseStatus(String? value) {
    switch (value) {
      case 'suspended':
        return UserStatus.suspended;
      default:
        return UserStatus.active;
    }
  }
}

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory AuthSession.fromTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: _extractExpiry(accessToken),
    );
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final tokens = json['tokens'] as Map<String, dynamic>?;
    final access = tokens?['accessToken'] as String? ?? '';
    final refresh = tokens?['refreshToken'] as String? ?? '';
    return AuthSession(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: _extractExpiry(access),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'tokens': {
          'accessToken': accessToken,
          'refreshToken': refreshToken,
        },
      };

  static DateTime _extractExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return DateTime.now().add(const Duration(minutes: 15));
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = json['exp'] as int?;
      if (exp == null) return DateTime.now().add(const Duration(minutes: 15));
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (_) {
      return DateTime.now().add(const Duration(minutes: 15));
    }
  }
}
