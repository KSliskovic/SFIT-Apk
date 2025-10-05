import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/auth_user.dart';
import 'auth_repository.dart';
import 'users_repository.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) => UsersRepository());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(usersRepositoryProvider)),
);

/// Trenutni korisnik (učitava se iz SharedPreferences)
final authUserProvider = FutureProvider<AuthUser?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getCurrentUser();
});

/// (Alias, ako negdje koristiš currentUserProvider)
final currentUserProvider = authUserProvider;

final authActionsProvider = Provider<AuthActions>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthActions(ref, repo);
});

class AuthActions {
  final Ref ref;
  final AuthRepository repo;
  AuthActions(this.ref, this.repo);

  Future<void> signOut() async {
    await repo.signOut();
    ref.invalidate(authUserProvider);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? faculty,
    String? indexNo,
    String? organizerCode,
  }) async {
    await repo.register(
      name: name,
      email: email,
      password: password,
      role: role,
      faculty: faculty,
      indexNo: indexNo,
      organizerCode: organizerCode,
    );
    ref.invalidate(authUserProvider);
  }

  Future<void> login({required String email, required String password}) async {
    await repo.login(email: email, password: password);
    ref.invalidate(authUserProvider);
  }
}
