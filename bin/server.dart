import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Basit WebSocket oyun sunucusu
// Çalıştırmak için: dart run bin/server.dart

class GameRoom {
  String id;
  String hostId;
  String hostName;
  List<Map<String, dynamic>> players = [];
  String state = 'waiting';
  String? currentWord;
  String? wordChooser;
  List<String> guessedLetters = [];
  int wrongGuesses = 0;
  int maxWrongGuesses = 6;
  Map<String, int> scores = {};
  int currentRound = 1;
  int totalRounds = 4;

  GameRoom({
    required this.id,
    required this.hostId,
    required this.hostName,
  }) {
    players.add({
      'id': hostId,
      'name': hostName,
      'isReady': true,
      'isHost': true,
    });
    scores[hostId] = 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hostId': hostId,
      'hostName': hostName,
      'players': players,
      'state': state,
      'currentWord': currentWord,
      'wordChooser': wordChooser,
      'guessedLetters': guessedLetters,
      'wrongGuesses': wrongGuesses,
      'maxWrongGuesses': maxWrongGuesses,
      'scores': scores,
      'currentRound': currentRound,
      'totalRounds': totalRounds,
      'gameDurationSeconds': 120,
    };
  }

  bool isWordGuessed() {
    if (currentWord == null) return false;
    return currentWord!.toUpperCase().split('').every(
          (letter) => guessedLetters.contains(letter.toUpperCase()),
        );
  }

  bool isGameOver() {
    return wrongGuesses >= maxWrongGuesses || isWordGuessed();
  }

  String getMaskedWord() {
    if (currentWord == null) return '';
    return currentWord!.split('').map((letter) {
      if (guessedLetters.contains(letter.toUpperCase())) {
        return letter.toUpperCase();
      }
      return '_';
    }).join(' ');
  }
}

class GameServer {
  HttpServer? _server;
  final List<WebSocket> _clients = [];
  final Map<String, WebSocket> _playerSockets = {};
  GameRoom? _room;

  Future<void> start({int port = 8080}) async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);

    // Lokal IP adresini bul
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );

    String localIp = '127.0.0.1';
    for (var interface in interfaces) {
      for (var addr in interface.addresses) {
        if (!addr.isLoopback) {
          localIp = addr.address;
          break;
        }
      }
    }

    print('');
    print('╔════════════════════════════════════════════════════════════╗');
    print('║           ADAM ASMACA - OYUN SUNUCUSU                      ║');
    print('╠════════════════════════════════════════════════════════════╣');
    print('║  Sunucu adresi: $localIp:$port');
    print('║  Baslangic: ${DateTime.now()}');
    print('╚════════════════════════════════════════════════════════════╝');
    print('');
    print('📡 Baglantilar bekleniyor...');
    print('');

    _server!.listen(_handleConnection);
  }

  void _handleConnection(HttpRequest request) async {
    if (request.uri.path == '/ws' && WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = await WebSocketTransformer.upgrade(request);
      _clients.add(socket);
      _log('🔌', 'YENI BAGLANTI: ${request.connectionInfo?.remoteAddress.address}');

      socket.listen(
        (data) => _handleMessage(socket, data),
        onDone: () => _handleDisconnect(socket),
        onError: (error) => _handleDisconnect(socket),
      );
    } else {
      // CORS preflight
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      request.response.headers.add('Access-Control-Allow-Headers', '*');
      request.response.statusCode = HttpStatus.ok;
      request.response.close();
    }
  }

  String _timestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  void _log(String emoji, String message) {
    print('[${_timestamp()}] $emoji $message');
  }

  void _handleMessage(WebSocket socket, dynamic data) {
    try {
      final message = jsonDecode(data as String) as Map<String, dynamic>;
      final type = message['type'] as String;

      switch (type) {
        case 'create_room':
          _handleCreateRoom(socket, message);
          break;
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
      print('[!] Hata: $e');
    }
  }

  void _handleCreateRoom(WebSocket socket, Map<String, dynamic> message) {
    final hostId = message['playerId'] as String;
    final hostName = message['playerName'] as String;

    _room = GameRoom(
      id: _generateRoomId(),
      hostId: hostId,
      hostName: hostName,
    );

    _playerSockets[hostId] = socket;
    _log('🏠', 'ODA OLUSTURULDU');
    _log('   ', '  Oda ID: ${_room!.id}');
    _log('   ', '  Host: $hostName');
    _broadcastRoomUpdate();
  }

  void _handleJoin(WebSocket socket, Map<String, dynamic> message) {
    if (_room == null) {
      _sendToSocket(socket, {'type': 'error', 'message': 'Oda bulunamadi'});
      return;
    }

    final playerId = message['playerId'] as String;
    final playerName = message['playerName'] as String;

    // Zaten varsa güncelle
    if (_room!.players.any((p) => p['id'] == playerId)) {
      _playerSockets[playerId] = socket;
      _sendToSocket(socket, {'type': 'room_update', 'room': _room!.toMap()});
      return;
    }

    if (_room!.state != 'waiting') {
      _sendToSocket(socket, {'type': 'error', 'message': 'Oyun zaten baslamis'});
      return;
    }

    _room!.players.add({
      'id': playerId,
      'name': playerName,
      'isReady': false,
      'isHost': false,
    });
    _room!.scores[playerId] = 0;
    _playerSockets[playerId] = socket;

    _log('👤', 'OYUNCU KATILDI: $playerName');
    _log('   ', '  Toplam oyuncu: ${_room!.players.length}');
    _broadcastRoomUpdate();
  }

  void _handleReady(Map<String, dynamic> message) {
    if (_room == null) return;

    final playerId = message['playerId'] as String;

    for (var player in _room!.players) {
      if (player['id'] == playerId) {
        player['isReady'] = !(player['isReady'] as bool);
        break;
      }
    }

    _broadcastRoomUpdate();
  }

  void _handleStartGame(Map<String, dynamic> message) {
    if (_room == null) return;

    final wordChooserId = message['wordChooserId'] as String;

    _room!.state = 'choosingWord';
    _room!.wordChooser = wordChooserId;
    _room!.guessedLetters = [];
    _room!.wrongGuesses = 0;
    _room!.currentWord = null;

    final chooserName = _room!.players.firstWhere((p) => p['id'] == wordChooserId)['name'];
    _log('🎮', '═══════════════════════════════════════');
    _log('🎮', 'OYUN BASLADI!');
    _log('🎮', '  Kelime secen: $chooserName');
    _log('🎮', '═══════════════════════════════════════');
    _broadcastRoomUpdate();
  }

  void _handleSetWord(Map<String, dynamic> message) {
    if (_room == null) return;

    final word = (message['word'] as String).toUpperCase();

    _room!.state = 'playing';
    _room!.currentWord = word;
    _room!.guessedLetters = [];
    _room!.wrongGuesses = 0;

    final chooserName = _room!.players.firstWhere((p) => p['id'] == _room!.wordChooser)['name'];
    _log('📝', '───────────────────────────────────────');
    _log('📝', 'KELIME SECILDI!');
    _log('📝', '  Kelime: *** $word ***');
    _log('📝', '  Secen: $chooserName');
    _log('📝', '  Harf sayisi: ${word.length}');
    _log('📝', '───────────────────────────────────────');
    _broadcastRoomUpdate();
  }

  void _handleGuessLetter(Map<String, dynamic> message) {
    if (_room == null) return;

    final letter = (message['letter'] as String).toUpperCase();
    final playerId = message['playerId'] as String;

    if (_room!.guessedLetters.contains(letter)) {
      _sendToPlayer(playerId, {'type': 'guess_result', 'alreadyGuessed': true});
      return;
    }

    _room!.guessedLetters.add(letter);
    final isCorrect = _room!.currentWord?.toUpperCase().contains(letter) ?? false;

    if (!isCorrect) {
      _room!.wrongGuesses++;
    }

    final guesserName = _room!.players.firstWhere((p) => p['id'] == playerId, orElse: () => {'name': '?'})['name'];
    final icon = isCorrect ? '✅' : '❌';
    _log(icon, 'TAHMIN: "$letter" by $guesserName ${isCorrect ? "(DOGRU)" : "(YANLIS)"}');
    _log('   ', '  Kelime: ${_room!.getMaskedWord()}');
    _log('   ', '  Yanlis: ${_room!.wrongGuesses}/${_room!.maxWrongGuesses}');

    // Oyun bitti mi?
    if (_room!.isGameOver()) {
      _log('🏁', '═══════════════════════════════════════');
      if (_room!.isWordGuessed()) {
        // Tahmin edenler kazandı
        for (var player in _room!.players) {
          if (player['id'] != _room!.wordChooser) {
            _room!.scores[player['id'] as String] =
                (_room!.scores[player['id'] as String] ?? 0) + 10;
          }
        }
        _log('🏁', 'TUR BITTI - KELIME BULUNDU!');
        _log('🏁', '  Kelime: ${_room!.currentWord}');
      } else {
        // Kelime seçen kazandı
        if (_room!.wordChooser != null) {
          _room!.scores[_room!.wordChooser!] =
              (_room!.scores[_room!.wordChooser!] ?? 0) + 15;
        }
        _log('🏁', 'TUR BITTI - ADAM ASILDI!');
        _log('🏁', '  Kelime: ${_room!.currentWord}');
      }
      _log('🏁', '  SKORLAR:');
      for (var player in _room!.players) {
        final score = _room!.scores[player['id']] ?? 0;
        _log('🏁', '    ${player['name']}: $score puan');
      }
      _log('🏁', '═══════════════════════════════════════');
      _room!.state = 'finished';
    }

    _broadcastRoomUpdate();
  }

  void _handleNewRound(Map<String, dynamic> message) {
    if (_room == null) return;

    final newWordChooserId = message['newWordChooserId'] as String;

    _room!.currentRound++;

    if (_room!.currentRound > _room!.totalRounds) {
      _room!.state = 'gameOver';
      _log('🏆', '═══════════════════════════════════════');
      _log('🏆', 'OYUN BITTI!');
      _log('🏆', '  FINAL SKORLAR:');
      final sortedPlayers = List.from(_room!.players);
      sortedPlayers.sort((a, b) => (_room!.scores[b['id']] ?? 0).compareTo(_room!.scores[a['id']] ?? 0));
      for (var i = 0; i < sortedPlayers.length; i++) {
        final player = sortedPlayers[i];
        final score = _room!.scores[player['id']] ?? 0;
        final medal = i == 0 ? '🥇' : (i == 1 ? '🥈' : '🥉');
        _log('🏆', '    $medal ${player['name']}: $score puan');
      }
      _log('🏆', '═══════════════════════════════════════');
    } else {
      _room!.state = 'choosingWord';
      _room!.wordChooser = newWordChooserId;
      _room!.currentWord = null;
      _room!.guessedLetters = [];
      _room!.wrongGuesses = 0;
      final chooserName = _room!.players.firstWhere((p) => p['id'] == newWordChooserId)['name'];
      _log('🔄', 'YENI TUR: ${_room!.currentRound}/${_room!.totalRounds}');
      _log('🔄', '  Kelime secen: $chooserName');
    }

    // Oyuncuları hazır değil yap (host hariç)
    for (var player in _room!.players) {
      if (player['isHost'] == true) {
        player['isReady'] = true;
      } else {
        player['isReady'] = false;
      }
    }

    _broadcastRoomUpdate();
  }

  void _handleLeave(WebSocket socket, Map<String, dynamic> message) {
    final playerId = message['playerId'] as String;
    _removePlayer(playerId);
  }

  void _handleDisconnect(WebSocket socket) {
    _clients.remove(socket);

    String? disconnectedPlayerId;
    _playerSockets.forEach((id, s) {
      if (s == socket) disconnectedPlayerId = id;
    });

    if (disconnectedPlayerId != null) {
      final playerName = _room?.players.firstWhere((p) => p['id'] == disconnectedPlayerId, orElse: () => {'name': '?'})['name'] ?? '?';
      _log('🔴', 'BAGLANTI KOPTU: $playerName');
      _removePlayer(disconnectedPlayerId!);
    }
  }

  void _removePlayer(String playerId) {
    if (_room == null) return;

    _playerSockets.remove(playerId);
    _room!.players.removeWhere((p) => p['id'] == playerId);

    if (_room!.players.isEmpty) {
      _room = null;
      print('[*] Oda kapatildi');
      return;
    }

    // Host ayrıldıysa yeni host ata
    if (_room!.hostId == playerId) {
      final newHost = _room!.players.first;
      _room!.hostId = newHost['id'] as String;
      _room!.hostName = newHost['name'] as String;
      newHost['isHost'] = true;
      newHost['isReady'] = true;
    }

    _broadcastRoomUpdate();
  }

  void _broadcastRoomUpdate() {
    if (_room == null) return;
    _broadcast({'type': 'room_update', 'room': _room!.toMap()});
  }

  void _broadcast(Map<String, dynamic> message) {
    final data = jsonEncode(message);
    for (var client in _clients) {
      try {
        client.add(data);
      } catch (e) {
        print('[!] Broadcast hatasi: $e');
      }
    }
  }

  void _sendToPlayer(String playerId, Map<String, dynamic> message) {
    final socket = _playerSockets[playerId];
    if (socket != null) _sendToSocket(socket, message);
  }

  void _sendToSocket(WebSocket socket, Map<String, dynamic> message) {
    try {
      socket.add(jsonEncode(message));
    } catch (e) {
      print('[!] Send hatasi: $e');
    }
  }

  String _generateRoomId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(6, (i) => chars[(random + i * 7) % chars.length]).join();
  }
}

void main() async {
  final server = GameServer();
  await server.start(port: 8080);
}
