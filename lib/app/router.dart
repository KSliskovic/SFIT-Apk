import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/events/presentation/events_list_screen.dart';
import '../features/results/presentation/results_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/auth/presentation/login_screen.dart';

/// Helper koji osvježava GoRouter kad se promijeni stream (npr. auth).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _auth = FirebaseAuth.instance;

final router = GoRouter(
  // osvježi rute kad se promijeni auth state
  refreshListenable: GoRouterRefreshStream(_auth.authStateChanges()),

  // inicijalna lokacija kad je user ulogiran
  initialLocation: '/events',

  // redirect ovisno o auth stanju
  redirect: (context, state) {
    final user = _auth.currentUser;
    final loggingIn = state.matchedLocation == '/login';

    if (user == null) {
      // nije logiran -> mora na login (osim ako je već na /login)
      return loggingIn ? null : '/login';
    }

    // logiran je: ako je na /login, preusmjeri ga na /events
    if (loggingIn) return '/events';

    // sve ostalo ostaje kako je
    return null;
  },

  routes: [
    // LOGIN — izvan shell-a (nema bottom navigation)
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // SHELL s bottom NavigationBarom
    StatefulShellRoute.indexedStack(
      builder: (context, state, navShell) {
        return Scaffold(
          body: navShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: navShell.currentIndex,
            onDestinationSelected: (i) => navShell.goBranch(i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.event), label: "Događaji"),
              NavigationDestination(icon: Icon(Icons.bar_chart), label: "Rezultati"),
              NavigationDestination(icon: Icon(Icons.person), label: "Profil"),
            ],
          ),
        );
      },
      branches: [
        // Events tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/events',
              builder: (context, state) => const EventsListScreen(),
            ),
          ],
        ),
        // Results tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/results',
              builder: (context, state) => const ResultsScreen(),
            ),
          ],
        ),
        // Profile tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
