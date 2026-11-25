import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../auth_state.dart';
import '../widgets.dart';

String? vRequired(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
String? vEmail(String? v) =>
    (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) ? 'Enter a valid email' : null;
String? vPassword(String? v) => (v == null || v.length < 8) ? 'At least 8 characters' : null;

void _done(BuildContext context) => Navigator.of(context).popUntil((r) => r.isFirst);

class AuthScreen extends StatefulWidget {
  final bool pushed;
  const AuthScreen({super.key, this.pushed = false});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _key = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false, _hide = true;

  Future<void> _login() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthState>().login(_email.text.trim(), _password.text);
      if (mounted) _done(context);
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: widget.pushed ? AppBar(title: const Text('Log in')) : null,
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
            const SizedBox(height: 16),
            Icon(Icons.health_and_safety, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text('Safeguard Safety',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const Text('& Management Center', textAlign: TextAlign.center),
            const SizedBox(height: 32),
            Form(
              key: _key,
              child: Column(children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  validator: vEmail,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: _hide,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                        icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _hide = !_hide)),
                  ),
                  validator: vRequired,
                  onFieldSubmitted: (_) => _login(),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _login,
              child: _busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Log in'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: const Text('Create an account'),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterCompanyScreen())),
              child: const Text('Register your company'),
            ),
          ]),
        ),
      );

}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController(), _email = TextEditingController(), _phone = TextEditingController();
  final _password = TextEditingController(), _code = TextEditingController();
  bool _busy = false;

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthState>().register({
        'fullName': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'password': _password.text,
        if (_code.text.trim().isNotEmpty) 'joinCode': _code.text.trim(),
      });
      if (mounted) _done(context);
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create account')),
        body: Form(
          key: _key,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full name'), validator: vRequired),
            const SizedBox(height: 14),
            TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: vEmail),
            const SizedBox(height: 14),
            TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number'),
                validator: vRequired),
            const SizedBox(height: 14),
            TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: vPassword),
            const SizedBox(height: 14),
            TextFormField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                  labelText: 'Company code (optional)', helperText: 'Enter this if your employer gave you a code'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create account'),
            ),
          ]),
        ),
      );

}

class RegisterCompanyScreen extends StatefulWidget {
  const RegisterCompanyScreen({super.key});
  @override
  State<RegisterCompanyScreen> createState() => _RegisterCompanyScreenState();
}

class _RegisterCompanyScreenState extends State<RegisterCompanyScreen> {
  final _key = GlobalKey<FormState>();
  final _company = TextEditingController(), _rc = TextEditingController(), _industry = TextEditingController();
  final _address = TextEditingController(), _name = TextEditingController(), _title = TextEditingController();
  final _email = TextEditingController(), _phone = TextEditingController(), _password = TextEditingController();
  bool _busy = false;

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final code = await context.read<AuthState>().registerCompany({
        'fullName': _name.text.trim(),
        'jobTitle': _title.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'password': _password.text,
        'company': {
          'name': _company.text.trim(),
          'rcNumber': _rc.text.trim(),
          'industry': _industry.text.trim(),
          'address': _address.text.trim(),
        },
      });
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Company registered'),
          content: Text('Share this code with your staff so they can join your company when they sign up:\n\n$code'),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Done'))],
        ),
      );
      if (mounted) _done(context);
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _f(TextEditingController c, String label,
          {bool req = true, TextInputType? type, bool obscure = false, String? Function(String?)? validator}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: c,
          keyboardType: type,
          obscureText: obscure,
          decoration: InputDecoration(labelText: req ? label : '$label (optional)'),
          validator: validator ?? (req ? vRequired : null),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Register your company')),
        body: Form(
          key: _key,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Text('Company details', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _f(_company, 'Company name'),
            _f(_rc, 'RC number', req: false),
            _f(_industry, 'Industry', req: false),
            _f(_address, 'Address', req: false),
            const SizedBox(height: 8),
            Text('Your details (company administrator)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _f(_name, 'Full name'),
            _f(_title, 'Job title', req: false),
            _f(_email, 'Work email', type: TextInputType.emailAddress, validator: vEmail),
            _f(_phone, 'Phone number', type: TextInputType.phone),
            _f(_password, 'Password', obscure: true, validator: vPassword),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Register company'),
            ),
          ]),
        ),
      );
}
