import 'dart:convert';
import 'dart:developer' as developer;

/// Verbose websocket / chat diagnostics.
///
/// - Default: **on** (easy diagnosis of remote-server issues).
/// - Silence: `--dart-define=NA_CHAT_TRACE=false`
class ChatTrace {
  ChatTrace._();

  static const bool enabled = bool.fromEnvironment(
    'NA_CHAT_TRACE',
    defaultValue: true,
  );

  static void log(String phase, [Map<String, Object?> detail = const {}]) {
    if (!enabled) return;
    final payload =
        detail.isEmpty ? phase : '$phase ${_encodeDetail(detail)}';
    developer.log(payload, name: 'NA.Chat');
  }

  static String _encodeDetail(Map<String, Object?> detail) {
    try {
      return jsonEncode(
        detail.map(
          (k, v) => MapEntry(k, _stringifyValue(v)),
        ),
      );
    } catch (_) {
      return '${detail.keys.join(",")}(non-json)';
    }
  }

  static Object? _stringifyValue(Object? v) {
    if (v == null) return null;
    if (v is String || v is num || v is bool) return v;
    final s = v.toString();
    const max = 800;
    return s.length <= max ? s : '${s.substring(0, max)}…(${s.length} chars)';
  }
}
