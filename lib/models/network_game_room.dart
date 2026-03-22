class NetworkGameRoom {
  final String id;
  final String hostId;
  final String hostName;
  final List<NetworkPlayer> players;
  final NetworkGameState state;
  final String? currentWord;
  final String? wordChooser;
  final List<String> guessedLetters;
  final int wrongGuesses;
  final int maxWrongGuesses;
  final DateTime? gameStartTime;
  final int gameDurationSeconds;
  final Map<String, int> scores;
  final int currentRound;
  final int totalRounds;

  NetworkGameRoom({
    required this.id,
    required this.hostId,
    required this.hostName,
    this.players = const [],
    this.state = NetworkGameState.waiting,
    this.currentWord,
    this.wordChooser,
    this.guessedLetters = const [],
    this.wrongGuesses = 0,
    this.maxWrongGuesses = 6,
    this.gameStartTime,
    this.gameDurationSeconds = 120,
    this.scores = const {},
    this.currentRound = 1,
    this.totalRounds = 4,
  });

  factory NetworkGameRoom.fromMap(Map<String, dynamic> map) {
    return NetworkGameRoom(
      id: map['id'] ?? '',
      hostId: map['hostId'] ?? '',
      hostName: map['hostName'] ?? '',
      players: (map['players'] as List<dynamic>?)
              ?.map((p) => NetworkPlayer.fromMap(p))
              .toList() ??
          [],
      state: NetworkGameState.values.firstWhere(
        (e) => e.name == map['state'],
        orElse: () => NetworkGameState.waiting,
      ),
      currentWord: map['currentWord'],
      wordChooser: map['wordChooser'],
      guessedLetters: List<String>.from(map['guessedLetters'] ?? []),
      wrongGuesses: map['wrongGuesses'] ?? 0,
      maxWrongGuesses: map['maxWrongGuesses'] ?? 6,
      gameStartTime: map['gameStartTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['gameStartTime'])
          : null,
      gameDurationSeconds: map['gameDurationSeconds'] ?? 120,
      scores: Map<String, int>.from(map['scores'] ?? {}),
      currentRound: map['currentRound'] ?? 1,
      totalRounds: map['totalRounds'] ?? 4,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
      'currentRound': currentRound,
      'totalRounds': totalRounds,
    };
  }

  NetworkGameRoom copyWith({
    String? id,
    String? hostId,
    String? hostName,
    List<NetworkPlayer>? players,
    NetworkGameState? state,
    String? currentWord,
    String? wordChooser,
    List<String>? guessedLetters,
    int? wrongGuesses,
    int? maxWrongGuesses,
    DateTime? gameStartTime,
    int? gameDurationSeconds,
    Map<String, int>? scores,
    int? currentRound,
    int? totalRounds,
  }) {
    return NetworkGameRoom(
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
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
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

  NetworkPlayer? getWordChooserPlayer() {
    if (wordChooser == null) return null;
    return players.cast<NetworkPlayer?>().firstWhere(
          (p) => p?.id == wordChooser,
          orElse: () => null,
        );
  }

  List<NetworkPlayer> getGuessers() {
    return players.where((p) => p.id != wordChooser).toList();
  }
}

class NetworkPlayer {
  final String id;
  final String name;
  final bool isReady;
  final bool isHost;

  NetworkPlayer({
    required this.id,
    required this.name,
    this.isReady = false,
    this.isHost = false,
  });

  factory NetworkPlayer.fromMap(Map<String, dynamic> map) {
    return NetworkPlayer(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      isReady: map['isReady'] ?? false,
      isHost: map['isHost'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isReady': isReady,
      'isHost': isHost,
    };
  }

  NetworkPlayer copyWith({
    String? id,
    String? name,
    bool? isReady,
    bool? isHost,
  }) {
    return NetworkPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      isReady: isReady ?? this.isReady,
      isHost: isHost ?? this.isHost,
    );
  }
}

enum NetworkGameState {
  waiting,      // Oyuncular bekleniyor
  choosingWord, // Kelime seçiliyor
  playing,      // Oyun devam ediyor
  finished,     // Tur bitti
  gameOver,     // Oyun tamamen bitti
}
