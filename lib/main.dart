import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'app_state.dart';
import 'login_page.dart';
import 'community.dart';
import 'history.dart';
import 'setting_page.dart';
import 'search_page.dart';
import 'osm_map_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(create: (_) => ApplicationState(), child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final GoRouter _router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/sign-in', builder: (context, state) => const LoginPage()),

      ShellRoute(
        builder: (context, state, child) => HomePage(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => OSMMapPage()),
          GoRoute(
            path: '/search',
            builder: (context, state) => SearchMapPage(),
          ),
          GoRoute(path: '/history', builder: (context, state) => HistoryPage()),
          GoRoute(
            path: '/community',
            builder: (context, state) => CommunityPage(),
          ),
          GoRoute(
            path: '/setting',
            builder: (context, state) => SettingsPage(),
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}

class HomePage extends StatefulWidget {
  final Widget child;
  const HomePage({super.key, required this.child});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2;

  final List<String> _routes = [
    '/search',
    '/history',
    '/home',
    '/community',
    '/setting',
  ];

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onTap,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        iconSize: 28,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Community"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Setting"),
        ],
      ),
    );
  }
}
