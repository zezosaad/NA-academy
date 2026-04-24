import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

class DeepLinkHandler {
  final AppLinks _appLinks = AppLinks();
  final GoRouter router;
  StreamSubscription<Uri>? _uriLinkSub;

  DeepLinkHandler({required this.router});

  void init() {
    _uriLinkSub?.cancel();
    _uriLinkSub = _appLinks.uriLinkStream.listen(_handleDeepLink);
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (!isPasswordResetLink(uri)) return;

    final token = uri.queryParameters['token'];
    if (token != null && token.isNotEmpty) {
      router.go('/auth/reset-password?token=$token');
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

  void dispose() {
    _uriLinkSub?.cancel();
    _uriLinkSub = null;
  }
}
