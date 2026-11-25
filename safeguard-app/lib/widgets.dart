import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'actions.dart';
import 'auth_state.dart';
import 'models.dart';

String naira(int? kobo) =>
    kobo == null ? 'Price on request' : '₦${NumberFormat('#,###').format(kobo ~/ 100)}';

String fmtDate(String? iso) =>
    (iso == null || iso.length < 10) ? '' : DateFormat('d MMM yyyy').format(DateTime.parse(iso.substring(0, 10)));

String dateRange(String start, String end) =>
    start == end ? fmtDate(start) : '${fmtDate(start)} – ${fmtDate(end)}';

class IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  const IconText(this.icon, this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ]),
      );
}

class StatusChip extends StatelessWidget {
  final String text;
  final MaterialColor color;
  const StatusChip(this.text, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: color.shade800, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

MaterialColor statusColor(String s) => switch (s) {
      'confirmed' || 'paid' || 'valid' || 'completed' => Colors.green,
      'pending' || 'unpaid' || 'invoiced' || 'expired' => Colors.amber,
      'cancelled' || 'revoked' || 'no_show' => Colors.red,
      _ => Colors.blueGrey,
    };

String pretty(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).replaceAll('_', ' ')}';

void snack(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorRetry({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.black38),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ]),
        ),
      );
}

/// A pull-to-refresh list with loading, error and empty states.
class AsyncList<T> extends StatefulWidget {
  final Future<List<T>> Function() load;
  final Widget Function(BuildContext, T, VoidCallback reload) itemBuilder;
  final String emptyText;
  const AsyncList({super.key, required this.load, required this.itemBuilder, this.emptyText = 'Nothing here yet.'});
  @override
  State<AsyncList<T>> createState() => _AsyncListState<T>();
}

class _AsyncListState<T> extends State<AsyncList<T>> {
  late Future<List<T>> _f;
  @override
  void initState() {
    super.initState();
    _f = widget.load();
  }

  void _reload() => setState(() => _f = widget.load());

  Future<void> _refresh() async {
    _reload();
    try {
      await _f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<T>>(
        future: _f,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return ErrorRetry(message: snap.error.toString(), onRetry: _reload);
          final items = snap.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: items.isEmpty
                ? ListView(children: [
                    Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(child: Text(widget.emptyText, textAlign: TextAlign.center)),
                    ),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (c, i) => widget.itemBuilder(c, items[i], _reload),
                  ),
          );
        },
      );
}

/// One scheduled training date, with its register button.
class SessionTile extends StatelessWidget {
  final Session s;
  final String courseTitle;
  final int? priceKobo;
  final bool showTitle;
  const SessionTile(this.s,
      {super.key, required this.courseTitle, required this.priceKobo, this.showTitle = true});

  @override
  Widget build(BuildContext context) {
    final corporate = context.select<AuthState, bool>((a) => a.isCorporate);
    final full = s.status != 'open' || (s.seatsLeft != null && s.seatsLeft! <= 0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (showTitle) Text(courseTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          if (showTitle && s.category != null) Text(s.category!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          IconText(Icons.event, dateRange(s.startDate, s.endDate)),
          if (s.examDate != null) IconText(Icons.edit_note, 'Exam: ${fmtDate(s.examDate)}'),
          if (s.location != null) IconText(Icons.place_outlined, s.location!),
          const SizedBox(height: 8),
          Row(children: [
            Text(naira(priceKobo), style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            if (!full && s.seatsLeft != null) Text('${s.seatsLeft} seats left', style: const TextStyle(color: Colors.black54)),
          ]),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: full
                  ? null
                  : () => startRegistration(context,
                      sessionId: s.id, courseTitle: courseTitle, startDate: s.startDate, priceKobo: priceKobo),
              child: Text(full ? 'Full' : (corporate ? 'Register staff' : 'Register')),
            ),
          ),
        ]),
      ),
    );
  }
}

class RegistrationCard extends StatelessWidget {
  final Registration r;
  final bool showAttendee;
  final Widget? trailing;
  const RegistrationCard(this.r, {super.key, this.showAttendee = false, this.trailing});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.courseTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            if (showAttendee) IconText(Icons.person_outline, '${r.attendeeName} (${r.attendeeEmail})'),
            IconText(Icons.event, dateRange(r.startDate, r.endDate)),
            if (r.location != null) IconText(Icons.place_outlined, r.location!),
            const SizedBox(height: 8),
            Row(children: [
              StatusChip(pretty(r.status), statusColor(r.status)),
              const SizedBox(width: 8),
              StatusChip(pretty(r.paymentStatus), statusColor(r.paymentStatus)),
              const Spacer(),
              if (trailing != null) trailing!,
            ]),
          ]),
        ),
      );
}
