import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

class DeepLinkHandler {
  final AppLinks _appLinks = AppLinks();
  final GoRouter router;

  DeepLinkHandler({required this.router});

  void init() {
    _appLinks.uriLinkStream.listen(_handleDeepLink);
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    final path = uri.path;
    final token = uri.queryParameters['token'];

    if (path.contains('/auth/reset') || path.contains('/reset')) {
      if (token != null && token.isNotEmpty) {
        router.go('/auth/reset-password?token=$token');
      }
    }
  }

  static String? extractResetToken(Uri uri) {
    return uri.queryParameters['token'];
  }

  static bool isPasswordResetLink(Uri uri) {
    final host = uri.host;
    final path = uri.path;
    final scheme = uri.scheme;
    return (scheme == 'naacademy' && path.contains('/auth/reset')) ||
        (host.contains('naacademy.app') && path.contains('/reset'));
  }
}
