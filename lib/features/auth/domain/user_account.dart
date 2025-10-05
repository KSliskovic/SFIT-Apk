class UserAccount {
  final String name;
  final String email;
  final String password; // DEMO: plain text (ne za produkciju)
  final String role; // 'student' | 'organizer'
  final String faculty; // npr. FPMOZ, FSRE, EF, FF
  final String indexNo; // npr. "14488"

  const UserAccount({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.faculty,
    required this.indexNo,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'password': password,
    'role': role,
    'faculty': faculty,
    'indexNo': indexNo,
  };

  static UserAccount fromJson(Map<String, dynamic> json) => UserAccount(
    name: (json['name'] as String?)?.trim() ?? '',
    email: (json['email'] as String?)?.trim() ?? '',
    password: (json['password'] as String?) ?? '',
    role: (json['role'] as String?)?.trim().isNotEmpty == true
        ? (json['role'] as String).trim()
        : 'student',
    faculty: (json['faculty'] as String?)?.trim() ?? '',
    indexNo: (json['indexNo'] as String?)?.trim() ?? '',
  );
}
