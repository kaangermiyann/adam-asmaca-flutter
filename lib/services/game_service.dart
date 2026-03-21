import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/game_room.dart';

class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _roomsCollection =>
      _firestore.collection('game_rooms');

  /// Yeni oda oluştur
  Future<GameRoom> createRoom({
    required String hostId,
    required String hostName,
  }) async {
    final roomId = _uuid.v4().substring(0, 6).toUpperCase();

    final room = GameRoom(
      id: roomId,
      hostId: hostId,
      hostName: hostName,
      players: [
        Player(id: hostId, name: hostName, isReady: false),
      ],
      state: GameState.waiting,
      scores: {hostId: 0},
    );

    await _roomsCollection.doc(roomId).set(room.toMap());

    return room;
  }

  /// Odaya katıl
  Future<GameRoom?> joinRoom({
    required String roomId,
    required String playerId,
    required String playerName,
  }) async {
    final docRef = _roomsCollection.doc(roomId.toUpperCase());
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception('Oda bulunamadı');
    }

    final room = GameRoom.fromMap(doc.data()!, doc.id);

    if (room.state != GameState.waiting) {
      throw Exception('Oyun zaten başlamış');
    }

    if (room.players.any((p) => p.id == playerId)) {
      return room; // Zaten odada
    }

    final updatedPlayers = [
      ...room.players,
      Player(id: playerId, name: playerName, isReady: false),
    ];

    final updatedScores = Map<String, int>.from(room.scores);
    updatedScores[playerId] = 0;

    await docRef.update({
      'players': updatedPlayers.map((p) => p.toMap()).toList(),
      'scores': updatedScores,
    });

    return room.copyWith(players: updatedPlayers, scores: updatedScores);
  }

  /// Hazır ol/değil
  Future<void> toggleReady({
    required String roomId,
    required String playerId,
  }) async {
    final docRef = _roomsCollection.doc(roomId);
    final doc = await docRef.get();

    if (!doc.exists) return;

    final room = GameRoom.fromMap(doc.data()!, doc.id);
    final updatedPlayers = room.players.map((p) {
      if (p.id == playerId) {
        return p.copyWith(isReady: !p.isReady);
      }
      return p;
    }).toList();

    await docRef.update({
      'players': updatedPlayers.map((p) => p.toMap()).toList(),
    });
  }

  /// Oyunu başlat (kelime seçici belirle)
  Future<void> startGame({
    required String roomId,
    required String wordChooserId,
  }) async {
    final docRef = _roomsCollection.doc(roomId);

    await docRef.update({
      'state': GameState.choosingWord.name,
      'wordChooser': wordChooserId,
      'guessedLetters': [],
      'wrongGuesses': 0,
      'currentWord': null,
    });
  }

  /// Kelime seç
  Future<void> setWord({
    required String roomId,
    required String word,
  }) async {
    final docRef = _roomsCollection.doc(roomId);

    await docRef.update({
      'state': GameState.playing.name,
      'currentWord': word.toUpperCase(),
      'gameStartTime': DateTime.now().millisecondsSinceEpoch,
      'guessedLetters': [],
      'wrongGuesses': 0,
    });
  }

  /// Harf tahmin et
  Future<Map<String, dynamic>> guessLetter({
    required String roomId,
    required String letter,
    required String playerId,
  }) async {
    final docRef = _roomsCollection.doc(roomId);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception('Oda bulunamadı');
    }

    final room = GameRoom.fromMap(doc.data()!, doc.id);

    if (room.guessedLetters.contains(letter.toUpperCase())) {
      return {'alreadyGuessed': true};
    }

    final updatedGuessedLetters = [
      ...room.guessedLetters,
      letter.toUpperCase(),
    ];

    final isCorrect =
        room.currentWord?.toUpperCase().contains(letter.toUpperCase()) ?? false;

    int updatedWrongGuesses = room.wrongGuesses;
    if (!isCorrect) {
      updatedWrongGuesses++;
    }

    final updateData = {
      'guessedLetters': updatedGuessedLetters,
      'wrongGuesses': updatedWrongGuesses,
    };

    // Oyun bitti mi kontrol et
    final tempRoom = room.copyWith(
      guessedLetters: updatedGuessedLetters,
      wrongGuesses: updatedWrongGuesses,
    );

    if (tempRoom.isGameOver()) {
      updateData['state'] = GameState.finished.name;

      // Puan güncelle
      final updatedScores = Map<String, int>.from(room.scores);
      if (tempRoom.isWordGuessed()) {
        // Tahmin edenler kazandı - her tahmin edene puan
        for (final player in room.players) {
          if (player.id != room.wordChooser) {
            updatedScores[player.id] = (updatedScores[player.id] ?? 0) + 10;
          }
        }
      } else {
        // Kelime seçen kazandı
        if (room.wordChooser != null) {
          updatedScores[room.wordChooser!] =
              (updatedScores[room.wordChooser!] ?? 0) + 15;
        }
      }
      updateData['scores'] = updatedScores;
    }

    await docRef.update(updateData);

    return {
      'isCorrect': isCorrect,
      'alreadyGuessed': false,
      'isGameOver': tempRoom.isGameOver(),
      'isWordGuessed': tempRoom.isWordGuessed(),
    };
  }

  /// Odadan ayrıl
  Future<void> leaveRoom({
    required String roomId,
    required String playerId,
  }) async {
    final docRef = _roomsCollection.doc(roomId);
    final doc = await docRef.get();

    if (!doc.exists) return;

    final room = GameRoom.fromMap(doc.data()!, doc.id);
    final updatedPlayers =
        room.players.where((p) => p.id != playerId).toList();

    if (updatedPlayers.isEmpty) {
      // Odada kimse kalmadı, odayı sil
      await docRef.delete();
      return;
    }

    final updateData = <String, dynamic>{
      'players': updatedPlayers.map((p) => p.toMap()).toList(),
    };

    // Ev sahibi ayrılırsa yeni ev sahibi ata
    if (room.hostId == playerId) {
      updateData['hostId'] = updatedPlayers.first.id;
      updateData['hostName'] = updatedPlayers.first.name;
    }

    await docRef.update(updateData);
  }

  /// Yeni tur başlat
  Future<void> newRound({
    required String roomId,
    required String newWordChooserId,
  }) async {
    final docRef = _roomsCollection.doc(roomId);
    final doc = await docRef.get();

    if (!doc.exists) return;

    final room = GameRoom.fromMap(doc.data()!, doc.id);

    // Tüm oyuncuları hazır değil yap
    final updatedPlayers =
        room.players.map((p) => p.copyWith(isReady: false)).toList();

    await docRef.update({
      'state': GameState.choosingWord.name,
      'wordChooser': newWordChooserId,
      'currentWord': null,
      'guessedLetters': [],
      'wrongGuesses': 0,
      'gameStartTime': null,
      'players': updatedPlayers.map((p) => p.toMap()).toList(),
    });
  }

  /// Oda stream'i
  Stream<GameRoom?> roomStream(String roomId) {
    return _roomsCollection.doc(roomId.toUpperCase()).snapshots().map((doc) {
      if (!doc.exists) return null;
      return GameRoom.fromMap(doc.data()!, doc.id);
    });
  }

  /// Oda var mı kontrol et
  Future<bool> roomExists(String roomId) async {
    final doc = await _roomsCollection.doc(roomId.toUpperCase()).get();
    return doc.exists;
  }
}
