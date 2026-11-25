import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_state.dart';
import '../widgets.dart';
import 'auth_screens.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final u = auth.user;
    if (u == null) return const AuthScreen();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Center(
        child: CircleAvatar(
          radius: 36,
          child: Text(u.fullName.isEmpty ? '?' : u.fullName[0].toUpperCase(), style: const TextStyle(fontSize: 28)),
        ),
      ),
      const SizedBox(height: 12),
      Center(child: Text(u.fullName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
      Center(child: StatusChip(auth.isCorporate ? 'Company admin' : (u.companyId != null ? 'Company staff' : 'Individual'), Colors.blueGrey)),
      const SizedBox(height: 24),
      ListTile(leading: const Icon(Icons.email_outlined), title: Text(u.email)),
      if (u.phone != null) ListTile(leading: const Icon(Icons.phone_outlined), title: Text(u.phone!)),
      const SizedBox(height: 24),
      OutlinedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text('Log out'),
        onPressed: () => auth.logout(),
      ),
    ]);
  }
}
