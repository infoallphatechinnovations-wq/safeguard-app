import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../auth_state.dart';
import '../models.dart';
import '../widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String? _category;
  late final Future<List<String>> _cats;

  @override
  void initState() {
    super.initState();
    _cats = context
        .read<AuthState>()
        .api
        .get('/categories')
        .then((d) => (d['categories'] as List).map((c) => c['name'] as String).toList());
  }

  // Sessions come back sorted by date; insert a month heading whenever the month changes.
  Future<List<Object>> _load() async {
    final d = await context.read<AuthState>().api.get('/sessions', query: {if (_category != null) 'category': _category!});
    final out = <Object>[];
    String? month;
    for (final j in d['sessions'] as List) {
      final s = Session.fromJson(j);
      final m = DateFormat('MMMM yyyy').format(DateTime.parse(s.startDate.substring(0, 10)));
      if (m != month) {
        out.add(m);
        month = m;
      }
      out.add(s);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            Text('Training calendar', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            FutureBuilder<List<String>>(
              future: _cats,
              builder: (context, snap) => DropdownButton<String?>(
                value: _category,
                hint: const Text('All'),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('All categories')),
                  for (final c in snap.data ?? <String>[]) DropdownMenuItem<String?>(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v),
              ),
            ),
          ]),
        ),
        Expanded(
          child: AsyncList<Object>(
            key: ValueKey(_category),
            load: _load,
            emptyText: 'No upcoming training dates have been published yet.\nPlease check back soon.',
            itemBuilder: (context, item, _) {
              if (item is String) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                  child: Text(item, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                );
              }
              final s = item as Session;
              return SessionTile(s, courseTitle: s.title ?? 'Training', priceKobo: s.priceKobo);
            },
          ),
        ),
      ]);
}
