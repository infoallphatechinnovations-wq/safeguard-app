import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api.dart';
import 'auth_state.dart';
import 'screens/auth_screens.dart';
import 'screens/corporate/bulk_register.dart';
import 'widgets.dart';

/// Called from any "Register" button. Sends guests to log in, company admins to the
/// staff picker, and everyone else through a one-tap confirmation.
Future<void> startRegistration(BuildContext context,
    {required String sessionId,
    required String courseTitle,
    required String startDate,
    int? priceKobo}) async {
  final auth = context.read<AuthState>();
  if (!auth.isLoggedIn) {
    snack(context, 'Please log in or create an account to register.');
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(pushed: true)));
    return;
  }
  if (auth.isCorporate) {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BulkRegisterScreen(
            sessionId: sessionId, courseTitle: courseTitle, startDate: startDate, priceKobo: priceKobo),
      ),
    );
    return;
  }
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Confirm registration'),
      content: Text('$courseTitle\nStarts ${fmtDate(startDate)}\nFee: ${naira(priceKobo)}'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Register')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await auth.api.post('/registrations', {'sessionId': sessionId});
    if (context.mounted) snack(context, 'Registration received. Find it under My Training.');
  } on ApiException catch (e) {
    if (context.mounted) snack(context, e.message);
  }
}
