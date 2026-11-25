import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../auth_state.dart';
import '../models.dart';
import '../widgets.dart';

class MyTrainingScreen extends StatelessWidget {
  const MyTrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<AuthState>().api;
    return DefaultTabController(
      length: 2,
      child: Column(children: [
        const TabBar(tabs: [Tab(text: 'Registrations'), Tab(text: 'Certificates')]),
        Expanded(
          child: TabBarView(children: [
            AsyncList<Registration>(
              load: () async => ((await api.get('/registrations/mine'))['registrations'] as List)
                  .map((r) => Registration.fromJson(r))
                  .toList(),
              emptyText: 'You have not registered for any training yet.\nBrowse Courses to get started.',
              itemBuilder: (context, r, reload) => RegistrationCard(
                r,
                trailing: (r.status == 'pending' || r.status == 'confirmed')
                    ? TextButton(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Cancel registration?'),
                              content: Text(r.courseTitle),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep it')),
                                FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Cancel it')),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          try {
                            await api.delete('/registrations/${r.id}');
                            reload();
                          } on ApiException catch (e) {
                            if (context.mounted) snack(context, e.message);
                          }
                        },
                        child: const Text('Cancel'),
                      )
                    : null,
              ),
            ),
            AsyncList<Certificate>(
              load: () async => ((await api.get('/certificates/mine'))['certificates'] as List)
                  .map((c) => Certificate.fromJson(c))
                  .toList(),
              emptyText: 'No certificates yet. They appear here once Safeguard issues them after your training.',
              itemBuilder: (context, c, _) => Card(
                child: ListTile(
                  leading: Icon(Icons.workspace_premium_outlined, color: statusColor(c.state).shade700),
                  title: Text(c.courseTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${c.certificateNumber}\nIssued ${fmtDate(c.issuedOn)}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy number',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: c.certificateNumber));
                      snack(context, 'Certificate number copied');
                    },
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
