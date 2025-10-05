import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_providers.dart';

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
  final _orgCode = TextEditingController();

  String _role = 'student';
  String? _faculty;
  final _faculties = const ['FPMOZ', 'FSRE', 'EF', 'FF'];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _indexNo.dispose();
    _orgCode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final actions = ref.read(authActionsProvider);
    try {
      await actions.register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        role: _role,
        faculty: _faculty,
        indexNo: _indexNo.text.trim().isEmpty ? null : _indexNo.text.trim(),
        organizerCode: _role == 'organizer' ? _orgCode.text.trim() : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true); // vrati na login/profil caller
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registracija uspješna')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
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
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obavezno' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Obavezno';
                if (!v.contains('@')) return 'Neispravan email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              decoration: const InputDecoration(
                labelText: 'Lozinka',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Obavezno';
                if (v.length < 4) return 'Min 4 znaka (demo)';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Fakultet',
                border: OutlineInputBorder(),
              ),
              value: _faculty,
              items: _faculties
                  .map((f) => DropdownMenuItem<String>(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _faculty = v),
              validator: (v) => (v == null || v.isEmpty) ? 'Odaberi fakultet' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _indexNo,
              decoration: const InputDecoration(
                labelText: 'Broj indexa (npr. 14488)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            const Text('Uloga'),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'student', label: Text('Student')),
                ButtonSegment(value: 'organizer', label: Text('Organizator')),
              ],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            if (_role == 'organizer') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _orgCode,
                decoration: const InputDecoration(
                  labelText: 'Organizatorski kod',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) {
                  if (_role != 'organizer') return null;
                  if (v == null || v.isEmpty) return 'Unesi kod';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.person_add),
              label: const Text('Registriraj se'),
            ),
          ],
        ),
      ),
    );
  }
}
