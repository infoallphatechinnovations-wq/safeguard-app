import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../auth_state.dart';
import '../models.dart';
import '../widgets.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});
  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _number = TextEditingController();
  bool _busy = false;
  Certificate? _cert;
  String? _error;

  Future<void> _verify() async {
    final n = _number.text.trim();
    if (n.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _cert = null;
      _error = null;
    });
    try {
      final d = await context.read<AuthState>().api.get('/certificates/verify/${Uri.encodeComponent(n)}');
      setState(() => _cert = Certificate.fromJson(d['certificate']));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _cert;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Verify a certificate', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      const Text('Enter the certificate number printed on a Safeguard certificate, for example SG-2026-123456.'),
      const SizedBox(height: 16),
      TextField(
        controller: _number,
        textCapitalization: TextCapitalization.characters,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(labelText: 'Certificate number', prefixIcon: Icon(Icons.badge_outlined)),
        onSubmitted: (_) => _verify(),
      ),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: _busy ? null : _verify,
        child: _busy
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Verify'),
      ),
      const SizedBox(height: 20),
      if (_error != null)
        Card(
          color: Colors.red.shade50,
          child: ListTile(leading: const Icon(Icons.error_outline, color: Colors.red), title: Text(_error!)),
        ),
      if (c != null) _ResultCard(c),
    ]);
  }
}

class _ResultCard extends StatelessWidget {
  final Certificate c;
  const _ResultCard(this.c);
  @override
  Widget build(BuildContext context) {
    final color = statusColor(c.state);
    final label = switch (c.state) {
      'valid' => 'Valid certificate',
      'expired' => 'Certificate expired',
      _ => 'Certificate revoked',
    };
    return Card(
      color: color.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(c.state == 'valid' ? Icons.verified : Icons.warning_amber_rounded, color: color.shade700),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color.shade800)),
          ]),
          const Divider(height: 24),
          _row('Holder', c.holderName),
          _row('Course', c.courseTitle),
          if (c.awardingBody != null) _row('Awarded by', c.awardingBody!),
          _row('Issued', fmtDate(c.issuedOn)),
          if (c.expiresOn != null) _row('Expires', fmtDate(c.expiresOn)),
          _row('Number', c.certificateNumber),
        ]),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 90, child: Text(k, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );
}
