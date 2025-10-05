import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/profile.dart';
import 'profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository());

/// Async profil (učitava se iz SharedPreferences-a)
final profileProvider = FutureProvider<Profile>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.load();
});

/// Akcije nad profilom
final profileActionsProvider = Provider<ProfileActions>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return ProfileActions(ref, repo);
});

class ProfileActions {
  final Ref ref;
  final ProfileRepository repo;
  ProfileActions(this.ref, this.repo);

  Future<void> save(Profile p) async {
    await repo.save(p);
    ref.invalidate(profileProvider);
  }

  Future<void> setRole(String role) async {
    final current = await ref.read(profileProvider.future);
    await save(current.copyWith(role: role));
  }

  Future<void> clear() async {
    await repo.clear();
    ref.invalidate(profileProvider);
  }
}
