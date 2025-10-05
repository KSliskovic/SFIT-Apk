class Profile {
  final String name;
  final String email;
  final String role; // 'student' | 'organizer'
  final String? avatarPath; // lokalna putanja slike
  final String faculty; // npr. FPMOZ, FSRE, EF, FF
  final String indexNo; // npr. "14488"

  const Profile({
    required this.name,
    required this.email,
    required this.role,
    this.avatarPath,
    this.faculty = '',
    this.indexNo = '',
  });

  Profile copyWith({
    String? name,
    String? email,
    String? role,
    String? avatarPath,
    String? faculty,
    String? indexNo,
  }) => Profile(
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
    avatarPath: avatarPath ?? this.avatarPath,
    faculty: faculty ?? this.faculty,
    indexNo: indexNo ?? this.indexNo,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'role': role,
    'avatarPath': avatarPath,
    'faculty': faculty,
    'indexNo': indexNo,
  };

  static Profile fromJson(Map<String, dynamic> json) => Profile(
    name: (json['name'] as String?)?.trim() ?? '',
    email: (json['email'] as String?)?.trim() ?? '',
    role: (json['role'] as String?)?.trim().isNotEmpty == true
        ? (json['role'] as String).trim()
        : 'student',
    avatarPath: json['avatarPath'] as String?,
    faculty: (json['faculty'] as String?)?.trim() ?? '',
    indexNo: (json['indexNo'] as String?)?.trim() ?? '',
  );
}
