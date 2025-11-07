import 'package:financial_tracker/firebase_options.dart';
import 'package:financial_tracker/pages/accounts.dart';
import 'package:financial_tracker/pages/analytics.dart';
import 'package:financial_tracker/pages/auth/sign_in.dart';
import 'package:financial_tracker/pages/auth/verify_email.dart';
import 'package:financial_tracker/pages/budgets.dart';
import 'package:financial_tracker/pages/home.dart';
import 'package:financial_tracker/pages/insights.dart';
import 'package:financial_tracker/pages/profile.dart';
import 'package:financial_tracker/pages/transactions.dart';
import 'package:financial_tracker/services/api_service.dart';
import 'package:financial_tracker/structure.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'pages/splash.dart';

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<ApiService>(() => ApiService());
}
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setupLocator();
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
          path: '/transactions',
          builder: (BuildContext context, GoRouterState state) {
            return TransactionsPage();
          },
        ),
        GoRoute(
          path: '/analytics',
          builder: (BuildContext context, GoRouterState state) {
            return AnalyticsPage();
          },
        ),
        GoRoute(
          path: '/budgets',
          builder: (BuildContext context, GoRouterState state) {
            return BudgetsPage();
          },
        ),
        GoRoute(
          path: '/accounts',
          builder: (BuildContext context, GoRouterState state) {
            return AccountsPage();
          },
        ),
        GoRoute(
          path: '/insights',
          builder: (BuildContext context, GoRouterState state) {
            return InsightsPage();
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