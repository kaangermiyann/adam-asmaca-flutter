import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/game_room.dart';
import '../providers/game_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/hangman_figure.dart';
import '../widgets/keyboard_widget.dart';
import '../widgets/player_card.dart';
import 'home_screen.dart';
import 'word_selection_screen.dart';

class GameScreen extends StatefulWidget {
  final String roomId;

  const GameScreen({super.key, required this.roomId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final room = provider.currentRoom;

        if (room == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Kelime seçme aşaması
        if (room.state == GameState.choosingWord) {
          if (provider.isWordChooser) {
            return const WordSelectionScreen();
          } else {
            return _buildWaitingForWordScreen(room, provider);
          }
        }

        // Oyun bitti
        if (room.state == GameState.finished) {
          return _buildGameOverScreen(room, provider);
        }

        // Aktif oyun
        return _buildActiveGame(room, provider);
      },
    );
  }

  Widget _buildWaitingForWordScreen(GameRoom room, GameProvider provider) {
    final wordChooser = room.players.firstWhere(
      (p) => p.id == room.wordChooser,
      orElse: () => Player(id: '', name: 'Bilinmiyor'),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.hourglass_top,
                      size: 60,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(duration: 2.seconds),
                const SizedBox(height: 32),
                Text(
                  '${wordChooser.name}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: 8),
                Text(
                  'kelime seciyor...',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms),
                const SizedBox(height: 48),
                LinearProgressIndicator(
                  backgroundColor: AppTheme.cardColor,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 1.5.seconds),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveGame(GameRoom room, GameProvider provider) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Üst bar - Timer ve bilgiler
            _buildTopBar(room, provider),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Adam asmaca figürü
                    HangmanFigure(
                      wrongGuesses: room.wrongGuesses,
                      maxWrongGuesses: room.maxWrongGuesses,
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(begin: const Offset(0.9, 0.9), duration: 400.ms),
                    const SizedBox(height: 24),
                    // Kelime gösterimi
                    _buildWordDisplay(room, provider),
                    const SizedBox(height: 24),
                    // Yanlış tahminler
                    if (room.wrongGuesses > 0) _buildWrongGuesses(room),
                  ],
                ),
              ),
            ),
            // Klavye
            if (!provider.isWordChooser)
              Padding(
                padding: const EdgeInsets.all(8),
                child: KeyboardWidget(
                  guessedLetters: room.guessedLetters,
                  currentWord: room.currentWord,
                  enabled: room.state == GameState.playing,
                  onLetterPressed: (letter) => _guessLetter(letter, provider),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(GameRoom room, GameProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: provider.remainingSeconds < 60
                  ? AppTheme.errorColor.withValues(alpha: 0.2)
                  : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 20,
                  color: provider.remainingSeconds < 60
                      ? AppTheme.errorColor
                      : AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  provider.formatTime(provider.remainingSeconds),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: provider.remainingSeconds < 60
                        ? AppTheme.errorColor
                        : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Hak göstergesi
          Row(
            children: List.generate(room.maxWrongGuesses, (index) {
              final isLost = index < room.wrongGuesses;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  isLost ? Icons.favorite : Icons.favorite_border,
                  size: 24,
                  color: isLost ? AppTheme.errorColor : AppTheme.textMuted,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWordDisplay(GameRoom room, GameProvider provider) {
    final maskedWord = room.getMaskedWord();

    return Column(
      children: [
        if (provider.isWordChooser) ...[
          Text(
            'Sectigin Kelime',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            room.currentWord ?? '',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_off, size: 16, color: AppTheme.warningColor),
                SizedBox(width: 8),
                Text(
                  'Sadece sen gorebilirsin',
                  style: TextStyle(
                    color: AppTheme.warningColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardColor),
            ),
            child: Text(
              maskedWord,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: 8,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWrongGuesses(GameRoom room) {
    final wrongLetters = room.guessedLetters.where((letter) {
      return !(room.currentWord?.toUpperCase().contains(letter) ?? false);
    }).toList();

    return Column(
      children: [
        Text(
          'Yanlis Tahminler',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: wrongLetters.map((letter) {
            return Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: const TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGameOverScreen(GameRoom room, GameProvider provider) {
    final isWordGuessed = room.isWordGuessed();
    final wordChooser = room.players.firstWhere(
      (p) => p.id == room.wordChooser,
      orElse: () => Player(id: '', name: 'Bilinmiyor'),
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Sonuç ikonu
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: isWordGuessed
                      ? const LinearGradient(
                          colors: [AppTheme.successColor, Color(0xFF059669)],
                        )
                      : const LinearGradient(
                          colors: [AppTheme.errorColor, Color(0xFFDC2626)],
                        ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: (isWordGuessed ? AppTheme.successColor : AppTheme.errorColor)
                          .withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isWordGuessed ? Icons.celebration : Icons.sentiment_dissatisfied,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 32),
              // Sonuç mesajı
              Text(
                isWordGuessed ? 'Tahmin Edenler Kazandi!' : 'Adam Asildi!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: isWordGuessed ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 16),
              // Kelime
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Kelime',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room.currentWord ?? '',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms),
              const SizedBox(height: 8),
              Text(
                'Kelimeyi secen: ${wordChooser.name}',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 32),
              // Skor tablosu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.leaderboard, color: AppTheme.accentColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Skor Tablosu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: room.players.length,
                        itemBuilder: (context, index) {
                          final player = room.players[index];
                          final score = room.scores[player.id] ?? 0;
                          return PlayerCard(
                            player: player,
                            isHost: player.id == room.hostId,
                            isWordChooser: player.id == room.wordChooser,
                            score: score,
                            index: index,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Butonlar
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _leaveRoom(provider),
                      child: const Text('Cikis'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (provider.isHost)
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => provider.newRound(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.replay),
                            SizedBox(width: 8),
                            Text('Yeni Tur'),
                          ],
                        ),
                      ),
                    ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 400.ms)
                  .slideY(begin: 0.2, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guessLetter(String letter, GameProvider provider) async {
    try {
      final result = await provider.guessLetter(letter);

      if (result['alreadyGuessed'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu harf zaten tahmin edildi'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _leaveRoom(GameProvider provider) async {
    await provider.leaveRoom();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }
}
