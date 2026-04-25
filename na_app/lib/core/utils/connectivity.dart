import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>(
  (ref) => ConnectivityNotifier(),
);

enum ConnectivityState { online, offline, unknown }

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  ConnectivityNotifier() : super(ConnectivityState.unknown);

  void markOffline() {
    if (state != ConnectivityState.offline) {
      state = ConnectivityState.offline;
    }
  }

  void markOnline() {
    if (state != ConnectivityState.online) {
      state = ConnectivityState.online;
    }
  }

  void reportError(Object error) {
    final msg = error.toString();
    if (msg.contains('SocketException') ||
        msg.contains('Connection refused') ||
        msg.contains('Connection timed out') ||
        msg.contains('No address associated with hostname') ||
        msg.contains('connectionError') ||
        msg.contains('NETWORK_ERROR')) {
      markOffline();
    }
  }
}
