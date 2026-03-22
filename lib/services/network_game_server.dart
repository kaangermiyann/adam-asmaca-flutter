import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/network_game_room.dart';

class NetworkGameServer {
  HttpServer? _server;
  final List<WebSocket> _clients = [];
  final Map<String, WebSocket> _playerSockets = {};

  NetworkGameRoom? _room;
  final StreamController<NetworkGameRoom> _roomController = StreamController.broadcast();

  String? _hostIp;
  int _port = 8080;

  bool get isRunning => _server != null;
  String? get hostIp => _hostIp;
  int get port => _port;
  String get connectionAddress => '$_hostIp:$_port';
  Stream<NetworkGameRoom> get roomStream => _roomController.stream;
  NetworkGameRoom? get room => _room;

  Future<String> start({
    required String hostId,
    required String hostName,
    int port = 8080,
  }) async {
    _port = port;

    // Lokal IP adresini bul
    _hostIp = await _getLocalIpAddress();

    _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);

    // Odayı oluştur
    _room = NetworkGameRoom(
      id: _generateRoomId(),
      hostId: hostId,
      hostName: hostName,
      players: [
        NetworkPlayer(id: hostId, name: hostName, isReady: true, isHost: true),
      ],
      state: NetworkGameState.waiting,
      scores: {hostId: 0},
    );

    _roomController.add(_room!);

    // Bağlantıları dinle
    _server!.listen(_handleConnection);

    return connectionAddress;
  }

  Future<String> _getLocalIpAddress() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );

    for (var interface in interfaces) {
      for (var addr in interface.addresses) {
        if (!addr.isLoopback && addr.address.startsWith('192.168')) {
          return addr.address;
        }
      }
    }

    // Fallback: Herhangi bir non-loopback adres
    for (var interface in interfaces) {
      for (var addr in interface.addresses) {
        if (!addr.isLoopback) {
          return addr.address;
        }
      }
    }

    return '127.0.0.1';
  }

  String _generateRoomId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[DateTime.now().microsecondsSinceEpoch % chars.length]).join();
  }

  void _handleConnection(HttpRequest request) async {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = await WebSocketTransformer.upgrade(request);
      _clients.add(socket);

      socket.listen(
        (data) => _handleMessage(socket, data),
        onDone: () => _handleDisconnect(socket),
        onError: (error) => _handleDisconnect(socket),
      );
    }
  }

  // Host için doğrudan komut işleme metodları
  void hostToggleReady(String playerId) {
    _handleReady({'playerId': playerId});
  }

  void hostStartGame(String wordChooserId) {
    _handleStartGame({'wordChooserId': wordChooserId});
  }

  void hostSetWord(String word) {
    _handleSetWord({'word': word});
  }

  void hostGuessLetter(String letter, String playerId) {
    _handleGuessLetter({'letter': letter, 'playerId': playerId});
  }

  void hostNewRound(String newWordChooserId) {
    _handleNewRound({'newWordChooserId': newWordChooserId});
  }

  void _handleMessage(WebSocket socket, dynamic data) {
    try {
      final message = jsonDecode(data as String) as Map<String, dynamic>;
      final type = message['type'] as String;

      switch (type) {
        case 'join':
          _handleJoin(socket, message);
          break;
        case 'ready':
          _handleReady(message);
          break;
        case 'start_game':
          _handleStartGame(message);
          break;
        case 'set_word':
          _handleSetWord(message);
          break;
        case 'guess_letter':
          _handleGuessLetter(message);
          break;
        case 'new_round':
          _handleNewRound(message);
          break;
        case 'leave':
          _handleLeave(socket, message);
          break;
      }
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  void _handleJoin(WebSocket socket, Map<String, dynamic> message) {
    if (_room == null) return;

    final playerId = message['playerId'] as String;
    final playerName = message['playerName'] as String;

    // Oyuncu zaten varsa güncelle
    if (_room!.players.any((p) => p.id == playerId)) {
      _playerSockets[playerId] = socket;
      _sendToSocket(socket, {
        'type': 'room_update',
        'room': _room!.toMap(),
      });
      return;
    }

    // Oyun başlamışsa katılmaya izin verme
    if (_room!.state != NetworkGameState.waiting) {
      _sendToSocket(socket, {
        'type': 'error',
        'message': 'Oyun zaten başlamış',
      });
      return;
    }

    // Yeni oyuncu ekle
    final newPlayer = NetworkPlayer(
      id: playerId,
      name: playerName,
      isReady: false,
      isHost: false,
    );

    final updatedPlayers = [..._room!.players, newPlayer];
    final updatedScores = Map<String, int>.from(_room!.scores);
    updatedScores[playerId] = 0;

    _room = _room!.copyWith(
      players: updatedPlayers,
      scores: updatedScores,
    );

    _playerSockets[playerId] = socket;
    _broadcastRoomUpdate();
  }

  void _handleReady(Map<String, dynamic> message) {
    if (_room == null) return;

    final playerId = message['playerId'] as String;

    final updatedPlayers = _room!.players.map((p) {
      if (p.id == playerId) {
        return p.copyWith(isReady: !p.isReady);
      }
      return p;
    }).toList();

    _room = _room!.copyWith(players: updatedPlayers);
    _broadcastRoomUpdate();
  }

  void _handleStartGame(Map<String, dynamic> message) {
    if (_room == null) return;

    final wordChooserId = message['wordChooserId'] as String;

    _room = _room!.copyWith(
      state: NetworkGameState.choosingWord,
      wordChooser: wordChooserId,
      guessedLetters: [],
      wrongGuesses: 0,
      currentWord: null,
    );

    _broadcastRoomUpdate();
  }

  void _handleSetWord(Map<String, dynamic> message) {
    if (_room == null) return;

    final word = (message['word'] as String).toUpperCase();

    _room = _room!.copyWith(
      state: NetworkGameState.playing,
      currentWord: word,
      guessedLetters: [],
      wrongGuesses: 0,
      gameStartTime: DateTime.now(),
    );

    _broadcastRoomUpdate();
  }

  void _handleGuessLetter(Map<String, dynamic> message) {
    if (_room == null) return;

    final letter = (message['letter'] as String).toUpperCase();
    final playerId = message['playerId'] as String;

    if (_room!.guessedLetters.contains(letter)) {
      _sendToPlayer(playerId, {
        'type': 'guess_result',
        'alreadyGuessed': true,
      });
      return;
    }

    final updatedGuessedLetters = [..._room!.guessedLetters, letter];
    final isCorrect = _room!.currentWord?.contains(letter) ?? false;

    int updatedWrongGuesses = _room!.wrongGuesses;
    if (!isCorrect) {
      updatedWrongGuesses++;
    }

    _room = _room!.copyWith(
      guessedLetters: updatedGuessedLetters,
      wrongGuesses: updatedWrongGuesses,
    );

    // Oyun bitti mi kontrol et
    final isWordGuessed = _room!.isWordGuessed();
    final isGameOver = _room!.isGameOver();

    if (isGameOver) {
      final updatedScores = Map<String, int>.from(_room!.scores);

      if (isWordGuessed) {
        // Tahmin edenler kazandı
        for (final player in _room!.players) {
          if (player.id != _room!.wordChooser) {
            updatedScores[player.id] = (updatedScores[player.id] ?? 0) + 10;
          }
        }
      } else {
        // Kelime seçen kazandı
        if (_room!.wordChooser != null) {
          updatedScores[_room!.wordChooser!] = (updatedScores[_room!.wordChooser!] ?? 0) + 15;
        }
      }

      _room = _room!.copyWith(
        state: NetworkGameState.finished,
        scores: updatedScores,
      );
    }

    _broadcastRoomUpdate();

    // Tahmin sonucunu gönder
    _broadcast({
      'type': 'guess_result',
      'letter': letter,
      'isCorrect': isCorrect,
      'isGameOver': isGameOver,
      'isWordGuessed': isWordGuessed,
    });
  }

  void _handleNewRound(Map<String, dynamic> message) {
    if (_room == null) return;

    final newWordChooserId = message['newWordChooserId'] as String;

    // Tüm oyuncuları hazır değil yap
    final updatedPlayers = _room!.players.map((p) => p.copyWith(isReady: p.isHost)).toList();

    _room = _room!.copyWith(
      state: NetworkGameState.choosingWord,
      wordChooser: newWordChooserId,
      currentWord: null,
      guessedLetters: [],
      wrongGuesses: 0,
      gameStartTime: null,
      players: updatedPlayers,
    );

    _broadcastRoomUpdate();
  }

  void _handleLeave(WebSocket socket, Map<String, dynamic> message) {
    final playerId = message['playerId'] as String;
    _removePlayer(playerId);
  }

  void _handleDisconnect(WebSocket socket) {
    _clients.remove(socket);

    // Hangi oyuncunun bağlantısı koptu bul
    String? disconnectedPlayerId;
    _playerSockets.forEach((id, s) {
      if (s == socket) {
        disconnectedPlayerId = id;
      }
    });

    if (disconnectedPlayerId != null) {
      _removePlayer(disconnectedPlayerId!);
    }
  }

  void _removePlayer(String playerId) {
    if (_room == null) return;

    _playerSockets.remove(playerId);

    final updatedPlayers = _room!.players.where((p) => p.id != playerId).toList();

    if (updatedPlayers.isEmpty) {
      // Odada kimse kalmadı
      stop();
      return;
    }

    // Ev sahibi ayrıldıysa yeni ev sahibi ata
    String newHostId = _room!.hostId;
    String newHostName = _room!.hostName;

    if (_room!.hostId == playerId) {
      final newHost = updatedPlayers.first;
      newHostId = newHost.id;
      newHostName = newHost.name;

      final playersWithNewHost = updatedPlayers.map((p) {
        if (p.id == newHostId) {
          return p.copyWith(isHost: true, isReady: true);
        }
        return p;
      }).toList();

      _room = _room!.copyWith(
        hostId: newHostId,
        hostName: newHostName,
        players: playersWithNewHost,
      );
    } else {
      _room = _room!.copyWith(players: updatedPlayers);
    }

    _broadcastRoomUpdate();
  }

  void _broadcastRoomUpdate() {
    if (_room == null) return;

    _roomController.add(_room!);

    _broadcast({
      'type': 'room_update',
      'room': _room!.toMap(),
    });
  }

  void _broadcast(Map<String, dynamic> message) {
    final data = jsonEncode(message);
    for (var client in _clients) {
      try {
        client.add(data);
      } catch (e) {
        print('Error broadcasting to client: $e');
      }
    }
  }

  void _sendToPlayer(String playerId, Map<String, dynamic> message) {
    final socket = _playerSockets[playerId];
    if (socket != null) {
      _sendToSocket(socket, message);
    }
  }

  void _sendToSocket(WebSocket socket, Map<String, dynamic> message) {
    try {
      socket.add(jsonEncode(message));
    } catch (e) {
      print('Error sending to socket: $e');
    }
  }

  void stop() {
    for (var client in _clients) {
      try {
        client.close();
      } catch (e) {
        print('Error closing client: $e');
      }
    }
    _clients.clear();
    _playerSockets.clear();
    _server?.close();
    _server = null;
    _room = null;
    _roomController.close();
  }

  void dispose() {
    stop();
  }
}
