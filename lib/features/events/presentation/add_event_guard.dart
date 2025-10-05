import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/permissions.dart';
import 'add_event_screen.dart'; // promijeni ako je drugačije ime

class AddEventGuard extends ConsumerWidget {
  const AddEventGuard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = ref.watch(canEditProvider);
    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Novi event')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Samo organizatori mogu dodavati evente.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return const AddEventScreen();
  }
}
