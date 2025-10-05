import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_controller.dart';
import '../data/auth_providers.dart';
import 'registration_screen.dart';

import 'package:sumfit/core/forms/validators.dart';
import 'package:sumfit/core/ui/notify.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ctrl = ref.read(authControllerProvider.notifier);
    final res = await ctrl.login(
      email: _email.text.trim(),
      password: _password.text,
    );

    if (!mounted) return;
    res.fold(
      (f) => showError(context, f.message),
      (_) {
        showSuccess(context, 'Dobrodošao!');
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // vrati na AuthGate/home
        } else {
          // Fallback: ako nema ništa za pop, zamijeni ekran profilom
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        }
      },
    );
  }

  void _goRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Prijava')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => requireEmail(v),
              enabled: !isLoading,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              decoration: const InputDecoration(
                labelText: 'Lozinka',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (v) => minLength(v, 6, label: 'Lozinka'),
              enabled: !isLoading,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: isLoading ? null : _submit,
              icon: isLoading
                  ? const SizedBox(
                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.login),
              label: Text(isLoading ? 'Prijava…' : 'Prijavi se'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: isLoading ? null : _goRegister,
              child: const Text('Nemate korisnički račun? Registrirajte se'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // Ovo je placeholder; u tvom projektu već postoji prava ProfileScreen
    return const Scaffold(body: Center(child: Text('Profil')));
  }
}
