import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

import 'firebase_options.dart';
import 'app_state.dart';
import 'community.dart';
import 'history.dart';
import 'setting_page.dart';
import 'search_page.dart';
import 'osm_map_page.dart';
import 'src/theme_provider.dart';
import 'src/locale_provider.dart';
import 'about_page.dart';
import 'privacy_policy_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApplicationState()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ApplicationState()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final GoRouter _router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) {
          return SignInScreen(
            providers: [EmailAuthProvider()],
            actions: [
              ForgotPasswordAction(((context, email) {
                final uri = Uri(
                  path: '/sign-in/forgot-password',
                  queryParameters: <String, String?>{'email': email},
                );
                context.push(uri.toString());
              })),
              AuthStateChangeAction(((context, state) {
                final user = switch (state) {
                  SignedIn s => s.user,
                  UserCreated s => s.credential.user,
                  _ => null,
                };
                if (user == null) return;
                if (state is UserCreated) {
                  user.updateDisplayName(user.email!.split('@')[0]);
                }
                if (!user.emailVerified) {
                  user.sendEmailVerification();
                  const snackBar = SnackBar(
                    content: Text('Please verify your email'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
                context.go('/community');
              })),
            ],
          );
        },
        routes: [
          GoRoute(
            path: 'forgot-password',
            builder: (context, state) {
              final arguments = state.uri.queryParameters;
              return ForgotPasswordScreen(
                email: arguments['email'],
                headerMaxExtent: 200,
              );
            },
          ),
        ],
      ),

      GoRoute(
        path: '/profile',
        builder: (context, state) {
          final from = (state.extra as Map?)?['from'] ?? 'community';

          return Scaffold(
            appBar: AppBar(
              title: const Text('Profile'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (from == 'settings') {
                    context.go('/setting');
                  } else {
                    context.go('/community');
                  }
                },
              ),
            ),
            body: ProfileScreen(
              providers: const [],
              actions: [
                SignedOutAction((context) {
                  context.go('/community');
                }),
              ],
            ),
          );
        },
      ),
      GoRoute(
        path: '/about', 
        builder: (context, state) => const AboutPage()),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),

      ShellRoute(
        builder: (context, state, child) => HomePage(child: child),
        routes: [
          GoRoute(
            path: '/home', 
            builder: (context, state) => OSMMapPage()),
          GoRoute(
            path: '/search',
            builder: (context, state) => SearchMapPage(),
          ),
          GoRoute(
            path: '/history', 
            builder: (context, state) => HistoryPage()),
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
    return Builder(
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final localeProvider = Provider.of<LocaleProvider>(context);

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.themeMode,
          locale: localeProvider.locale,
          routerConfig: _router,
        );
      },
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
