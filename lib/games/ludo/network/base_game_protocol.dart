import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/ludo_models.dart';

abstract class BaseGameProtocol {
  Stream<LudoGameSnapshot> get stateUpdates;

  void sendRollDice();

  void sendMoveHorse(String horseId);

  void dispose();
}

class WebSocketLudoProtocol implements BaseGameProtocol {
  WebSocketLudoProtocol(Uri uri)
      : _channel = WebSocketChannel.connect(uri) {
    _subscription = _channel.stream.listen((message) {
      final decoded = jsonDecode(message as String) as Map<String, dynamic>;
      if (decoded['type'] != 'gameState') return;
      _stateController.add(
        LudoGameSnapshot.fromJson(decoded['gameState'] as Map<String, dynamic>),
      );
    });
  }

  final WebSocketChannel _channel;
  final _stateController = StreamController<LudoGameSnapshot>.broadcast();
  late final StreamSubscription<dynamic> _subscription;

  @override
  Stream<LudoGameSnapshot> get stateUpdates => _stateController.stream;

  @override
  void sendRollDice() {
    _channel.sink.add(jsonEncode({'type': 'rollDice'}));
  }

  @override
  void sendMoveHorse(String horseId) {
    _channel.sink.add(jsonEncode({'type': 'moveHorse', 'horseId': horseId}));
  }

  @override
  void dispose() {
    _subscription.cancel();
    _stateController.close();
    _channel.sink.close();
  }
}
