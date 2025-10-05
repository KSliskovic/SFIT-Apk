import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Uloge u aplikaciji.
enum UserRole { organizer, student }

/// Držimo ulogu u state-u da se može kasnije postaviti iz auth profila.
final roleStateProvider = StateProvider<UserRole>((ref) {
  return UserRole.organizer; // <-- DEFAULT: ORGANIZATOR (ima sve ovlasti)
  // Za test studentskog moda, promijeni u: return UserRole.student;
});

/// Trenutna uloga
final userRoleProvider = Provider<UserRole>((ref) {
  return ref.watch(roleStateProvider);
});

/// Smije li uređivati/dodavati?
final canEditProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == UserRole.organizer;
});
