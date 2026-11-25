import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api.dart';
import '../../auth_state.dart';
import '../../widgets.dart';

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});
  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  final _course = TextEditingController(), _count = TextEditingController();
  final _dates = TextEditingController(), _message = TextEditingController();
  bool _busy = false;

  Future<void> _send() async {
    if (_course.text.trim().isEmpty) {
      snack(context, 'Tell us which course you need.');
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<AuthState>().api.post('/quotes', {
        'courseText': _course.text.trim(),
        'headcount': int.tryParse(_count.text.trim()),
        'preferredDates': _dates.text.trim(),
        'message': _message.text.trim(),
      });
      if (!mounted) return;
      snack(context, 'Request sent. Safeguard will contact you with a quote.');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Request a quote')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Tell us about the training your company needs and we will send you a quote.'),
          const SizedBox(height: 16),
          TextField(controller: _course, decoration: const InputDecoration(labelText: 'Course or topic')),
          const SizedBox(height: 14),
          TextField(controller: _count, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Number of staff')),
          const SizedBox(height: 14),
          TextField(controller: _dates, decoration: const InputDecoration(labelText: 'Preferred dates or period')),
          const SizedBox(height: 14),
          TextField(controller: _message, maxLines: 4, decoration: const InputDecoration(labelText: 'Anything else we should know')),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _send,
            child: _busy
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Send request'),
          ),
        ]),
      );
}
