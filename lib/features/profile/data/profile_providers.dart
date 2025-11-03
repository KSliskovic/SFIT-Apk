import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/profile.dart';
import 'profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository());

final profileProvider = FutureProvider<Profile>((ref) async {
  final uid = await ref.watch(currentUserProvider.future).then((u) => u?.uid);
  if (uid == null) return const Profile(name: '', email: '', role: 'student');
  return ref.read(profileRepositoryProvider).load(uid);
});

final profileActionsProvider = Provider<ProfileActions>((ref) {
  return ProfileActions(ref, ref.read(profileRepositoryProvider));
});

class ProfileActions {
  final Ref ref;
  final ProfileRepository repo;
  ProfileActions(this.ref, this.repo);

  Future<void> save(Profile p) async {
    final uid = await ref.read(currentUserProvider.future).then((u) => u?.uid);
    if (uid == null) return;
    await repo.save(uid, p);
    ref.invalidate(profileProvider);
  }

  Future<void> setRole(String role) async {
    final current = await ref.read(profileProvider.future);
    await save(current.copyWith(role: role));
  }
}
