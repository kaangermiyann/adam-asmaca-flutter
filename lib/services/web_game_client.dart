import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/network_game_room.dart';

class WebGameClient {
  WebSocketChannel? _channel;
  final StreamController<NetworkGameRoom> _roomController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();

  bool _isConnected = false;
  String? _playerId;
  String? _playerName;

  bool get isConnected => _isConnected;
  Stream<NetworkGameRoom> get roomStream => _roomController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  Future<bool> connect({
    required String serverAddress,
    required String playerId,
    required String playerName,
  }) async {
    try {
      _playerId = playerId;
      _playerName = playerName;

      // ws:// prefix ekle
      String wsUrl = serverAddress;
      if (!wsUrl.startsWith('ws://') && !wsUrl.startsWith('wss://')) {
        wsUrl = 'ws://$serverAddress';
      }

      // /ws path ekle
      if (!wsUrl.endsWith('/ws')) {
        wsUrl = '$wsUrl/ws';
      }

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Bağlantıyı bekle
      await _channel!.ready;

      _isConnected = true;

      _channel!.stream.listen(
        _handleMessage,
        onDone: _handleDisconnect,
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnect();
        },
      );

      return true;
    } catch (e) {
      print('Connection error: $e');
      _isConnected = false;
      return false;
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data as String) as Map<String, dynamic>;
      final type = message['type'] as String;

      if (type == 'room_update') {
        final roomData = message['room'] as Map<String, dynamic>;
        final room = NetworkGameRoom.fromMap(roomData);
        _roomController.add(room);
      }

      _messageController.add(message);
    } catch (e) {
      print('Error parsing message: $e');
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _messageController.add({'type': 'disconnected'});
  }

  void send(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(jsonEncode(message));
      } catch (e) {
        print('Error sending message: $e');
      }
    }
  }

  void createRoom() {
    send({
      'type': 'create_room',
      'playerId': _playerId,
      'playerName': _playerName,
    });
  }

  void joinRoom() {
    send({
      'type': 'join',
      'playerId': _playerId,
      'playerName': _playerName,
    });
  }

  void toggleReady() {
    send({
      'type': 'ready',
      'playerId': _playerId,
    });
  }

  void startGame(String wordChooserId) {
    send({
      'type': 'start_game',
      'wordChooserId': wordChooserId,
    });
  }

  void setWord(String word) {
    send({
      'type': 'set_word',
      'word': word,
    });
  }

  void guessLetter(String letter) {
    send({
      'type': 'guess_letter',
      'letter': letter,
      'playerId': _playerId,
    });
  }

  void newRound(String newWordChooserId) {
    send({
      'type': 'new_round',
      'newWordChooserId': newWordChooserId,
    });
  }

  void leave() {
    send({
      'type': 'leave',
      'playerId': _playerId,
    });
    disconnect();
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _roomController.close();
    _messageController.close();
  }
}
