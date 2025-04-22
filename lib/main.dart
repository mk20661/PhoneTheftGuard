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
import 'src/settings_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApplicationState()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => SettingsState()),
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
          final from = state.extra;
          final fromSettings = from is Map && from['from'] == 'settings';
          return SignInScreen(
            providers: [EmailAuthProvider()],
            actions: [
              ForgotPasswordAction((context, email) {
                final uri = Uri(
                  path: '/sign-in/forgot-password',
                  queryParameters: {'email': email},
                );
                context.push(uri.toString(), extra: from);
              }),
              AuthStateChangeAction((context, state) {
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please verify your email')),
                  );
                }
                if (fromSettings) {
                  context.go('/setting');
                } else {
                  context.go('/community');
                }
              }),
            ],
            headerBuilder: (context, constraints, _) {
              return Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (fromSettings) {
                      context.go('/setting');
                    } else {
                      context.go('/community');
                    }
                  },
                ),
              );
            },
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
                headerBuilder: (context, constraints, _) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        context.go("/sign-in");
                      },
                    ),
                  );
                },
              );
            },
          ),
          GoRoute(
            path: 'register',
            builder: (context, state) {
              return RegisterScreen(
                providers: [EmailAuthProvider()],
                showAuthActionSwitch: true,
                actions: [
                  AuthStateChangeAction((context, state) {
                    if (state is SignedIn || state is UserCreated) {
                      context.go('/sign-in');
                    }
                  }),
                ],
                headerMaxExtent: 120,
                headerBuilder: (context, constraints, _) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        context.go("/sign-in");
                      },
                    ),
                  );
                },
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
      GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomePage(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => OSMMapPage()),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SizedBox(),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Winky_Rough',
        scaffoldBackgroundColor: const Color(0xFFE6F0FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFB3D1F2),
          foregroundColor: Colors.black,
          centerTitle: true,
          elevation: 1,
        ),
        dialogTheme: DialogTheme(
          backgroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          contentTextStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedLabelStyle: TextStyle(
            fontFamily: 'BubblegumSans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'BubblegumSans',
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        cardTheme: const CardTheme(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4A90E2),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Color(0xFF4A90E2),
            side: const BorderSide(color: Color(0xFF4A90E2)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF4A90E2),
          secondary: const Color(0xFFB3D1F2),
        ),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.themeMode,
      locale: localeProvider.locale,
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
    if (index == 0) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder:
            (context) => FractionallySizedBox(
              heightFactor: 0.95,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: const SearchMapPage(),
              ),
            ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
      context.go(_routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onTap,
        selectedItemColor: const Color(0xFF4A90E2),
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
