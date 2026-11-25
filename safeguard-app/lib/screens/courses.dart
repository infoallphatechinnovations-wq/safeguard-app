import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../auth_state.dart';
import '../models.dart';
import '../widgets.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});
  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final _search = TextEditingController();
  String? _category;
  String _q = '';
  late final Future<List<String>> _cats;

  Api get _api => context.read<AuthState>().api;

  @override
  void initState() {
    super.initState();
    _cats = _api.get('/categories').then((d) => (d['categories'] as List).map((c) => c['name'] as String).toList());
  }

  Future<List<Course>> _load() async {
    final d = await _api.get('/courses', query: {
      if (_category != null) 'category': _category!,
      if (_q.isNotEmpty) 'q': _q,
    });
    return (d['courses'] as List).map((c) => Course.fromJson(c)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search courses',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _q.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _search.clear();
                      _q = '';
                    })),
          ),
          onSubmitted: (v) => setState(() => _q = v.trim()),
        ),
      ),
      SizedBox(
        height: 52,
        child: FutureBuilder<List<String>>(
          future: _cats,
          builder: (context, snap) {
            final cats = snap.data ?? [];
            return ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final c in [null, ...cats])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c ?? 'All'),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      Expanded(
        child: AsyncList<Course>(
          key: ValueKey('$_category|$_q'),
          load: _load,
          emptyText: 'No courses match your search.',
          itemBuilder: (context, c, _) => Card(
            child: ListTile(
              title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${c.category}  •  ${naira(c.priceKobo)}'),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => CourseDetailScreen(slug: c.slug, title: c.title))),
            ),
          ),
        ),
      ),
    ]);
  }
}

class CourseDetailScreen extends StatefulWidget {
  final String slug, title;
  const CourseDetailScreen({super.key, required this.slug, required this.title});
  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late Future<dynamic> _f;

  @override
  void initState() {
    super.initState();
    _f = _fetch();
  }

  Future<dynamic> _fetch() => context.read<AuthState>().api.get('/courses/${widget.slug}');

  Widget _section(BuildContext context, String title, String? body) => (body == null || body.trim().isEmpty)
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(body),
          ]),
        );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.title, overflow: TextOverflow.ellipsis)),
        body: FutureBuilder<dynamic>(
          future: _f,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) {
              return ErrorRetry(message: snap.error.toString(), onRetry: () => setState(() => _f = _fetch()));
            }
            final course = Course.fromJson(snap.data['course']);
            final sessions = (snap.data['upcomingSessions'] as List).map((s) => Session.fromJson(s)).toList();
            return ListView(padding: const EdgeInsets.all(16), children: [
              Text(course.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                Chip(label: Text(course.category)),
                Chip(label: Text(naira(course.priceKobo))),
                if (course.durationDays != null) Chip(label: Text('${course.durationDays} days')),
              ]),
              _section(context, 'About this course', course.description ?? course.summary),
              _section(context, 'Who it is for', course.audience),
              _section(context, 'Entry requirements', course.requirements),
              const SizedBox(height: 24),
              Text('Upcoming training dates', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (sessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No dates are scheduled yet. Contact Safeguard to ask about the next intake.'),
                ),
              for (final s in sessions)
                SessionTile(s, courseTitle: course.title, priceKobo: course.priceKobo, showTitle: false),
            ]);
          },
        ),
      );
}
