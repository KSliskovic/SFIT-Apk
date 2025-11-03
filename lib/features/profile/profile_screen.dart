import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_providers.dart';
import '../../features/auth/domain/auth_user.dart';
import '../auth/presentation/login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Greška: $e')),
      data: (user) {
        if (user == null) {
          return _LoggedOutView(
            onLogin: () async {
              final ok = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
              if (ok == true && context.mounted) {
                // ako želiš, možeš i ref.invalidate(currentUserProvider) ovdje
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dobrodošao natrag!')),
                );
              }
            },
          );
        }
        return _LoggedInView(user: user);
      },
    );
  }
}

class _LoggedOutView extends StatelessWidget {
  // promjena: dozvoli async callback
  final Future<void> Function() onLogin;
  const _LoggedOutView({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_outline, size: 64),
              const SizedBox(height: 12),
              const Text('Nisi prijavljen', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async => onLogin(),
                icon: const Icon(Icons.login),
                label: const Text('Prijavi se'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoggedInView extends ConsumerWidget {
  final AuthUser user;
  const _LoggedInView({required this.user});

  String _roleLabel(String role) {
    if (role.isEmpty) return '—';
    return role[0].toUpperCase() + role.substring(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameOrEmail = (user.name?.trim().isNotEmpty == true)
        ? user.name!.trim()
        : user.email;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(nameOrEmail),
            subtitle: Text('Uloga: ${_roleLabel(user.role)}'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Odjava'),
            onTap: () async {
              await ref.read(authActionsProvider).signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Odjavljen')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
