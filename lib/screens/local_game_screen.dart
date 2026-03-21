import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/local_game_provider.dart';
import '../services/tdk_service.dart';
import '../utils/app_theme.dart';
import '../widgets/hangman_figure.dart';
import '../widgets/keyboard_widget.dart';

class LocalGameScreen extends StatefulWidget {
  const LocalGameScreen({super.key});

  @override
  State<LocalGameScreen> createState() => _LocalGameScreenState();
}

class _LocalGameScreenState extends State<LocalGameScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LocalGameProvider>(
      builder: (context, provider, _) {
        switch (provider.state) {
          case LocalGameState.setup:
            return _SetupScreen(provider: provider);
          case LocalGameState.choosingWord:
            return _WordSelectionScreen(provider: provider);
          case LocalGameState.handover:
            return _HandoverScreen(provider: provider);
          case LocalGameState.playing:
            return _PlayingScreen(provider: provider);
          case LocalGameState.roundEnd:
            return _RoundEndScreen(provider: provider);
          case LocalGameState.gameOver:
            return _GameOverScreen(provider: provider);
        }
      },
    );
  }
}

// ==================== SETUP SCREEN ====================
class _SetupScreen extends StatefulWidget {
  final LocalGameProvider provider;

  const _SetupScreen({required this.provider});

  @override
  State<_SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<_SetupScreen> {
  final _player1Controller = TextEditingController();
  final _player2Controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yerel Oyun'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Başlık
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.people,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.5, 0.5), duration: 400.ms),
                const SizedBox(height: 24),
                Text(
                  '2 Kişilik Oyun',
                  style: Theme.of(context).textTheme.headlineMedium,
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms),
                const SizedBox(height: 8),
                Text(
                  'Aynı cihazda sırayla oynayın',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms),
                const SizedBox(height: 48),
                // Player 1
                TextFormField(
                  controller: _player1Controller,
                  decoration: const InputDecoration(
                    hintText: 'Oyuncu 1 ismi',
                    prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor),
                  ),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'İsim giriniz';
                    }
                    return null;
                  },
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .slideX(begin: -0.2, duration: 400.ms),
                const SizedBox(height: 16),
                // Player 2
                TextFormField(
                  controller: _player2Controller,
                  decoration: const InputDecoration(
                    hintText: 'Oyuncu 2 ismi',
                    prefixIcon: Icon(Icons.person, color: AppTheme.secondaryColor),
                  ),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'İsim giriniz';
                    }
                    return null;
                  },
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms)
                    .slideX(begin: 0.2, duration: 400.ms),
                const SizedBox(height: 48),
                // Başlat butonu
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.provider.setPlayers(
                          _player1Controller.text.trim(),
                          _player2Controller.text.trim(),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow),
                        SizedBox(width: 12),
                        Text('Oyunu Başlat'),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 400.ms)
                    .slideY(begin: 0.2, duration: 400.ms),
                const SizedBox(height: 32),
                // Kurallar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.accentColor, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Nasıl Oynanır?',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildRule('1', 'Sırayla kelime seçin'),
                      _buildRule('2', 'Telefonu diğer oyuncuya verin'),
                      _buildRule('3', 'Harfleri tahmin edin'),
                      _buildRule('4', '4 tur sonunda en yüksek puan kazanır'),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRule(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ==================== WORD SELECTION SCREEN ====================
class _WordSelectionScreen extends StatefulWidget {
  final LocalGameProvider provider;

  const _WordSelectionScreen({required this.provider});

  @override
  State<_WordSelectionScreen> createState() => _WordSelectionScreenState();
}

class _WordSelectionScreenState extends State<_WordSelectionScreen> {
  final _wordController = TextEditingController();
  List<String> _suggestions = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _wordController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);
    _suggestions = await TDKService.getSuggestedWords(count: 8);
    setState(() => _isLoading = false);
  }

  void _submitWord() {
    final word = _wordController.text.trim();
    if (word.length < 3) {
      setState(() {
        _errorMessage = 'Kelime en az 3 harf olmalı';
      });
      return;
    }

    // Sadece harf kontrolü
    if (!RegExp(r'^[a-zA-ZğüşıöçĞÜŞİÖÇ]+$').hasMatch(word)) {
      setState(() {
        _errorMessage = 'Sadece harf kullanın';
      });
      return;
    }

    widget.provider.setWord(word);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Tur bilgisi
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Tur ${widget.provider.currentRound}/${widget.provider.totalRounds}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Sıra kimde
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          widget.provider.currentChooserName.isNotEmpty
                              ? widget.provider.currentChooserName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(begin: const Offset(0.5, 0.5), duration: 400.ms),
                    const SizedBox(height: 16),
                    Text(
                      widget.provider.currentChooserName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms),
                    const SizedBox(height: 4),
                    Text(
                      'Kelime seçme sırası sende!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 400.ms),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Kelime girişi
              TextFormField(
                controller: _wordController,
                decoration: const InputDecoration(
                  hintText: 'Kelimeyi yaz...',
                  prefixIcon: Icon(Icons.edit, color: AppTheme.textMuted),
                ),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              // Onayla butonu
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitWord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check),
                      SizedBox(width: 12),
                      Text('Kelimeyi Onayla'),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 400.ms),
              const SizedBox(height: 32),
              // Öneriler
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppTheme.warningColor, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Önerilen Kelimeler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _loadSuggestions,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Yenile'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _suggestions.map((word) {
                  return InkWell(
                    onTap: () {
                      _wordController.text = word.toUpperCase();
                      setState(() => _errorMessage = null);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        word.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== HANDOVER SCREEN ====================
class _HandoverScreen extends StatelessWidget {
  final LocalGameProvider provider;

  const _HandoverScreen({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Icon(
                    Icons.phone_android,
                    size: 60,
                    color: AppTheme.warningColor,
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 800.ms),
              const SizedBox(height: 32),
              Text(
                'Telefonu Ver!',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.warningColor,
                    ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 16),
              Text(
                '${provider.currentChooserName} kelimeyi seçti.\nŞimdi telefonu ${provider.currentGuesserName} isimli oyuncuya ver.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_off, color: AppTheme.errorColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${provider.currentChooserName}, ekrana bakma!',
                        style: const TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => provider.startGuessing(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                  ),
                  child: Text(
                    '${provider.currentGuesserName} Hazırım!',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 400.ms)
                  .slideY(begin: 0.2, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== PLAYING SCREEN ====================
class _PlayingScreen extends StatelessWidget {
  final LocalGameProvider provider;

  const _PlayingScreen({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Üst bar
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Tahmin eden bilgisi
                    Text(
                      '${provider.currentGuesserName} tahmin ediyor',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Adam asmaca
                    HangmanFigure(
                      wrongGuesses: provider.wrongGuesses,
                      maxWrongGuesses: provider.maxWrongGuesses,
                    ),
                    const SizedBox(height: 24),
                    // Kelime
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        provider.getMaskedWord(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Yanlış harfler
                    if (provider.wrongGuesses > 0) _buildWrongLetters(),
                  ],
                ),
              ),
            ),
            // Klavye
            Padding(
              padding: const EdgeInsets.all(8),
              child: KeyboardWidget(
                guessedLetters: provider.guessedLetters,
                currentWord: provider.currentWord,
                enabled: true,
                onLetterPressed: (letter) => provider.guessLetter(letter),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: provider.remainingSeconds < 30
                  ? AppTheme.errorColor.withValues(alpha: 0.2)
                  : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 20,
                  color: provider.remainingSeconds < 30
                      ? AppTheme.errorColor
                      : AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  provider.formatTime(provider.remainingSeconds),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: provider.remainingSeconds < 30
                        ? AppTheme.errorColor
                        : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Kalpler
          Row(
            children: List.generate(provider.maxWrongGuesses, (index) {
              final isLost = index < provider.wrongGuesses;
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

  Widget _buildWrongLetters() {
    final wrongLetters = provider.guessedLetters.where((letter) {
      return !(provider.currentWord?.contains(letter) ?? false);
    }).toList();

    return Column(
      children: [
        const Text(
          'Yanlış Harfler',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
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
}

// ==================== ROUND END SCREEN ====================
class _RoundEndScreen extends StatelessWidget {
  final LocalGameProvider provider;

  const _RoundEndScreen({required this.provider});

  @override
  Widget build(BuildContext context) {
    final guesserWon = provider.isWordGuessed();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Sonuç ikonu
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: guesserWon
                      ? const LinearGradient(colors: [AppTheme.successColor, Color(0xFF059669)])
                      : const LinearGradient(colors: [AppTheme.errorColor, Color(0xFFDC2626)]),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Icon(
                    guesserWon ? Icons.celebration : Icons.sentiment_dissatisfied,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text(
                guesserWon ? '${provider.currentGuesserName} Bildi!' : 'Adam Asıldı!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: guesserWon ? AppTheme.successColor : AppTheme.errorColor,
                    ),
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
                      provider.currentWord ?? '',
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
              const SizedBox(height: 32),
              // Skor tablosu
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Skor Tablosu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildScoreColumn(
                          provider.player1Name,
                          provider.player1Score,
                          AppTheme.primaryColor,
                        ),
                        Container(
                          width: 2,
                          height: 60,
                          color: AppTheme.cardColor,
                        ),
                        _buildScoreColumn(
                          provider.player2Name,
                          provider.player2Score,
                          AppTheme.secondaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 400.ms),
              const SizedBox(height: 32),
              // Sonraki tur butonu
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => provider.nextRound(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: Text(
                    provider.currentRound < provider.totalRounds
                        ? 'Sonraki Tur'
                        : 'Sonuçları Gör',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreColumn(String name, int score, Color color) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$score',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const Text(
          'puan',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}

// ==================== GAME OVER SCREEN ====================
class _GameOverScreen extends StatelessWidget {
  final LocalGameProvider provider;

  const _GameOverScreen({required this.provider});

  @override
  Widget build(BuildContext context) {
    final winner = provider.getWinner();
    final isDraw = winner == 'Berabere';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Kupa
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.emoji_events,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 32),
              Text(
                'Oyun Bitti!',
                style: Theme.of(context).textTheme.displayMedium,
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 16),
              Text(
                isDraw ? 'Berabere!' : '$winner Kazandı!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.warningColor,
                    ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms),
              const SizedBox(height: 32),
              // Final skorlar
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFinalScore(
                      provider.player1Name,
                      provider.player1Score,
                      provider.player1Score > provider.player2Score,
                    ),
                    const Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    _buildFinalScore(
                      provider.player2Name,
                      provider.player2Score,
                      provider.player2Score > provider.player1Score,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 400.ms),
              const SizedBox(height: 48),
              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        provider.resetGame();
                        Navigator.pop(context);
                      },
                      child: const Text('Ana Menü'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => provider.newGame(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.replay),
                          SizedBox(width: 8),
                          Text('Tekrar Oyna'),
                        ],
                      ),
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinalScore(String name, int score, bool isWinner) {
    return Column(
      children: [
        if (isWinner)
          const Icon(Icons.star, color: AppTheme.warningColor, size: 24)
        else
          const SizedBox(height: 24),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isWinner ? AppTheme.warningColor : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: isWinner ? AppTheme.warningColor : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
