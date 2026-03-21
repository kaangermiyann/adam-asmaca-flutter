class GameRoom {
  final String id;
  final String hostId;
  final String hostName;
  final List<Player> players;
  final GameState state;
  final String? currentWord;
  final String? wordChooser;
  final List<String> guessedLetters;
  final int wrongGuesses;
  final int maxWrongGuesses;
  final DateTime? gameStartTime;
  final int gameDurationSeconds;
  final Map<String, int> scores;

  GameRoom({
    required this.id,
    required this.hostId,
    required this.hostName,
    this.players = const [],
    this.state = GameState.waiting,
    this.currentWord,
    this.wordChooser,
    this.guessedLetters = const [],
    this.wrongGuesses = 0,
    this.maxWrongGuesses = 6,
    this.gameStartTime,
    this.gameDurationSeconds = 600, // 10 dakika
    this.scores = const {},
  });

  factory GameRoom.fromMap(Map<String, dynamic> map, String id) {
    return GameRoom(
      id: id,
      hostId: map['hostId'] ?? '',
      hostName: map['hostName'] ?? '',
      players: (map['players'] as List<dynamic>?)
              ?.map((p) => Player.fromMap(p))
              .toList() ??
          [],
      state: GameState.values.firstWhere(
        (e) => e.name == map['state'],
        orElse: () => GameState.waiting,
      ),
      currentWord: map['currentWord'],
      wordChooser: map['wordChooser'],
      guessedLetters: List<String>.from(map['guessedLetters'] ?? []),
      wrongGuesses: map['wrongGuesses'] ?? 0,
      maxWrongGuesses: map['maxWrongGuesses'] ?? 6,
      gameStartTime: map['gameStartTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['gameStartTime'])
          : null,
      gameDurationSeconds: map['gameDurationSeconds'] ?? 600,
      scores: Map<String, int>.from(map['scores'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'hostName': hostName,
      'players': players.map((p) => p.toMap()).toList(),
      'state': state.name,
      'currentWord': currentWord,
      'wordChooser': wordChooser,
      'guessedLetters': guessedLetters,
      'wrongGuesses': wrongGuesses,
      'maxWrongGuesses': maxWrongGuesses,
      'gameStartTime': gameStartTime?.millisecondsSinceEpoch,
      'gameDurationSeconds': gameDurationSeconds,
      'scores': scores,
    };
  }

  GameRoom copyWith({
    String? id,
    String? hostId,
    String? hostName,
    List<Player>? players,
    GameState? state,
    String? currentWord,
    String? wordChooser,
    List<String>? guessedLetters,
    int? wrongGuesses,
    int? maxWrongGuesses,
    DateTime? gameStartTime,
    int? gameDurationSeconds,
    Map<String, int>? scores,
  }) {
    return GameRoom(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      players: players ?? this.players,
      state: state ?? this.state,
      currentWord: currentWord ?? this.currentWord,
      wordChooser: wordChooser ?? this.wordChooser,
      guessedLetters: guessedLetters ?? this.guessedLetters,
      wrongGuesses: wrongGuesses ?? this.wrongGuesses,
      maxWrongGuesses: maxWrongGuesses ?? this.maxWrongGuesses,
      gameStartTime: gameStartTime ?? this.gameStartTime,
      gameDurationSeconds: gameDurationSeconds ?? this.gameDurationSeconds,
      scores: scores ?? this.scores,
    );
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

  bool isWordGuessed() {
    if (currentWord == null) return false;
    return currentWord!.toUpperCase().split('').every(
          (letter) => guessedLetters.contains(letter.toUpperCase()),
        );
  }

  bool isGameOver() {
    return wrongGuesses >= maxWrongGuesses || isWordGuessed();
  }
}

class Player {
  final String id;
  final String name;
  final bool isReady;

  Player({
    required this.id,
    required this.name,
    this.isReady = false,
  });

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      isReady: map['isReady'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isReady': isReady,
    };
  }

  Player copyWith({String? id, String? name, bool? isReady}) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      isReady: isReady ?? this.isReady,
    );
  }
}

enum GameState {
  waiting,      // Oyuncular bekleniyor
  choosingWord, // Kelime seçiliyor
  playing,      // Oyun devam ediyor
  finished,     // Oyun bitti
}
