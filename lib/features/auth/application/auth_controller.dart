import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumfit/core/failure.dart';
import 'package:sumfit/core/result.dart';
import '../data/auth_providers.dart';
import '../data/auth_repository.dart';

class AuthController extends AutoDisposeAsyncNotifier<void> {
  late AuthRepository _repo;

  @override
  Future<void> build() async {
    _repo = ref.read(authRepositoryProvider);
  }

  Future<Result<void>> register({
    required String name,
    required String email,
    required String password,
    required String role, // 'student' | 'organizer'
    String? faculty,
    String? indexNo,
    String? organizerCode,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.register(
        name: name,
        email: email,
        password: password,
        role: role,
        faculty: faculty,
        indexNo: indexNo,
        organizerCode: organizerCode,
      );
      ref.invalidate(authUserProvider);
      state = const AsyncData(null);
      return const Success(null);
    } catch (e, st) {
      final f = mapError(e, st);
      state = AsyncError(f, st);
      return Error(f);
    }
  }

  Future<Result<void>> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.login(email: email, password: password);
      ref.invalidate(authUserProvider);
      state = const AsyncData(null);
      return const Success(null);
    } catch (e, st) {
      final f = mapError(e, st);
      state = AsyncError(f, st);
      return Error(f);
    }
  }

  Future<void> logout() async {
    try {
      await _repo.signOut();
      ref.invalidate(authUserProvider);
    } catch (_) {}
  }
}

final authControllerProvider =
    AutoDisposeAsyncNotifierProvider<AuthController, void>(() => AuthController());
