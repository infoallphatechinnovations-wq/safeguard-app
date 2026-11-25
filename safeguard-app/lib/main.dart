import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_state.dart';
import 'screens/shell.dart';
import 'theme.dart';

void main() => runApp(
      ChangeNotifierProvider(create: (_) => AuthState()..init(), child: const SafeguardApp()),
    );

class SafeguardApp extends StatelessWidget {
  const SafeguardApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ready = context.select<AuthState, bool>((a) => a.ready);
    return MaterialApp(
      title: 'Safeguard Safety',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: ready
          ? const Shell()
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
