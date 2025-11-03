// lib/features/events/presentation/add_event_guard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_providers.dart';

class AddEventGuard extends ConsumerWidget {
  final Widget child;
  const AddEventGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).value;
    if (me?.role == 'organizer') return child;
    return const SizedBox.shrink();
  }
}
