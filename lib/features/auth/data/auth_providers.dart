// lib/features/auth/data/auth_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/auth_user.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.read(authRepositoryProvider).watchAuthState();
});

final currentUserProvider = FutureProvider<AuthUser?>((ref) {
  return ref.read(authRepositoryProvider).getCurrentUser();
});

final authActionsProvider = Provider<AuthActions>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return AuthActions(ref, repo);
});

class AuthActions {
  final Ref ref;
  final AuthRepository repo;
  AuthActions(this.ref, this.repo);

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
    ref.invalidate(currentUserProvider);
  }

  Future<void> login(String email, String password) async {
    await repo.login(email: email, password: password);
    ref.invalidate(currentUserProvider);
  }

  Future<void> signOut() async {
    await repo.signOut();
    ref
      ..invalidate(currentUserProvider)
      ..invalidate(authStateProvider);
  }
}
