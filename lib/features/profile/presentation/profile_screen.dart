import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/presentation/login_screen.dart';
import '../../organizer/presentation/organizer_hub_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Greška: $e')),
        data: (user) {
          if (user == null) {
            return _LoggedOutView(onLogin: () async {
              final ok = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
              if (ok == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dobrodošao natrag!')),
                );
              }
            });
          }
          return _LoggedInView(user: user);
        },
      ),
    );
  }
}

class _LoggedOutView extends StatelessWidget {
  final VoidCallback onLogin;
  const _LoggedOutView({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Center(
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
              onPressed: onLogin,
              icon: const Icon(Icons.login),
              label: const Text('Prijavi se'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoggedInView extends ConsumerWidget {
  final AuthUser user;
  const _LoggedInView({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = (user.name != null && user.name!.trim().isNotEmpty)
        ? user.name!
        : user.email;

    final isOrganizer = user.role == 'organizer';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 36)),
        const SizedBox(height: 12),
        Center(
          child: Text(
            displayName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        if (user.email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Center(child: Text(user.email, style: const TextStyle(color: Colors.black54))),
        ],
        const SizedBox(height: 16),
        if ((user.faculty ?? '').isNotEmpty)
          ListTile(
            leading: const Icon(Icons.school),
            title: Text('Fakultet: ${user.faculty}'),
          ),
        if ((user.indexNo ?? '').isNotEmpty)
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text('Index: ${user.indexNo}'),
          ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text('Uloga: ${user.role}'),
        ),
        if (isOrganizer) ...[
          const Divider(),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Organizer Hub'),
            subtitle: const Text('Članovi i Timovi (pregled/uređivanje/brisanje)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const OrganizerHubScreen(),
              ));
            },
          ),
        ],
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
    );
  }
}
