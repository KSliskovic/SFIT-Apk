import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_controller.dart';
import 'package:sumfit/core/forms/validators.dart';
import 'package:sumfit/core/ui/notify.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _indexNo = TextEditingController();
  final _organizerCode = TextEditingController();

  String _role = 'student'; // 'student' | 'organizer'
  String? _faculty;

  final List<String> _faculties = const [
    'ETF', 'PMF', 'FF', 'EF', 'FESB', 'FER', 'TVZ', 'Algebra'
  ];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _indexNo.dispose();
    _organizerCode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ctrl = ref.read(authControllerProvider.notifier);
    final res = await ctrl.register(
      name: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      role: _role,
      faculty: _role == 'student' ? _faculty : null,
      indexNo: _role == 'student' ? _indexNo.text.trim() : null,
      organizerCode: _role == 'organizer' ? _organizerCode.text.trim() : null,
    );

    if (!mounted) return;
    res.fold(
      (f) => showError(context, f.message),
      (_) {
        showSuccess(context, 'Registracija uspješna');
        Navigator.of(context).pop(); // nazad na login
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Registracija')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Ime i prezime',
                border: OutlineInputBorder(),
              ),
              validator: (v) => requireText(v, label: 'Ime i prezime'),
              enabled: !isLoading,
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Uloga',
                border: OutlineInputBorder(),
              ),
              value: _role,
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Student')),
                DropdownMenuItem(value: 'organizer', child: Text('Organizator')),
              ],
              onChanged: isLoading ? null : (v) => setState(() => _role = v ?? 'student'),
            ),
            const SizedBox(height: 12),

            if (_role == 'student') ...[
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Fakultet',
                  border: OutlineInputBorder(),
                ),
                value: _faculty,
                items: _faculties.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: isLoading ? null : (v) => setState(() => _faculty = v),
                validator: (v) => (v == null || v.isEmpty) ? 'Odaberi fakultet' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _indexNo,
                decoration: const InputDecoration(
                  labelText: 'Broj indeksa',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => requireText(v, label: 'Broj indeksa'),
                enabled: !isLoading,
              ),
            ],

            if (_role == 'organizer') ...[
              TextFormField(
                controller: _organizerCode,
                decoration: const InputDecoration(
                  labelText: 'Organizer kod (ako je potreban)',
                  border: OutlineInputBorder(),
                ),
                enabled: !isLoading,
              ),
            ],

            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: isLoading ? null : _submit,
              icon: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.app_registration),
              label: Text(isLoading ? 'Spremanje…' : 'Registriraj se'),
            ),
          ],
        ),
      ),
    );
  }
}
