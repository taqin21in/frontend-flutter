class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
  });

  final String token;
  final int userId;
  final String fullName;
  final String email;
  final String phone;
  final String role;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;

    return AuthSession(
      token: json['token'] as String? ?? '',
      userId: user['id'] as int,
      fullName: user['fullName'] as String? ?? '',
      email: user['email'] as String? ?? '',
      phone: user['phone'] as String? ?? '',
      role: user['role'] as String? ?? 'CUSTOMER',
    );
  }
}
