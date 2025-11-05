import 'package:financial_tracker/firebase_options.dart';
import 'package:financial_tracker/pages/auth/sign_in.dart';
import 'package:financial_tracker/pages/auth/verify_email.dart';
import 'package:financial_tracker/pages/home.dart';
import 'package:financial_tracker/pages/profile.dart';
import 'package:financial_tracker/structure.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pages/splash.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return MaterialApp.router(
          title: 'Finance Tracker',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green, brightness: Brightness.dark),
            useMaterial3: true,
          ),
          routerConfig: _router,
        );
      },
    );
  }
}

const List<String> publicRoutes = [
  '/',
  '/auth/sign-in',
];

const String verifyEmailRoute = '/auth/verify-email';

final GoRouter _router = GoRouter(
  initialLocation: '/',
  redirect: (BuildContext context, GoRouterState state) {
    final User? user = FirebaseAuth.instance.currentUser;
    final bool loggedIn = user != null;
    final bool emailVerified = user?.emailVerified ?? false;

    final String goingTo = state.fullPath ?? '/';

    if (loggedIn) {
      if (!emailVerified && goingTo != verifyEmailRoute) {
        return verifyEmailRoute;
      }

      return null;
    } else {
      if (!publicRoutes.contains(goingTo)) {
        return '/auth/sign-in';
      }

      return null;
    }
  },
  routes: <RouteBase>[
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        if(state.fullPath == '/' || state.fullPath!.startsWith('/auth')) {
          return child;
        }
        return NavigatorScafold(child: child);
      },

      routes: [
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) {
            return SplashPage();
          },
        ),
        GoRoute(
          path: '/auth/sign-in',
          builder: (BuildContext context, GoRouterState state) {
            return SignInPage();
          },
        ),
        GoRoute(
          path: '/auth/verify-email',
          builder: (BuildContext context, GoRouterState state) {
            return VerifyEmailPage();
          },
        ),
        GoRoute(
          path: '/home',
          builder: (BuildContext context, GoRouterState state) {
            return HomePage();
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (BuildContext context, GoRouterState state) {
            return ProfilePage();
          },
        ),
      ],
    ),
  ],
);