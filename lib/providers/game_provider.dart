import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/game_room.dart';
import '../services/game_service.dart';

class GameProvider extends ChangeNotifier {
  final GameService _gameService = GameService();

  String? _playerId;
  String? _playerName;
  GameRoom? _currentRoom;
  StreamSubscription<GameRoom?>? _roomSubscription;
  Timer? _gameTimer;
  int _remainingSeconds = 600;

  String? get playerId => _playerId;
  String? get playerName => _playerName;
  GameRoom? get currentRoom => _currentRoom;
  int get remainingSeconds => _remainingSeconds;

  bool get isHost => _currentRoom?.hostId == _playerId;
  bool get isWordChooser => _currentRoom?.wordChooser == _playerId;

  void setPlayer(String id, String name) {
    _playerId = id;
    _playerName = name;
    notifyListeners();
  }

  Future<String> createRoom() async {
    if (_playerId == null || _playerName == null) {
      throw Exception('Oyuncu bilgisi eksik');
    }

    final room = await _gameService.createRoom(
      hostId: _playerId!,
      hostName: _playerName!,
    );

    _currentRoom = room;
    _subscribeToRoom(room.id);
    notifyListeners();

    return room.id;
  }

  Future<void> joinRoom(String roomId) async {
    if (_playerId == null || _playerName == null) {
      throw Exception('Oyuncu bilgisi eksik');
    }

    final room = await _gameService.joinRoom(
      roomId: roomId,
      playerId: _playerId!,
      playerName: _playerName!,
    );

    if (room != null) {
      _currentRoom = room;
      _subscribeToRoom(room.id);
      notifyListeners();
    }
  }

  void _subscribeToRoom(String roomId) {
    _roomSubscription?.cancel();
    _roomSubscription = _gameService.roomStream(roomId).listen((room) {
      _currentRoom = room;

      // Oyun başladığında timer'ı başlat
      if (room?.state == GameState.playing && _gameTimer == null) {
        _startGameTimer();
      }

      // Oyun bittiyse timer'ı durdur
      if (room?.state == GameState.finished) {
        _gameTimer?.cancel();
        _gameTimer = null;
      }

      notifyListeners();
    });
  }

  void _startGameTimer() {
    _remainingSeconds = _currentRoom?.gameDurationSeconds ?? 600;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();

        // Süre dolduğunda oyunu bitir
        if (_remainingSeconds == 0 && _currentRoom != null) {
          _endGameDueToTimeout();
        }
      }
    });
  }

  Future<void> _endGameDueToTimeout() async {
    // Süre dolduğunda kelime seçen kazanır
    _gameTimer?.cancel();
    _gameTimer = null;
    notifyListeners();
  }

  Future<void> toggleReady() async {
    if (_currentRoom == null || _playerId == null) return;

    await _gameService.toggleReady(
      roomId: _currentRoom!.id,
      playerId: _playerId!,
    );
  }

  Future<void> startGame() async {
    if (_currentRoom == null) return;

    // Rastgele bir oyuncu kelime seçici olsun
    final players = _currentRoom!.players;
    if (players.length < 2) {
      throw Exception('En az 2 oyuncu gerekli');
    }

    // İlk olarak ev sahibi kelime seçici olsun
    await _gameService.startGame(
      roomId: _currentRoom!.id,
      wordChooserId: _playerId!,
    );
  }

  Future<void> setWord(String word) async {
    if (_currentRoom == null) return;

    await _gameService.setWord(
      roomId: _currentRoom!.id,
      word: word,
    );
  }

  Future<Map<String, dynamic>> guessLetter(String letter) async {
    if (_currentRoom == null || _playerId == null) {
      throw Exception('Oyun bilgisi eksik');
    }

    return await _gameService.guessLetter(
      roomId: _currentRoom!.id,
      letter: letter,
      playerId: _playerId!,
    );
  }

  Future<void> newRound() async {
    if (_currentRoom == null) return;

    // Sıradaki oyuncuyu kelime seçici yap
    final players = _currentRoom!.players;
    final currentChooserIndex = players.indexWhere(
      (p) => p.id == _currentRoom!.wordChooser,
    );
    final nextChooserIndex = (currentChooserIndex + 1) % players.length;
    final nextChooser = players[nextChooserIndex];

    await _gameService.newRound(
      roomId: _currentRoom!.id,
      newWordChooserId: nextChooser.id,
    );

    _remainingSeconds = _currentRoom?.gameDurationSeconds ?? 600;
    _gameTimer?.cancel();
    _gameTimer = null;
    notifyListeners();
  }

  Future<void> leaveRoom() async {
    if (_currentRoom == null || _playerId == null) return;

    _gameTimer?.cancel();
    _gameTimer = null;

    await _gameService.leaveRoom(
      roomId: _currentRoom!.id,
      playerId: _playerId!,
    );

    _roomSubscription?.cancel();
    _roomSubscription = null;
    _currentRoom = null;
    notifyListeners();
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _gameTimer?.cancel();
    super.dispose();
  }
}
