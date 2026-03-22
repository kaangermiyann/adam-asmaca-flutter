import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/network_game_room.dart';
import '../services/web_game_client.dart';

class NetworkGameProvider extends ChangeNotifier {
  WebGameClient? _client;

  final String _playerId = const Uuid().v4();
  String _playerName = '';

  NetworkGameRoom? _currentRoom;
  StreamSubscription<NetworkGameRoom>? _roomSubscription;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;

  Timer? _gameTimer;
  int _remainingSeconds = 120;

  bool _isHost = false;
  bool _isConnecting = false;
  String? _errorMessage;
  String? _serverAddress;

  // Getters
  String get playerId => _playerId;
  String get playerName => _playerName;
  NetworkGameRoom? get currentRoom => _currentRoom;
  int get remainingSeconds => _remainingSeconds;
  bool get isHost => _isHost;
  bool get isConnecting => _isConnecting;
  String? get errorMessage => _errorMessage;
  String? get serverAddress => _serverAddress;

  bool get isWordChooser => _currentRoom?.wordChooser == _playerId;
  bool get isConnected => _client?.isConnected ?? false;

  void setPlayerName(String name) {
    _playerName = name;
    notifyListeners();
  }

  // Oda oluştur (sunucuya bağlan ve oda oluştur)
  Future<String?> createRoom(String playerName) async {
    try {
      _isConnecting = true;
      _errorMessage = null;
      notifyListeners();

      _playerName = playerName;
      _isHost = true;

      // Varsayılan olarak localhost'a bağlan
      _serverAddress = 'localhost:8080';

      _client = WebGameClient();

      final connected = await _client!.connect(
        serverAddress: _serverAddress!,
        playerId: _playerId,
        playerName: _playerName,
      );

      if (!connected) {
        _errorMessage = 'Sunucuya baglanilamadi. Sunucu calisıyor mu?';
        _isConnecting = false;
        notifyListeners();
        return null;
      }

      // Room stream'ini dinle
      _roomSubscription = _client!.roomStream.listen((room) {
        _currentRoom = room;

        // Oyun başladığında timer'ı başlat
        if (room.state == NetworkGameState.playing && _gameTimer == null) {
          _startGameTimer();
        }

        // Oyun bittiyse timer'ı durdur
        if (room.state == NetworkGameState.finished || room.state == NetworkGameState.gameOver) {
          _gameTimer?.cancel();
          _gameTimer = null;
        }

        notifyListeners();
      });

      // Mesajları dinle
      _messageSubscription = _client!.messageStream.listen((message) {
        if (message['type'] == 'error') {
          _errorMessage = message['message'];
          notifyListeners();
        } else if (message['type'] == 'disconnected') {
          _errorMessage = 'Baglanti kesildi';
          notifyListeners();
        }
      });

      // Oda oluştur
      _client!.createRoom();

      _isConnecting = false;
      notifyListeners();

      return _serverAddress;
    } catch (e) {
      _errorMessage = 'Oda olusturulamadi: $e';
      _isConnecting = false;
      notifyListeners();
      return null;
    }
  }

  // Odaya katıl
  Future<bool> joinRoom(String serverAddress, String playerName) async {
    try {
      _isConnecting = true;
      _errorMessage = null;
      notifyListeners();

      _playerName = playerName;
      _isHost = false;
      _serverAddress = serverAddress;

      _client = WebGameClient();

      final connected = await _client!.connect(
        serverAddress: serverAddress,
        playerId: _playerId,
        playerName: _playerName,
      );

      if (!connected) {
        _errorMessage = 'Baglanti kurulamadi';
        _isConnecting = false;
        notifyListeners();
        return false;
      }

      // Room stream'ini dinle
      _roomSubscription = _client!.roomStream.listen((room) {
        _currentRoom = room;

        // Oyun başladığında timer'ı başlat
        if (room.state == NetworkGameState.playing && _gameTimer == null) {
          _startGameTimer();
        }

        // Oyun bittiyse timer'ı durdur
        if (room.state == NetworkGameState.finished || room.state == NetworkGameState.gameOver) {
          _gameTimer?.cancel();
          _gameTimer = null;
        }

        notifyListeners();
      });

      // Mesajları dinle
      _messageSubscription = _client!.messageStream.listen((message) {
        if (message['type'] == 'error') {
          _errorMessage = message['message'];
          notifyListeners();
        } else if (message['type'] == 'disconnected') {
          _errorMessage = 'Baglanti kesildi';
          notifyListeners();
        }
      });

      // Odaya katıl
      _client!.joinRoom();

      _isConnecting = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Baglanti hatasi: $e';
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  void _startGameTimer() {
    _remainingSeconds = _currentRoom?.gameDurationSeconds ?? 120;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      }
    });
  }

  // Hazır ol/değil
  void toggleReady() {
    _client?.toggleReady();
  }

  // Oyunu başlat
  void startGame() {
    if (_currentRoom == null) return;
    _client?.startGame(_playerId);
  }

  // Kelime seç
  void setWord(String word) {
    _client?.setWord(word);
  }

  // Harf tahmin et
  void guessLetter(String letter) {
    _client?.guessLetter(letter);
  }

  // Yeni tur
  void newRound() {
    if (_currentRoom == null) return;

    // Sıradaki oyuncuyu kelime seçici yap
    final players = _currentRoom!.players;
    final currentChooserIndex = players.indexWhere(
      (p) => p.id == _currentRoom!.wordChooser,
    );
    final nextChooserIndex = (currentChooserIndex + 1) % players.length;
    final nextChooser = players[nextChooserIndex];

    _remainingSeconds = _currentRoom?.gameDurationSeconds ?? 120;
    _gameTimer?.cancel();
    _gameTimer = null;

    _client?.newRound(nextChooser.id);
  }

  // Odadan ayrıl
  void leaveRoom() {
    _gameTimer?.cancel();
    _gameTimer = null;
    _roomSubscription?.cancel();
    _messageSubscription?.cancel();

    _client?.leave();
    _client = null;

    _currentRoom = null;
    _isHost = false;
    _serverAddress = null;
    notifyListeners();
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _roomSubscription?.cancel();
    _messageSubscription?.cancel();
    _client?.dispose();
    super.dispose();
  }
}
