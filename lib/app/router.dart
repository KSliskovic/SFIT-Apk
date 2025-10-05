import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/events/presentation/events_list_screen.dart';
import '../features/results/presentation/results_screen.dart';
import '../features/profile/presentation/profile_screen.dart';

final router = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navShell) {
        return Scaffold(
          body: navShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: navShell.currentIndex,
            onDestinationSelected: navShell.goBranch,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.event), label: "Događaji"),
              NavigationDestination(icon: Icon(Icons.bar_chart), label: "Rezultati"),
              NavigationDestination(icon: Icon(Icons.person), label: "Profil"),
            ],
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/events',
              builder: (context, state) => const EventsListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/results',
              builder: (context, state) => const ResultsScreen(),
            ),
          ],
        ),
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
  initialLocation: '/events',
);
