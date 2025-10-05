import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Originalni ekran (ne diramo ga)
import 'manage_roster_screen.dart';

// Role-based permissions
import '../../../core/auth/permissions.dart';

/// Wrapper koji onemogućava pristup uređivanju kad je korisnik Student.
class ManageRosterGuard extends ConsumerWidget {
  const ManageRosterGuard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = ref.watch(canEditProvider);
    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Timovi i članovi')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Samo organizatori mogu uređivati timove i članove.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    // Ako smije uređivati, prikaži originalni ekran
    return const ManageRosterScreen();
  }
}
