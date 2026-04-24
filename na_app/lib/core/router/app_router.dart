import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _StubPage(title: 'Splash'),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const _StubPage(title: 'Login'),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const _StubPage(title: 'Register'),
      ),
      GoRoute(
        path: '/today',
        builder: (context, state) => const _StubPage(title: 'Today'),
      ),
    ],
  );
});

class _StubPage extends StatelessWidget {
  final String title;
  const _StubPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
