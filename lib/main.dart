// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'app/router.dart'; // ⬅️ router s ShellRoute-om i tabovima

// lib/main.dart
import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart';

// ...
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  dev.log('projectId: ${Firebase.app().options.projectId}');
  dev.log('appId: ${Firebase.app().options.appId}');
  dev.log('currentUser(uid): ${FirebaseAuth.instance.currentUser?.uid}');

  runApp(const ProviderScope(child: MyApp()));
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SumFit',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      // (opcionalno, ali korisno)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('hr')],
      routerConfig: router, // ⬅️ važan dio
    );
  }
}
