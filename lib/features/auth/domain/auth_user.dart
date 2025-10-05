class AuthUser {
  final String uid;
  final String email;
  final String? name;       // Ime i prezime
  final String role;        // 'student' | 'organizer'
  final String? faculty;    // FPMOZ, FSRE, EF, FF...
  final String? indexNo;    // npr. 14488

  const AuthUser({
    required this.uid,
    required this.email,
    this.name,
    this.role = 'student',
    this.faculty,
    this.indexNo,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'name': name,
        'role': role,
        'faculty': faculty,
        'indexNo': indexNo,
      };

  static AuthUser? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final uid = json['uid'] as String?;
    final email = json['email'] as String?;
    if (uid == null || email == null) return null;
    return AuthUser(
      uid: uid,
      email: email,
      name: json['name'] as String?,
      role: (json['role'] as String?) ?? 'student',
      faculty: json['faculty'] as String?,
      indexNo: json['indexNo'] as String?,
    );
  }

  AuthUser copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? faculty,
    String? indexNo,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      faculty: faculty ?? this.faculty,
      indexNo: indexNo ?? this.indexNo,
    );
  }
}
