/// Single compile-time base for Dio + websocket derivation.
///
/// Use **exactly** the REST base URL (typically ends with `/api/v1`).
/// Chat connects to `_socketIoOrigin`/ namespace `chat`; Socket.IO handshake
/// uses path `/socket.io` on that same origin — your reverse proxy **must**
/// proxy `/socket.io/` to Nest alongside `/api/` (see `admin-dashboard/nginx.conf`).
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://naacademy.tech/api/v1',
);

/// Origin for Socket.IO (no trailing slash): strips `/api` and `/api/v1` suffixes.
String socketIoOriginFromApiBaseUrl(String apiBaseUrl) {
  String s = apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  for (final suffix in ['/api/v1', '/api']) {
    if (s.toLowerCase().endsWith(suffix)) {
      s = s.substring(0, s.length - suffix.length).replaceAll(RegExp(r'/+$'), '');
      break;
    }
  }
  return s;
}
