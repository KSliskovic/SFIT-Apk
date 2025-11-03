import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_providers.dart';
import '../../profile/presentation/profile_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> with SingleTickerProviderStateMixin {
  late TabController _tab;

  // Register fields
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPassword = TextEditingController();
  final _regIndex = TextEditingController();
  final _regOrgCode = TextEditingController();
  String _regRole = 'student';
  String? _regFaculty;
  final _faculties = const ['FPMOZ', 'FSRE', 'EF', 'FF'];

  // Login fields
  final _logEmail = TextEditingController();
  final _logPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _regName.dispose();
    _regEmail.dispose();
    _regPassword.dispose();
    _regIndex.dispose();
    _regOrgCode.dispose();
    _logEmail.dispose();
    _logPassword.dispose();
    super.dispose();
  }

  void _finishAuth() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop(true);
    } else {
      nav.pushReplacement(MaterialPageRoute(builder: (_) => const ProfileScreen()));
    }
  }

  Future<void> _doRegister() async {
    final auth = ref.read(authActionsProvider);
    final name = _regName.text.trim();
    final email = _regEmail.text.trim();
    final pwd = _regPassword.text;
    final idx = _regIndex.text.trim();
    final code = _regRole == 'organizer' ? _regOrgCode.text.trim() : null;

    if (name.isEmpty) return _snack('Unesi ime i prezime');
    if (!email.contains('@')) return _snack('Unesi ispravan email');
    if (pwd.length < 4) return _snack('Lozinka min 4 znaka (demo)');
    if (_regFaculty == null || _regFaculty!.isEmpty) return _snack('Odaberi fakultet');
    if (_regRole == 'organizer' && (code == null || code.isEmpty)) {
      return _snack('Unesi organizatorski kod');
    }

    try {
      await auth.register(
        name: name,
        email: email,
        password: pwd,
        role: _regRole,
        faculty: _regFaculty,
        indexNo: idx.isEmpty ? null : idx,
        organizerCode: code,
      );
      if (!mounted) return;
      _finishAuth();
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _doLogin() async {
    final auth = ref.read(authActionsProvider);
    final email = _logEmail.text.trim();
    final pwd = _logPassword.text;

    if (!email.contains('@')) return _snack('Unesi ispravan email');
    if (pwd.isEmpty) return _snack('Unesi lozinku');

    try {
      await auth.login(email, pwd);
      if (!mounted) return;
      _finishAuth();
    } catch (e) {
      _snack(e.toString());
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SUMFIT • Prijava / Registracija'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Registracija'),
            Tab(text: 'Prijava'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // -------- REGISTER --------
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _regName,
                decoration: const InputDecoration(
                  labelText: 'Ime i prezime',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _regEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _regPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Lozinka',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _regFaculty,
                items: _faculties
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => _regFaculty = v),
                decoration: const InputDecoration(
                  labelText: 'Fakultet',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _regIndex,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Broj indexa (npr. 14488)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Uloga'),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'student', label: Text('Student')),
                  ButtonSegment(value: 'organizer', label: Text('Organizator')),
                ],
                selected: {_regRole},
                onSelectionChanged: (s) => setState(() => _regRole = s.first),
              ),
              if (_regRole == 'organizer') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _regOrgCode,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Organizatorski kod (org123)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _doRegister,
                icon: const Icon(Icons.person_add),
                label: const Text('Registriraj se'),
              ),
            ],
          ),

          // -------- LOGIN --------
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _logEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _logPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Lozinka',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _doLogin,
                icon: const Icon(Icons.login),
                label: const Text('Prijavi se'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
