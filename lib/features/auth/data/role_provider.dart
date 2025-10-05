import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/data/profile_providers.dart';

/// READ-ONLY prikaz trenutne uloge iz profila ('student' fallback)
final roleProvider = Provider<String>((ref) {
  final async = ref.watch(profileProvider);
  return async.maybeWhen(
    data: (p) => p.role,
    orElse: () => 'student',
  );
});
