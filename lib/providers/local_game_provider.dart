import 'dart:async';
import 'package:flutter/foundation.dart';

class LocalGameProvider extends ChangeNotifier {
  // Oyuncular
  String _player1Name = '';
  String _player2Name = '';

  // Puanlar
  int _player1Score = 0;
  int _player2Score = 0;

  // Oyun durumu
  LocalGameState _state = LocalGameState.setup;
  String? _currentWord;
  List<String> _guessedLetters = [];
  int _wrongGuesses = 0;
  final int maxWrongGuesses = 6;

  // Tur bilgisi
  int _currentRound = 1;
  int _totalRounds = 4; // 4 tur (her oyuncu 2 kez kelime seçer)
  bool _isPlayer1Chooser = true; // İlk turda player1 kelime seçer

  // Timer
  Timer? _gameTimer;
  int _remainingSeconds = 120; // 2 dakika per round
  final int roundDuration = 120;

  // Getters
  String get player1Name => _player1Name;
  String get player2Name => _player2Name;
  int get player1Score => _player1Score;
  int get player2Score => _player2Score;
  LocalGameState get state => _state;
  String? get currentWord => _currentWord;
  List<String> get guessedLetters => _guessedLetters;
  int get wrongGuesses => _wrongGuesses;
  int get currentRound => _currentRound;
  int get totalRounds => _totalRounds;
  bool get isPlayer1Chooser => _isPlayer1Chooser;
  int get remainingSeconds => _remainingSeconds;

  String get currentChooserName => _isPlayer1Chooser ? _player1Name : _player2Name;
  String get currentGuesserName => _isPlayer1Chooser ? _player2Name : _player1Name;

  // Oyuncuları ayarla
  void setPlayers(String player1, String player2) {
    _player1Name = player1;
    _player2Name = player2;
    _player1Score = 0;
    _player2Score = 0;
    _currentRound = 1;
    _isPlayer1Chooser = true;
    _state = LocalGameState.choosingWord;
    notifyListeners();
  }

  // Kelime seç
  void setWord(String word) {
    _currentWord = word.toUpperCase();
    _guessedLetters = [];
    _wrongGuesses = 0;
    _remainingSeconds = roundDuration;
    _state = LocalGameState.handover;
    notifyListeners();
  }

  // Telefonu ver ekranından oyuna geç
  void startGuessing() {
    _state = LocalGameState.playing;
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();

        if (_remainingSeconds == 0) {
          _endRound(guesserWon: false, reason: 'Süre doldu!');
        }
      }
    });
  }

  // Harf tahmin et
  Map<String, dynamic> guessLetter(String letter) {
    final upperLetter = letter.toUpperCase();

    if (_guessedLetters.contains(upperLetter)) {
      return {'alreadyGuessed': true};
    }

    _guessedLetters.add(upperLetter);

    final isCorrect = _currentWord?.contains(upperLetter) ?? false;

    if (!isCorrect) {
      _wrongGuesses++;
    }

    notifyListeners();

    // Oyun bitti mi kontrol et
    if (isWordGuessed()) {
      _endRound(guesserWon: true, reason: 'Kelime bulundu!');
      return {'isCorrect': true, 'isGameOver': true, 'guesserWon': true};
    }

    if (_wrongGuesses >= maxWrongGuesses) {
      _endRound(guesserWon: false, reason: 'Adam asıldı!');
      return {'isCorrect': false, 'isGameOver': true, 'guesserWon': false};
    }

    return {'isCorrect': isCorrect, 'alreadyGuessed': false, 'isGameOver': false};
  }

  bool isWordGuessed() {
    if (_currentWord == null) return false;
    return _currentWord!.split('').every(
      (letter) => _guessedLetters.contains(letter),
    );
  }

  String getMaskedWord() {
    if (_currentWord == null) return '';
    return _currentWord!.split('').map((letter) {
      if (_guessedLetters.contains(letter)) {
        return letter;
      }
      return '_';
    }).join(' ');
  }

  void _endRound({required bool guesserWon, required String reason}) {
    _gameTimer?.cancel();
    _gameTimer = null;

    // Puan ver
    if (guesserWon) {
      // Tahmin eden kazandı
      if (_isPlayer1Chooser) {
        _player2Score += 10;
      } else {
        _player1Score += 10;
      }
    } else {
      // Kelime seçen kazandı
      if (_isPlayer1Chooser) {
        _player1Score += 15;
      } else {
        _player2Score += 15;
      }
    }

    _state = LocalGameState.roundEnd;
    notifyListeners();
  }

  // Sonraki tura geç
  void nextRound() {
    if (_currentRound >= _totalRounds) {
      _state = LocalGameState.gameOver;
      notifyListeners();
      return;
    }

    _currentRound++;
    _isPlayer1Chooser = !_isPlayer1Chooser; // Sıra değişir
    _currentWord = null;
    _guessedLetters = [];
    _wrongGuesses = 0;
    _state = LocalGameState.choosingWord;
    notifyListeners();
  }

  // Oyunu sıfırla
  void resetGame() {
    _gameTimer?.cancel();
    _gameTimer = null;
    _player1Name = '';
    _player2Name = '';
    _player1Score = 0;
    _player2Score = 0;
    _state = LocalGameState.setup;
    _currentWord = null;
    _guessedLetters = [];
    _wrongGuesses = 0;
    _currentRound = 1;
    _isPlayer1Chooser = true;
    _remainingSeconds = roundDuration;
    notifyListeners();
  }

  // Yeni oyun (aynı oyuncularla)
  void newGame() {
    _gameTimer?.cancel();
    _gameTimer = null;
    _player1Score = 0;
    _player2Score = 0;
    _currentRound = 1;
    _isPlayer1Chooser = true;
    _currentWord = null;
    _guessedLetters = [];
    _wrongGuesses = 0;
    _state = LocalGameState.choosingWord;
    _remainingSeconds = roundDuration;
    notifyListeners();
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String getWinner() {
    if (_player1Score > _player2Score) {
      return _player1Name;
    } else if (_player2Score > _player1Score) {
      return _player2Name;
    }
    return 'Berabere';
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}

enum LocalGameState {
  setup,        // Oyuncu isimleri giriliyor
  choosingWord, // Kelime seçiliyor
  handover,     // Telefonu ver ekranı
  playing,      // Oyun devam ediyor
  roundEnd,     // Tur bitti
  gameOver,     // Oyun tamamen bitti
}
