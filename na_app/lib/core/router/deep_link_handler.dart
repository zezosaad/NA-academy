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
    return _isCustomSchemeReset(scheme, host, path) ||
        (_isUniversalResetHost(host) && path.contains('/reset'));
  }

  /// `naacademy://auth/reset?...` parses as host `auth`, path `/reset`.
  static bool _isCustomSchemeReset(String scheme, String host, String path) {
    if (scheme != 'naacademy') return false;
    if (host == 'auth' && path.startsWith('/reset')) return true;
    return path.contains('/auth/reset');
  }

  /// HTTPS universal-link hosts (production + legacy).
  static bool _isUniversalResetHost(String host) {
    if (host == 'naacademy.tech' || host == 'www.naacademy.tech') return true;
    if (host.endsWith('.naacademy.tech')) return true;
    if (host.contains('naacademy.app')) return true;
    return false;
  }

  void dispose() {
    _uriLinkSub?.cancel();
    _uriLinkSub = null;
  }
}
