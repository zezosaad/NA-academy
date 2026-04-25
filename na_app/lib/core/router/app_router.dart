import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:na_app/core/widgets/app_shell.dart';
import 'package:na_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:na_app/features/auth/presentation/pages/splash_page.dart';
import 'package:na_app/features/auth/presentation/pages/login_page.dart';
import 'package:na_app/features/auth/presentation/pages/register_page.dart';
import 'package:na_app/features/subjects/presentation/pages/subjects_page.dart';
import 'package:na_app/features/subjects/presentation/pages/subject_detail_page.dart';
import 'package:na_app/features/subjects/presentation/pages/enter_subject_code_page.dart';
import 'package:na_app/features/subjects/presentation/pages/code_unlocking_page.dart';
import 'package:na_app/features/subjects/presentation/pages/code_expired_page.dart';
import 'package:na_app/features/subjects/presentation/pages/code_used_page.dart';
import 'package:na_app/features/exams/presentation/pages/exams_page.dart';
import 'package:na_app/features/exams/presentation/pages/enter_exam_code_page.dart';
import 'package:na_app/features/exams/presentation/pages/take_exam_page.dart';
import 'package:na_app/features/exams/presentation/pages/exam_result_page.dart';
import 'package:na_app/features/exams/domain/exam_models.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isAuthenticated = authState.value != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (isSplash) return null;

      if (!isAuthenticated && !isAuthRoute && !isOnboarding) {
        return '/splash';
      }

      if (isAuthenticated && (isAuthRoute || isOnboarding)) {
        return '/today';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const _PlaceholderPage(title: 'Onboarding'),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const _PlaceholderPage(title: 'Forgot Password'),
      ),
      GoRoute(
        path: '/auth/reset-password',
        builder: (context, state) => const _PlaceholderPage(title: 'Reset Password'),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) =>
                    const _PlaceholderPage(title: 'Today'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/subjects',
                builder: (context, state) => const SubjectsPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final subjectId = state.pathParameters['id']!;
                      return SubjectDetailPage(subjectId: subjectId);
                    },
                    routes: [
                      GoRoute(
                        path: 'lessons/:lessonId',
                        builder: (context, state) {
                          final lessonId = state.pathParameters['lessonId']!;
                          return _PlaceholderPage(title: 'Lesson $lessonId');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/exams',
                builder: (context, state) => const ExamsPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final examId = state.pathParameters['id']!;
                      return _PlaceholderPage(title: 'Exam Detail $examId');
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) =>
                    const _PlaceholderPage(title: 'Chat'),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final conversationId = state.pathParameters['id']!;
                      return _PlaceholderPage(
                          title: 'Chat $conversationId');
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) =>
                    const _PlaceholderPage(title: 'Profile'),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) =>
                        const _PlaceholderPage(title: 'Settings'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/subjects/enter-code',
        builder: (context, state) => const EnterSubjectCodePage(),
      ),
      GoRoute(
        path: '/subjects/:id/unlocking',
        builder: (context, state) {
          final subjectId = state.pathParameters['id']!;
          return CodeUnlockingPage(subjectId: subjectId);
        },
      ),
      GoRoute(
        path: '/subjects/code-expired',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CodeExpiredPage(
            code: extra['code'] as String? ?? '',
            expiredAt: extra['expiredAt'] as DateTime?,
          );
        },
      ),
      GoRoute(
        path: '/subjects/code-used',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CodeUsedPage(
            code: extra['code'] as String? ?? '',
            consumedAt: extra['consumedAt'] as DateTime?,
          );
        },
      ),
      GoRoute(
        path: '/exams/:id/enter-code',
        builder: (context, state) {
          final examId = state.pathParameters['id']!;
          return EnterExamCodePage(examId: examId);
        },
      ),
      GoRoute(
        path: '/exams/:id/take',
        builder: (context, state) {
          final examId = state.pathParameters['id']!;
          return TakeExamPage(examId: examId);
        },
      ),
      GoRoute(
        path: '/exams/:id/result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final score = extra['score'] as ExamScore? ?? ExamScore(sessionId: '', score: 0);
          final timedOut = extra['timedOut'] as bool? ?? false;
          return ExamResultPage(score: score, timedOut: timedOut);
        },
      ),
    ],
  );
});

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
