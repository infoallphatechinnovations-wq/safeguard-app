import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_state.dart';
import 'account.dart';
import 'calendar.dart';
import 'corporate/company_screen.dart';
import 'courses.dart';
import 'my_training.dart';
import 'verify.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final tabs = <({String label, IconData icon, Widget page})>[
      (label: 'Courses', icon: Icons.menu_book_outlined, page: const CoursesScreen()),
      (label: 'Calendar', icon: Icons.calendar_month_outlined, page: const CalendarScreen()),
      if (auth.isCorporate) (label: 'Company', icon: Icons.business_outlined, page: const CompanyScreen()),
      if (auth.isLoggedIn && !auth.isCorporate)
        (label: 'My Training', icon: Icons.school_outlined, page: const MyTrainingScreen()),
      (label: 'Verify', icon: Icons.verified_outlined, page: const VerifyScreen()),
      (label: auth.isLoggedIn ? 'Account' : 'Log in', icon: Icons.person_outline, page: const AccountScreen()),
    ];
    final index = _i >= tabs.length ? 0 : _i;
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: index, children: [for (final t in tabs) t.page])),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: [for (final t in tabs) NavigationDestination(icon: Icon(t.icon), label: t.label)],
      ),
    );
  }
}
