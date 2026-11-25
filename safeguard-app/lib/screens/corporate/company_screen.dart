import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../auth_state.dart';
import '../../models.dart';
import '../../widgets.dart';
import 'quote.dart';

class CompanyScreen extends StatelessWidget {
  const CompanyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<AuthState>().api;
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        const TabBar(tabs: [Tab(text: 'Overview'), Tab(text: 'Staff'), Tab(text: 'Bookings')]),
        Expanded(
          child: TabBarView(children: [
            _Overview(api: api),
            AsyncList<StaffMember>(
              load: () async =>
                  ((await api.get('/company/staff'))['staff'] as List).map((s) => StaffMember.fromJson(s)).toList(),
              emptyText: 'No staff yet. Share your company code so they can join.',
              itemBuilder: (context, s, _) => Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(s.fullName[0].toUpperCase())),
                  title: Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text([if (s.jobTitle != null && s.jobTitle!.isNotEmpty) s.jobTitle!, s.email].join('\n')),
                  isThreeLine: s.jobTitle != null && s.jobTitle!.isNotEmpty,
                ),
              ),
            ),
            AsyncList<Registration>(
              load: () async => ((await api.get('/company/registrations'))['registrations'] as List)
                  .map((r) => Registration.fromJson(r))
                  .toList(),
              emptyText: 'No bookings yet.\nOpen the Calendar tab and tap "Register staff" on a date.',
              itemBuilder: (context, r, _) => RegistrationCard(r, showAttendee: true),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Overview extends StatefulWidget {
  final dynamic api;
  const _Overview({required this.api});
  @override
  State<_Overview> createState() => _OverviewState();
}

class _OverviewState extends State<_Overview> {
  late Future<dynamic> _f = widget.api.get('/company');

  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
        future: _f,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) {
            return ErrorRetry(message: snap.error.toString(), onRetry: () => setState(() => _f = widget.api.get('/company')));
          }
          final c = snap.data['company'] as Map<String, dynamic>;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(c['name'], style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            if (c['industry'] != null) Text(c['industry']),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Staff join code', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(c['joinCode'] ?? '-', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: c['joinCode'] ?? ''));
                        snack(context, 'Code copied');
                      },
                    ),
                  ]),
                  const Text('Staff enter this code when creating their account to join your company.'),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(children: [
                ListTile(leading: const Icon(Icons.email_outlined), title: Text(c['contactEmail'] ?? '')),
                if (c['contactPhone'] != null) ListTile(leading: const Icon(Icons.phone_outlined), title: Text(c['contactPhone'])),
                if (c['address'] != null && c['address'].toString().isNotEmpty)
                  ListTile(leading: const Icon(Icons.place_outlined), title: Text(c['address'])),
              ]),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.request_quote_outlined),
              label: const Text('Request in-company training quote'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuoteScreen())),
            ),
          ]);
        },
      );
}
