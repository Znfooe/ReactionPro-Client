final class SiteUser {
  const SiteUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String displayName;
  final String role;
  final String createdAt;
  final String? avatarUrl;

  factory SiteUser.fromJson(Map<String, Object?> json) {
    return SiteUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}
