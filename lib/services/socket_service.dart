import 'package:socket_io_client/socket_io_client.dart' as sio;
import 'app_config.dart';
import 'token_storage.dart';

/// Singleton service managing the Socket.IO connection to the backend.
class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  final _storage = TokenStorage();
  sio.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  /// Connect to the backend Socket.IO server using the stored JWT.
  Future<void> connect() async {
    if (isConnected) return;

    final token = await _storage.getToken();
    if (token == null) {
      throw Exception('SocketService: No JWT token found. User must log in first.');
    }

    // AppConfig.baseUrl is e.g. 'http://10.0.2.2:5000' (no /api suffix)
    final baseUrl = AppConfig.baseUrl;

    _socket = sio.io(
      baseUrl,
      sio.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      // ignore: avoid_print
      print('[SocketService] Connected');
    });
    _socket!.onDisconnect((_) {
      // ignore: avoid_print
      print('[SocketService] Disconnected');
    });
    _socket!.onConnectError((err) {
      // ignore: avoid_print
      print('[SocketService] Connection error: $err');
    });
  }

  /// Disconnect and clean up the socket connection.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// Emit an event with optional [data] payload.
  void emit(String event, [dynamic data]) {
    _socket?.emit(event, data);
  }

  /// Register a listener for [event].
  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  /// Remove a specific event listener or all listeners for [event].
  void off(String event, [dynamic Function(dynamic)? handler]) {
    _socket?.off(event, handler);
  }
}
