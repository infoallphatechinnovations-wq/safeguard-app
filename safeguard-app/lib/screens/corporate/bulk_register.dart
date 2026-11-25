import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api.dart';
import '../../auth_state.dart';
import '../../models.dart';
import '../../widgets.dart';

class BulkRegisterScreen extends StatefulWidget {
  final String sessionId, courseTitle, startDate;
  final int? priceKobo;
  const BulkRegisterScreen(
      {super.key, required this.sessionId, required this.courseTitle, required this.startDate, this.priceKobo});
  @override
  State<BulkRegisterScreen> createState() => _BulkRegisterScreenState();
}

class _BulkRegisterScreenState extends State<BulkRegisterScreen> {
  late Future<List<StaffMember>> _staff;
  final _selected = <String>{};
  final _extra = <Map<String, String>>[];
  List<StaffMember> _staffList = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _staff = _load();
  }

  Future<List<StaffMember>> _load() async {
    final d = await context.read<AuthState>().api.get('/company/staff');
    _staffList = (d['staff'] as List).map((s) => StaffMember.fromJson(s)).toList();
    return _staffList;
  }

  int get _count => _selected.length + _extra.length;

  Future<void> _addPerson() async {
    final name = TextEditingController(), email = TextEditingController(), phone = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add attendee'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 10),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 10),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone (optional)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty && email.text.contains('@')) {
      setState(() => _extra.add({'name': name.text.trim(), 'email': email.text.trim(), 'phone': phone.text.trim()}));
    }
  }

  Future<void> _submit() async {
    final attendees = [
      for (final s in _staffList.where((s) => _selected.contains(s.id)))
        {'name': s.fullName, 'email': s.email, if (s.phone != null) 'phone': s.phone},
      ..._extra,
    ];
    setState(() => _busy = true);
    try {
      await context.read<AuthState>().api.post(
          '/registrations/bulk', {'sessionId': widget.sessionId, 'attendees': attendees});
      if (!mounted) return;
      snack(context, '${attendees.length} ${attendees.length == 1 ? 'person' : 'people'} registered.');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Register staff')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.courseTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text('Starts ${fmtDate(widget.startDate)}  •  ${naira(widget.priceKobo)} per person'),
              ]),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<StaffMember>>(
              future: _staff,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                if (snap.hasError) {
                  return ErrorRetry(message: snap.error.toString(), onRetry: () => setState(() => _staff = _load()));
                }
                return ListView(children: [
                  for (final s in snap.data!)
                    CheckboxListTile(
                      value: _selected.contains(s.id),
                      title: Text(s.fullName),
                      subtitle: Text(s.email),
                      onChanged: (v) => setState(() => v == true ? _selected.add(s.id) : _selected.remove(s.id)),
                    ),
                  for (final (i, p) in _extra.indexed)
                    ListTile(
                      leading: const Icon(Icons.person_add_alt_1_outlined),
                      title: Text(p['name']!),
                      subtitle: Text(p['email']!),
                      trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _extra.removeAt(i))),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: OutlinedButton.icon(
                        onPressed: _addPerson, icon: const Icon(Icons.add), label: const Text('Add someone without an account')),
                  ),
                ]);
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_count == 0 || _busy) ? null : _submit,
                  child: _busy
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_count == 0
                          ? 'Select attendees'
                          : 'Register $_count${widget.priceKobo != null ? '  •  ${naira(widget.priceKobo! * _count)}' : ''}'),
                ),
              ),
            ),
          ),
        ]),
      );
}
